#!/bin/bash
set -e

# WhatsApp Clone - CDN Deployment Script
# Deploys CloudFront distribution with Lambda@Edge functions for production

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}" # Lambda@Edge must be in us-east-1
CERTIFICATE_ARN="${SSL_CERTIFICATE_ARN:-}"
DOMAIN_NAME="${DOMAIN_NAME:-}"
S3_BUCKET="${CDN_LOGS_BUCKET:-whatsapp-clone-cdn-logs}"
WAF_WEB_ACL_ID="${WAF_WEB_ACL_ID:-}"

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
    
    # Check required environment variables
    if [[ -z "$CERTIFICATE_ARN" ]]; then
        error "SSL_CERTIFICATE_ARN environment variable is required"
    fi
    
    if [[ -z "$DOMAIN_NAME" ]]; then
        error "DOMAIN_NAME environment variable is required"
    fi
    
    success "Requirements check passed"
}

create_s3_bucket_for_logs() {
    log "Creating S3 bucket for CDN logs..."
    
    if aws s3api head-bucket --bucket "$S3_BUCKET" 2>/dev/null; then
        log "S3 bucket $S3_BUCKET already exists"
    else
        log "Creating S3 bucket: $S3_BUCKET"
        
        if [[ "$AWS_REGION" == "us-east-1" ]]; then
            aws s3api create-bucket --bucket "$S3_BUCKET" --region "$AWS_REGION"
        else
            aws s3api create-bucket --bucket "$S3_BUCKET" --region "$AWS_REGION" \
                --create-bucket-configuration LocationConstraint="$AWS_REGION"
        fi
        
        # Configure bucket for logging
        aws s3api put-bucket-versioning --bucket "$S3_BUCKET" \
            --versioning-configuration Status=Enabled
        
        # Set lifecycle policy for log retention
        cat > /tmp/lifecycle-policy.json << EOF
{
    "Rules": [
        {
            "ID": "CDNLogRetention",
            "Status": "Enabled",
            "Filter": {"Prefix": "cloudfront-logs/"},
            "Expiration": {"Days": 90},
            "NoncurrentVersionExpiration": {"NoncurrentDays": 30}
        }
    ]
}
EOF
        
        aws s3api put-bucket-lifecycle-configuration --bucket "$S3_BUCKET" \
            --lifecycle-configuration file:///tmp/lifecycle-policy.json
        
        rm /tmp/lifecycle-policy.json
    fi
    
    success "S3 bucket for logs ready"
}

create_lambda_functions() {
    log "Creating Lambda@Edge functions..."
    
    # Create IAM role for Lambda@Edge
    if ! aws iam get-role --role-name lambda-edge-role &>/dev/null; then
        log "Creating IAM role for Lambda@Edge..."
        
        cat > /tmp/lambda-edge-trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "lambda.amazonaws.com",
                    "edgelambda.amazonaws.com"
                ]
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
        
        aws iam create-role --role-name lambda-edge-role \
            --assume-role-policy-document file:///tmp/lambda-edge-trust-policy.json
        
        aws iam attach-role-policy --role-name lambda-edge-role \
            --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
        
        rm /tmp/lambda-edge-trust-policy.json
        
        # Wait for role to propagate
        sleep 10
    fi
    
    # Get account ID for ARN construction
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    LAMBDA_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/lambda-edge-role"
    
    # Create intelligent routing function
    log "Creating intelligent routing Lambda function..."
    
    # Zip the function
    cd infrastructure/cdn
    zip -q intelligent-routing.zip lambda-edge-intelligent-routing.js
    
    if aws lambda get-function --function-name intelligent-routing &>/dev/null; then
        log "Updating existing intelligent-routing function..."
        aws lambda update-function-code --function-name intelligent-routing \
            --zip-file fileb://intelligent-routing.zip
    else
        log "Creating new intelligent-routing function..."
        aws lambda create-function --function-name intelligent-routing \
            --runtime nodejs18.x --role "$LAMBDA_ROLE_ARN" \
            --handler lambda-edge-intelligent-routing.handler \
            --zip-file fileb://intelligent-routing.zip \
            --timeout 5 --memory-size 128 \
            --region us-east-1
    fi
    
    # Publish version for Lambda@Edge
    ROUTING_VERSION=$(aws lambda publish-version --function-name intelligent-routing \
        --query Version --output text)
    ROUTING_ARN="arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:intelligent-routing:${ROUTING_VERSION}"
    
    # Create security headers function
    log "Creating security headers Lambda function..."
    
    zip -q security-headers.zip lambda-edge-security-headers.js
    
    if aws lambda get-function --function-name security-headers &>/dev/null; then
        log "Updating existing security-headers function..."
        aws lambda update-function-code --function-name security-headers \
            --zip-file fileb://security-headers.zip
    else
        log "Creating new security-headers function..."
        aws lambda create-function --function-name security-headers \
            --runtime nodejs18.x --role "$LAMBDA_ROLE_ARN" \
            --handler lambda-edge-security-headers.handler \
            --zip-file fileb://security-headers.zip \
            --timeout 5 --memory-size 128 \
            --region us-east-1
    fi
    
    # Publish version for Lambda@Edge
    HEADERS_VERSION=$(aws lambda publish-version --function-name security-headers \
        --query Version --output text)
    HEADERS_ARN="arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:security-headers:${HEADERS_VERSION}"
    
    # Clean up zip files
    rm -f intelligent-routing.zip security-headers.zip
    cd - > /dev/null
    
    # Export ARNs for CloudFront distribution
    export ROUTING_LAMBDA_ARN="$ROUTING_ARN"
    export HEADERS_LAMBDA_ARN="$HEADERS_ARN"
    
    success "Lambda@Edge functions created successfully"
    success "Routing function ARN: $ROUTING_ARN"
    success "Headers function ARN: $HEADERS_ARN"
}

