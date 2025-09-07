#!/bin/bash
set -e

# WhatsApp Clone - Production Monitoring Setup Script
# Sets up comprehensive monitoring and alerting for production infrastructure

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="${PROJECT_NAME:-whatsapp-clone}"
ENVIRONMENT="${ENVIRONMENT:-production}"
AWS_REGION="${AWS_REGION:-ap-southeast-1}"
ALERT_EMAIL="${ALERT_EMAIL:-}"
CLOUDFRONT_DISTRIBUTION_ID="${CLOUDFRONT_DISTRIBUTION_ID:-}"
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

check_requirements() {
    log "Checking requirements..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed"
    fi
    
    # Check if user is authenticated
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS CLI is not configured or user not authenticated"
    fi
    
    # Check required parameters
    if [[ -z "$ALERT_EMAIL" ]]; then
        error "ALERT_EMAIL environment variable is required"
    fi
    
    success "Requirements check passed"
}

create_sns_topic() {
    log "Creating SNS topic for alerts..."
    
    # Create SNS topic
    SNS_TOPIC_ARN=$(aws sns create-topic \
        --name "${PROJECT_NAME}-${ENVIRONMENT}-alerts" \
        --region "$AWS_REGION" \
        --query 'TopicArn' --output text)
    
    # Subscribe email to the topic
    aws sns subscribe \
        --topic-arn "$SNS_TOPIC_ARN" \
        --protocol email \
        --notification-endpoint "$ALERT_EMAIL" \
        --region "$AWS_REGION"
    
    # Add Slack webhook if provided
    if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
        log "Setting up Slack notifications..."
        
        # Create Lambda function for Slack notifications
        cat > /tmp/slack-notifier.js << 'EOF'
const https = require('https');
const url = require('url');

exports.handler = async (event) => {
    const message = JSON.parse(event.Records[0].Sns.Message);
    const slackUrl = process.env.SLACK_WEBHOOK_URL;
    
    const slackMessage = {
        text: `🚨 *${message.AlarmName}*`,
        attachments: [{
            color: message.NewStateValue === 'ALARM' ? 'danger' : 'good',
            fields: [{
                title: 'Description',
                value: message.AlarmDescription,
                short: false
            }, {
                title: 'Region',
                value: message.Region,
                short: true
            }, {
                title: 'State',
                value: message.NewStateValue,
                short: true
            }, {
                title: 'Reason',
                value: message.NewStateReason,
                short: false
            }]
        }]
    };
    
    const payload = JSON.stringify(slackMessage);
    const options = url.parse(slackUrl);
    options.method = 'POST';
    options.headers = {
        'Content-Type': 'application/json',
        'Content-Length': payload.length
    };
    
    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            resolve({ statusCode: res.statusCode });
        });
        req.on('error', reject);
        req.write(payload);
        req.end();
    });
};
EOF
        
        # Create IAM role for Slack Lambda function
        cat > /tmp/lambda-trust-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
        
        if ! aws iam get-role --role-name slack-notifier-role &>/dev/null; then
            aws iam create-role --role-name slack-notifier-role \
                --assume-role-policy-document file:///tmp/lambda-trust-policy.json
            
            aws iam attach-role-policy --role-name slack-notifier-role \
                --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
            
            # Wait for role to propagate
            sleep 10
        fi
        
        # Get account ID and create Lambda function
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        LAMBDA_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/slack-notifier-role"
        
        # Create zip file for Lambda
        cd /tmp
        zip -q slack-notifier.zip slack-notifier.js
        
        # Create or update Lambda function
        if aws lambda get-function --function-name slack-notifier &>/dev/null; then
            aws lambda update-function-code --function-name slack-notifier \
                --zip-file fileb://slack-notifier.zip
        else
            aws lambda create-function --function-name slack-notifier \
                --runtime nodejs18.x --role "$LAMBDA_ROLE_ARN" \
                --handler slack-notifier.handler \
                --zip-file fileb://slack-notifier.zip \
                --environment Variables="{SLACK_WEBHOOK_URL=$SLACK_WEBHOOK_URL}" \
                --timeout 30 --memory-size 128
        fi
        
        # Subscribe Lambda to SNS topic
        LAMBDA_ARN="arn:aws:lambda:${AWS_REGION}:${ACCOUNT_ID}:function:slack-notifier"
        
        aws sns subscribe \
            --topic-arn "$SNS_TOPIC_ARN" \
            --protocol lambda \
            --notification-endpoint "$LAMBDA_ARN"
        
        # Add permission for SNS to invoke Lambda
        aws lambda add-permission \
            --function-name slack-notifier \
            --statement-id sns-invoke \
            --action lambda:InvokeFunction \
            --principal sns.amazonaws.com \
            --source-arn "$SNS_TOPIC_ARN" || true
        
        # Clean up
        rm -f /tmp/slack-notifier.js /tmp/slack-notifier.zip /tmp/lambda-trust-policy.json
        cd - > /dev/null
    fi
    
    export SNS_TOPIC_ARN
    success "SNS topic created: $SNS_TOPIC_ARN"
}