create_waf_web_acl() {
    if [[ -z "$WAF_WEB_ACL_ID" ]]; then
        log "Creating WAF Web ACL for security..."
        
        cat > /tmp/waf-rules.json << EOF
{
    "Name": "whatsapp-clone-waf",
    "Scope": "CLOUDFRONT",
    "DefaultAction": {"Allow": {}},
    "Description": "WAF rules for WhatsApp Clone CDN",
    "Rules": [
        {
            "Name": "AWSManagedRulesCommonRuleSet",
            "Priority": 1,
            "OverrideAction": {"None": {}},
            "Statement": {
                "ManagedRuleGroupStatement": {
                    "VendorName": "AWS",
                    "Name": "AWSManagedRulesCommonRuleSet"
                }
            },
            "VisibilityConfig": {
                "SampledRequestsEnabled": true,
                "CloudWatchMetricsEnabled": true,
                "MetricName": "CommonRuleSetMetric"
            }
        },
        {
            "Name": "AWSManagedRulesKnownBadInputsRuleSet",
            "Priority": 2,
            "OverrideAction": {"None": {}},
            "Statement": {
                "ManagedRuleGroupStatement": {
                    "VendorName": "AWS",
                    "Name": "AWSManagedRulesKnownBadInputsRuleSet"
                }
            },
            "VisibilityConfig": {
                "SampledRequestsEnabled": true,
                "CloudWatchMetricsEnabled": true,
                "MetricName": "KnownBadInputsMetric"
            }
        },
        {
            "Name": "RateLimitRule",
            "Priority": 3,
            "Action": {"Block": {}},
            "Statement": {
                "RateBasedStatement": {
                    "Limit": 2000,
                    "AggregateKeyType": "IP"
                }
            },
            "VisibilityConfig": {
                "SampledRequestsEnabled": true,
                "CloudWatchMetricsEnabled": true,
                "MetricName": "RateLimitMetric"
            }
        }
    ],
    "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "WhatsAppCloneWAF"
    }
}
EOF
        
        WAF_OUTPUT=$(aws wafv2 create-web-acl --cli-input-json file:///tmp/waf-rules.json --region us-east-1)
        WAF_WEB_ACL_ID=$(echo "$WAF_OUTPUT" | grep -o '"Id":"[^"]*' | cut -d'"' -f4)
        
        rm /tmp/waf-rules.json
        
        export WAF_WEB_ACL_ID
        success "WAF Web ACL created: $WAF_WEB_ACL_ID"
    else
        log "Using existing WAF Web ACL: $WAF_WEB_ACL_ID"
    fi
}

create_cloudfront_distribution() {
    log "Creating CloudFront distribution..."
    
    # Update CloudFront configuration with actual values
    sed -e "s/your-production-project-sg\.supabase\.co/${SUPABASE_PRIMARY_DOMAIN:-your-production-project-sg.supabase.co}/g" \
        -e "s/your-production-project-jp\.supabase\.co/${SUPABASE_SECONDARY_DOMAIN:-your-production-project-jp.supabase.co}/g" \
        -e "s/your-certificate-id/${CERTIFICATE_ARN##*/}/g" \
        -e "s/arn:aws:acm:us-east-1:123456789012:certificate\/your-certificate-id/${CERTIFICATE_ARN}/g" \
        -e "s/cdn\.your-production-domain\.com/cdn.${DOMAIN_NAME}/g" \
        -e "s/assets\.your-production-domain\.com/assets.${DOMAIN_NAME}/g" \
        -e "s/whatsapp-clone-cdn-logs\.s3\.amazonaws\.com/${S3_BUCKET}.s3.amazonaws.com/g" \
        -e "s/arn:aws:lambda:us-east-1:123456789012:function:intelligent-routing:1/${ROUTING_LAMBDA_ARN}/g" \
        -e "s/arn:aws:lambda:us-east-1:123456789012:function:security-headers:1/${HEADERS_LAMBDA_ARN}/g" \
        infrastructure/cdn/cloudfront-config.json > /tmp/cloudfront-config.json
    
    # Add WAF Web ACL ID if available
    if [[ -n "$WAF_WEB_ACL_ID" ]]; then
        # Get account ID and region for WAF ARN
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        WAF_ARN="arn:aws:wafv2:us-east-1:${ACCOUNT_ID}:global/webacl/whatsapp-clone-waf/${WAF_WEB_ACL_ID}"
        sed -i "s|arn:aws:wafv2:us-east-1:123456789012:global/webacl/whatsapp-clone-waf/your-waf-id|${WAF_ARN}|g" /tmp/cloudfront-config.json
    fi
    
    # Create CloudFront distribution
    DISTRIBUTION_OUTPUT=$(aws cloudfront create-distribution --distribution-config file:///tmp/cloudfront-config.json)
    DISTRIBUTION_ID=$(echo "$DISTRIBUTION_OUTPUT" | jq -r '.Distribution.Id')
    DISTRIBUTION_DOMAIN=$(echo "$DISTRIBUTION_OUTPUT" | jq -r '.Distribution.DomainName')
    
    rm /tmp/cloudfront-config.json
    
    success "CloudFront distribution created successfully"
    success "Distribution ID: $DISTRIBUTION_ID"
    success "Distribution Domain: $DISTRIBUTION_DOMAIN"
    
    # Wait for distribution to be deployed
    log "Waiting for distribution to be deployed (this may take 15-20 minutes)..."
    aws cloudfront wait distribution-deployed --id "$DISTRIBUTION_ID"
    
    success "CloudFront distribution is now deployed and ready"
}

update_dns_records() {
    log "Updating DNS records..."
    
    # This assumes you're using Route53 for DNS
    HOSTED_ZONE_ID=$(aws route53 list-hosted-zones --query "HostedZones[?Name=='${DOMAIN_NAME}.'].Id" --output text | cut -d'/' -f3)
    
    if [[ -n "$HOSTED_ZONE_ID" ]]; then
        log "Creating DNS records for CDN subdomains..."
        
        # Create CNAME records for CDN subdomains
        cat > /tmp/dns-changes.json << EOF
{
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "cdn.${DOMAIN_NAME}",
                "Type": "CNAME",
                "TTL": 300,
                "ResourceRecords": [{"Value": "${DISTRIBUTION_DOMAIN}"}]
            }
        },
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "assets.${DOMAIN_NAME}",
                "Type": "CNAME",
                "TTL": 300,
                "ResourceRecords": [{"Value": "${DISTRIBUTION_DOMAIN}"}]
            }
        }
    ]
}
EOF
        
        aws route53 change-resource-record-sets --hosted-zone-id "$HOSTED_ZONE_ID" \
            --change-batch file:///tmp/dns-changes.json
        
        rm /tmp/dns-changes.json
        
        success "DNS records updated successfully"
    else
        warning "Route53 hosted zone not found. Please manually create DNS records:"
        warning "cdn.${DOMAIN_NAME} -> CNAME -> ${DISTRIBUTION_DOMAIN}"
        warning "assets.${DOMAIN_NAME} -> CNAME -> ${DISTRIBUTION_DOMAIN}"
    fi
}

main() {
    log "Starting WhatsApp Clone CDN deployment..."
    
    check_requirements
    create_s3_bucket_for_logs
    create_lambda_functions
    create_waf_web_acl
    create_cloudfront_distribution
    update_dns_records
    
    success "CDN deployment completed successfully!"
    
    log "CDN Configuration Summary:"
    log "Distribution ID: $DISTRIBUTION_ID"
    log "Distribution Domain: $DISTRIBUTION_DOMAIN"
    log "CDN URLs:"
    log "  - https://cdn.${DOMAIN_NAME}"
    log "  - https://assets.${DOMAIN_NAME}"
    log "Lambda@Edge Functions:"
    log "  - Intelligent Routing: $ROUTING_LAMBDA_ARN"
    log "  - Security Headers: $HEADERS_LAMBDA_ARN"
    log "WAF Web ACL: $WAF_WEB_ACL_ID"
    log "S3 Logs Bucket: $S3_BUCKET"
    
    log "Next steps:"
    log "1. Update your Flutter app configuration to use the CDN URLs"
    log "2. Test the CDN from different regions, especially China"
    log "3. Monitor CloudWatch metrics and logs"
    log "4. Set up alerts for CDN performance and security events"
}

# Run the main function
main "$@"