deploy_cloudwatch_alarms() {
    log "Deploying CloudWatch alarms..."
    
    # Deploy CloudWatch alarms using CloudFormation
    aws cloudformation deploy \
        --template-file infrastructure/monitoring/cloudwatch-alarms.yaml \
        --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-monitoring" \
        --parameter-overrides \
            ProjectName="$PROJECT_NAME" \
            Environment="$ENVIRONMENT" \
            SNSTopicArn="$SNS_TOPIC_ARN" \
            CloudFrontDistributionId="${CLOUDFRONT_DISTRIBUTION_ID:-dummy}" \
            SupabaseProjectRef="${SUPABASE_PROJECT_REF:-dummy}" \
        --capabilities CAPABILITY_IAM \
        --region "$AWS_REGION"
    
    success "CloudWatch alarms deployed successfully"
}

create_custom_metrics_namespace() {
    log "Creating custom metrics namespace..."
    
    # Create CloudWatch custom metrics for application-specific monitoring
    cat > /tmp/custom-metrics-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "cloudwatch:namespace": "${PROJECT_NAME}/Application"
                }
            }
        }
    ]
}
EOF
    
    # Create IAM policy for custom metrics
    aws iam create-policy \
        --policy-name "${PROJECT_NAME}-custom-metrics-policy" \
        --policy-document file:///tmp/custom-metrics-policy.json || true
    
    rm /tmp/custom-metrics-policy.json
    
    success "Custom metrics namespace configured"
}

setup_log_groups() {
    log "Setting up CloudWatch log groups..."
    
    # Create log groups for different components
    LOG_GROUPS=(
        "/aws/lambda/${PROJECT_NAME}-${ENVIRONMENT}"
        "/aws/cloudfront/${PROJECT_NAME}-${ENVIRONMENT}"
        "/application/${PROJECT_NAME}/${ENVIRONMENT}/app"
        "/application/${PROJECT_NAME}/${ENVIRONMENT}/supabase"
        "/application/${PROJECT_NAME}/${ENVIRONMENT}/livekit"
    )
    
    for log_group in "${LOG_GROUPS[@]}"; do
        log "Creating log group: $log_group"
        aws logs create-log-group --log-group-name "$log_group" --region "$AWS_REGION" || true
        
        # Set retention policy (30 days for production)
        aws logs put-retention-policy \
            --log-group-name "$log_group" \
            --retention-in-days 30 \
            --region "$AWS_REGION" || true
    done
    
    success "CloudWatch log groups configured"
}

create_dashboards() {
    log "Creating CloudWatch dashboards..."
    
    # Create main dashboard
    cat > /tmp/dashboard.json << EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/CloudFront", "Requests", "DistributionId", "${CLOUDFRONT_DISTRIBUTION_ID:-dummy}" ]
                ],
                "period": 300,
                "stat": "Sum",
                "region": "us-east-1",
                "title": "CloudFront Requests"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/CloudFront", "4xxErrorRate", "DistributionId", "${CLOUDFRONT_DISTRIBUTION_ID:-dummy}" ],
                    [ ".", "5xxErrorRate", ".", "." ]
                ],
                "period": 300,
                "stat": "Average",
                "region": "us-east-1",
                "title": "Error Rates"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "${PROJECT_NAME}/Application", "DatabaseConnectionFailures" ],
                    [ ".", "MessageDeliveryFailures" ],
                    [ ".", "FileUploadFailures" ]
                ],
                "period": 300,
                "stat": "Sum",
                "region": "${AWS_REGION}",
                "title": "Application Errors"
            }
        },
        {
            "type": "log",
            "x": 12,
            "y": 6,
            "width": 12,
            "height": 6,
            "properties": {
                "query": "SOURCE '/application/${PROJECT_NAME}/${ENVIRONMENT}/app'\n| fields @timestamp, @message\n| filter @message like /ERROR/\n| sort @timestamp desc\n| limit 20",
                "region": "${AWS_REGION}",
                "title": "Recent Errors"
            }
        }
    ]
}
EOF
    
    # Create the dashboard
    aws cloudwatch put-dashboard \
        --dashboard-name "${PROJECT_NAME}-${ENVIRONMENT}-overview" \
        --dashboard-body file:///tmp/dashboard.json \
        --region "$AWS_REGION"
    
    rm /tmp/dashboard.json
    
    success "CloudWatch dashboard created"
}

setup_synthetic_monitoring() {
    log "Setting up synthetic monitoring (health checks)..."
    
    # Create Route53 health checks for synthetic monitoring
    HEALTH_CHECK_URLS=(
        "https://cdn.${DOMAIN_NAME:-example.com}/health"
        "https://api.${DOMAIN_NAME:-example.com}/health"
    )
    
    for url in "${HEALTH_CHECK_URLS[@]}"; do
        if [[ "$url" != *"example.com"* ]]; then
            log "Creating health check for: $url"
            
            HEALTH_CHECK_OUTPUT=$(aws route53 create-health-check \
                --caller-reference "$(date +%s)-${url##*/}" \
                --health-check-config '{
                    "Type": "HTTPS",
                    "ResourcePath": "/health",
                    "FullyQualifiedDomainName": "'${url#https://}'",
                    "Port": 443,
                    "RequestInterval": 30,
                    "FailureThreshold": 3
                }' --region "$AWS_REGION" 2>/dev/null || true)
            
            if [[ -n "$HEALTH_CHECK_OUTPUT" ]]; then
                HEALTH_CHECK_ID=$(echo "$HEALTH_CHECK_OUTPUT" | jq -r '.HealthCheck.Id')
                
                # Create CloudWatch alarm for health check
                aws cloudwatch put-metric-alarm \
                    --alarm-name "${PROJECT_NAME}-${ENVIRONMENT}-health-check-${url##*/}" \
                    --alarm-description "Health check alarm for ${url}" \
                    --metric-name HealthCheckStatus \
                    --namespace AWS/Route53 \
                    --statistic Minimum \
                    --period 60 \
                    --evaluation-periods 2 \
                    --threshold 1 \
                    --comparison-operator LessThanThreshold \
                    --dimensions Name=HealthCheckId,Value="$HEALTH_CHECK_ID" \
                    --alarm-actions "$SNS_TOPIC_ARN" \
                    --region "$AWS_REGION"
            fi
        fi
    done
    
    success "Synthetic monitoring configured"
}

output_monitoring_info() {
    log "Monitoring setup completed successfully!"
    
    echo ""
    echo "=== MONITORING CONFIGURATION SUMMARY ==="
    echo "Project: $PROJECT_NAME"
    echo "Environment: $ENVIRONMENT"
    echo "Region: $AWS_REGION"
    echo "SNS Topic: $SNS_TOPIC_ARN"
    echo "Alert Email: $ALERT_EMAIL"
    if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
        echo "Slack Integration: Enabled"
    fi
    echo ""
    echo "=== NEXT STEPS ==="
    echo "1. Check your email and confirm the SNS subscription"
    echo "2. Visit CloudWatch Console to view dashboards and alarms"
    echo "3. Configure application code to send custom metrics"
    echo "4. Test alerting by triggering a test alarm"
    echo ""
    echo "=== USEFUL LINKS ==="
    echo "CloudWatch Console: https://console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}"
    echo "SNS Console: https://console.aws.amazon.com/sns/v3/home?region=${AWS_REGION}"
    echo "Dashboard: https://console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#dashboards:name=${PROJECT_NAME}-${ENVIRONMENT}-overview"
    echo ""
}

main() {
    log "Starting WhatsApp Clone production monitoring setup..."
    
    check_requirements
    create_sns_topic
    deploy_cloudwatch_alarms
    create_custom_metrics_namespace
    setup_log_groups
    create_dashboards
    setup_synthetic_monitoring
    output_monitoring_info
    
    success "Monitoring setup completed successfully!"
}

# Run the main function
main "$@"