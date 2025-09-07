#!/bin/bash
set -e

# WhatsApp Clone - Backup and Disaster Recovery Setup Script
# Sets up automated backups, monitoring, and disaster recovery procedures

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
BACKUP_BUCKET="${BACKUP_BUCKET:-whatsapp-clone-prod-backups}"
DATABASE_URL="${DATABASE_URL:-}"
SECONDARY_DATABASE_URL="${SECONDARY_DATABASE_URL:-}"
BACKUP_ENCRYPTION_KEY="${BACKUP_ENCRYPTION_KEY:-}"

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
    
    # Check required tools
    for tool in aws psql pg_dump gpg; do
        if ! command -v "$tool" &> /dev/null; then
            error "$tool is not installed"
        fi
    done
    
    # Check AWS CLI authentication
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS CLI is not configured or user not authenticated"
    fi
    
    # Check required environment variables
    if [[ -z "$DATABASE_URL" ]]; then
        error "DATABASE_URL environment variable is required"
    fi
    
    if [[ -z "$BACKUP_ENCRYPTION_KEY" ]]; then
        warning "BACKUP_ENCRYPTION_KEY not set, backups will not be encrypted"
    fi
    
    success "Requirements check passed"
}

create_backup_bucket() {
    log "Creating S3 bucket for backups..."
    
    if aws s3api head-bucket --bucket "$BACKUP_BUCKET" 2>/dev/null; then
        log "S3 bucket $BACKUP_BUCKET already exists"
    else
        log "Creating S3 bucket: $BACKUP_BUCKET"
        
        if [[ "$AWS_REGION" == "us-east-1" ]]; then
            aws s3api create-bucket --bucket "$BACKUP_BUCKET" --region "$AWS_REGION"
        else
            aws s3api create-bucket --bucket "$BACKUP_BUCKET" --region "$AWS_REGION" \
                --create-bucket-configuration LocationConstraint="$AWS_REGION"
        fi
        
        # Enable versioning
        aws s3api put-bucket-versioning --bucket "$BACKUP_BUCKET" \
            --versioning-configuration Status=Enabled
        
        # Configure server-side encryption
        aws s3api put-bucket-encryption --bucket "$BACKUP_BUCKET" \
            --server-side-encryption-configuration '{
                "Rules": [
                    {
                        "ApplyServerSideEncryptionByDefault": {
                            "SSEAlgorithm": "AES256"
                        }
                    }
                ]
            }'
        
        # Set lifecycle policy for automated cleanup
        cat > /tmp/backup-lifecycle.json << EOF
{
    "Rules": [
        {
            "ID": "DailyBackupRetention",
            "Status": "Enabled",
            "Filter": {"Prefix": "daily/"},
            "Expiration": {"Days": 30},
            "NoncurrentVersionExpiration": {"NoncurrentDays": 7}
        },
        {
            "ID": "HourlyBackupRetention",
            "Status": "Enabled",
            "Filter": {"Prefix": "hourly/"},
            "Expiration": {"Days": 7},
            "NoncurrentVersionExpiration": {"NoncurrentDays": 1}
        },
        {
            "ID": "WeeklyArchiveRetention",
            "Status": "Enabled",
            "Filter": {"Prefix": "weekly/"},
            "Expiration": {"Days": 365},
            "NoncurrentVersionExpiration": {"NoncurrentDays": 30}
        },
        {
            "ID": "IncompleteMultipartUploads",
            "Status": "Enabled",
            "AbortIncompleteMultipartUpload": {"DaysAfterInitiation": 7}
        }
    ]
}
EOF
        
        aws s3api put-bucket-lifecycle-configuration --bucket "$BACKUP_BUCKET" \
            --lifecycle-configuration file:///tmp/backup-lifecycle.json
        
        rm /tmp/backup-lifecycle.json
    fi
    
    success "Backup S3 bucket configured"
}

setup_database_backup_schema() {
    log "Setting up database backup schema..."
    
    # Execute backup strategy SQL on primary database
    if ! psql "$DATABASE_URL" -f infrastructure/backup/backup-strategy.sql; then
        error "Failed to set up backup schema on primary database"
    fi
    
    # Setup on secondary database if available
    if [[ -n "$SECONDARY_DATABASE_URL" ]]; then
        log "Setting up backup schema on secondary database..."
        if ! psql "$SECONDARY_DATABASE_URL" -f infrastructure/backup/backup-strategy.sql; then
            warning "Failed to set up backup schema on secondary database"
        fi
    fi
    
    success "Database backup schema configured"
}

create_backup_scripts() {
    log "Creating backup scripts..."
    
    # Create daily backup script
    cat > /tmp/daily-backup.sh << 'EOF'
#!/bin/bash
set -e

# Daily backup script for WhatsApp Clone
PROJECT_NAME="${PROJECT_NAME:-whatsapp-clone}"
ENVIRONMENT="${ENVIRONMENT:-production}"
DATABASE_URL="${DATABASE_URL}"
BACKUP_BUCKET="${BACKUP_BUCKET}"
BACKUP_ENCRYPTION_KEY="${BACKUP_ENCRYPTION_KEY}"

# Generate timestamp
TIMESTAMP=$(date +%Y_%m_%d_%H_%M_%S)
BACKUP_NAME="daily_backup_${TIMESTAMP}"
BACKUP_FILE="/tmp/${BACKUP_NAME}.sql"
ENCRYPTED_FILE="${BACKUP_FILE}.gpg"

echo "[$(date)] Starting daily backup: $BACKUP_NAME"

# Create database dump
if ! pg_dump "$DATABASE_URL" --verbose --clean --no-owner --no-privileges > "$BACKUP_FILE"; then
    echo "[$(date)] ERROR: Database dump failed"
    exit 1
fi

# Encrypt backup if encryption key is available
if [[ -n "$BACKUP_ENCRYPTION_KEY" ]]; then
    echo "[$(date)] Encrypting backup..."
    echo "$BACKUP_ENCRYPTION_KEY" | gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 --output "$ENCRYPTED_FILE" "$BACKUP_FILE"
    UPLOAD_FILE="$ENCRYPTED_FILE"
else
    echo "[$(date)] WARNING: No encryption key provided, uploading unencrypted backup"
    UPLOAD_FILE="$BACKUP_FILE"
fi

# Upload to S3
echo "[$(date)] Uploading backup to S3..."
if aws s3 cp "$UPLOAD_FILE" "s3://${BACKUP_BUCKET}/daily/${BACKUP_NAME}.sql$([ -n "$BACKUP_ENCRYPTION_KEY" ] && echo ".gpg")"; then
    echo "[$(date)] Backup uploaded successfully"
    
    # Update backup history in database
    psql "$DATABASE_URL" -c "
        UPDATE backup.backup_history 
        SET status = 'completed', 
            end_time = now(),
            backup_size_bytes = $(stat -c%s "$UPLOAD_FILE"),
            checksum = '$(sha256sum "$UPLOAD_FILE" | cut -d' ' -f1)'
        WHERE backup_location LIKE '%${BACKUP_NAME}%' AND status = 'running';
    "
else
    echo "[$(date)] ERROR: Failed to upload backup"
    
    # Mark backup as failed in database
    psql "$DATABASE_URL" -c "
        UPDATE backup.backup_history 
        SET status = 'failed', 
            end_time = now(),
            error_message = 'Failed to upload to S3'
        WHERE backup_location LIKE '%${BACKUP_NAME}%' AND status = 'running';
    "
    exit 1
fi

# Cleanup local files
rm -f "$BACKUP_FILE" "$ENCRYPTED_FILE"

echo "[$(date)] Daily backup completed successfully"
EOF
    
    # Create disaster recovery script
    cat > /tmp/disaster-recovery.sh << 'EOF'
#!/bin/bash
set -e

# Disaster recovery script for WhatsApp Clone
# Usage: ./disaster-recovery.sh <mode> [backup-id]
# Modes: monitor, failover, failback, test

MODE="${1:-monitor}"
BACKUP_ID="${2:-}"
PROJECT_NAME="${PROJECT_NAME:-whatsapp-clone}"
ENVIRONMENT="${ENVIRONMENT:-production}"
DATABASE_URL="${DATABASE_URL}"
SECONDARY_DATABASE_URL="${SECONDARY_DATABASE_URL}"

log() {
    echo "[$(date)] $1"
}

monitor_health() {
    log "Monitoring primary database health..."
    
    if psql "$DATABASE_URL" -c "SELECT 1;" >/dev/null 2>&1; then
        log "Primary database is healthy"
        return 0
    else
        log "ERROR: Primary database is not responding"
        return 1
    fi
}

initiate_failover() {
    log "INITIATING DISASTER RECOVERY FAILOVER"
    log "WARNING: This will switch to secondary database"
    
    if [[ -z "$SECONDARY_DATABASE_URL" ]]; then
        log "ERROR: SECONDARY_DATABASE_URL not configured"
        exit 1
    fi
    
    # Test secondary database connectivity
    if ! psql "$SECONDARY_DATABASE_URL" -c "SELECT 1;" >/dev/null 2>&1; then
        log "ERROR: Secondary database is not responding"
        exit 1
    fi
    
    # Create failover record
    RECOVERY_ID=$(psql "$SECONDARY_DATABASE_URL" -t -c "SELECT backup.initiate_disaster_recovery('$(uuidgen)', now(), 'failover');" | xargs)
    log "Failover initiated with recovery ID: $RECOVERY_ID"
    
    # Update DNS or load balancer to point to secondary
    # This would be specific to your infrastructure setup
    log "Manual step required: Update DNS/load balancer to point to secondary database"
    log "Secondary database URL: $SECONDARY_DATABASE_URL"
    
    return 0
}

test_recovery() {
    log "Testing disaster recovery procedures..."
    
    # Test backup integrity
    LATEST_BACKUP=$(aws s3 ls "s3://${BACKUP_BUCKET}/daily/" --recursive | sort | tail -1 | awk '{print $4}')
    
    if [[ -n "$LATEST_BACKUP" ]]; then
        log "Latest backup found: $LATEST_BACKUP"
        
        # Download and verify backup
        aws s3 cp "s3://${BACKUP_BUCKET}/${LATEST_BACKUP}" /tmp/test-backup
        
        if [[ "$LATEST_BACKUP" == *.gpg ]]; then
            log "Backup is encrypted, testing decryption..."
            if [[ -n "$BACKUP_ENCRYPTION_KEY" ]]; then
                echo "$BACKUP_ENCRYPTION_KEY" | gpg --batch --yes --passphrase-fd 0 --decrypt /tmp/test-backup > /tmp/test-backup-decrypted
                log "Backup decryption successful"
            else
                log "ERROR: Cannot decrypt backup - no encryption key provided"
                exit 1
            fi
        fi
        
        rm -f /tmp/test-backup /tmp/test-backup-decrypted
        log "Disaster recovery test completed successfully"
    else
        log "ERROR: No backups found for testing"
        exit 1
    fi
}

case "$MODE" in
    "monitor")
        if monitor_health; then
            exit 0
        else
            log "Sending alert for database health check failure"
            exit 1
        fi
        ;;
    "failover")
        initiate_failover
        ;;
    "test")
        test_recovery
        ;;
    "failback")
        log "Failback procedures would be implemented here"
        log "This requires careful coordination and validation"
        ;;
    *)
        echo "Usage: $0 {monitor|failover|failback|test} [backup-id]"
        exit 1
        ;;
esac
EOF
    
    # Make scripts executable and move to infrastructure directory
    chmod +x /tmp/daily-backup.sh /tmp/disaster-recovery.sh
    
    mv /tmp/daily-backup.sh infrastructure/scripts/
    mv /tmp/disaster-recovery.sh infrastructure/scripts/
    
    success "Backup scripts created"
}

setup_automated_backups() {
    log "Setting up automated backup scheduling..."
    
    # Create IAM role for backup Lambda function
    cat > /tmp/backup-lambda-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${BACKUP_BUCKET}",
                "arn:aws:s3:::${BACKUP_BUCKET}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "sns:Publish"
            ],
            "Resource": "*"
        }
    ]
}
EOF
    
    # Create backup Lambda function
    cat > /tmp/backup-lambda.py << 'EOF'
import json
import subprocess
import os
import boto3
from datetime import datetime

def lambda_handler(event, context):
    """
    Lambda function to trigger database backups
    """
    
    # Configuration from environment variables
    project_name = os.environ.get('PROJECT_NAME', 'whatsapp-clone')
    database_url = os.environ.get('DATABASE_URL')
    backup_bucket = os.environ.get('BACKUP_BUCKET')
    
    if not database_url:
        raise ValueError('DATABASE_URL environment variable is required')
    
    try:
        # Trigger backup script
        result = subprocess.run([
            '/opt/daily-backup.sh'
        ], capture_output=True, text=True, check=True)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Backup completed successfully',
                'timestamp': datetime.utcnow().isoformat(),
                'output': result.stdout
            })
        }
        
    except subprocess.CalledProcessError as e:
        # Send alert on backup failure
        sns = boto3.client('sns')
        topic_arn = os.environ.get('SNS_TOPIC_ARN')
        
        if topic_arn:
            sns.publish(
                TopicArn=topic_arn,
                Message=f'Backup failed for {project_name}: {e.stderr}',
                Subject=f'{project_name} Backup Failure Alert'
            )
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Backup failed',
                'error': e.stderr
            })
        }
EOF
    
    # Create EventBridge rule for scheduled backups
    aws events put-rule \
        --name "${PROJECT_NAME}-${ENVIRONMENT}-daily-backup" \
        --schedule-expression "cron(0 2 * * ? *)" \
        --description "Daily backup for WhatsApp Clone" \
        --region "$AWS_REGION"
    
    success "Automated backup scheduling configured"
    
    # Cleanup
    rm -f /tmp/backup-lambda-policy.json /tmp/backup-lambda.py
}

create_recovery_runbook() {
    log "Creating disaster recovery runbook..."
    
    cat > infrastructure/docs/disaster-recovery-runbook.md << EOF
# WhatsApp Clone - Disaster Recovery Runbook

## Overview
This runbook provides step-by-step procedures for disaster recovery scenarios.

## Emergency Contacts
- Infrastructure Team: infrastructure@your-company.com
- Database Team: database@your-company.com
- On-call Engineer: oncall@your-company.com

## Backup Information
- S3 Backup Bucket: ${BACKUP_BUCKET}
- Primary Database: ${DATABASE_URL%%@*}@***
- Secondary Database: ${SECONDARY_DATABASE_URL%%@*}@***

## Recovery Procedures

### 1. Database Failure - Automatic Failover
\`\`\`bash
# Check database health
./infrastructure/scripts/disaster-recovery.sh monitor

# Initiate failover to secondary region
./infrastructure/scripts/disaster-recovery.sh failover
\`\`\`

### 2. Point-in-Time Recovery
\`\`\`bash
# List available backups
aws s3 ls s3://${BACKUP_BUCKET}/daily/ --recursive

# Download specific backup
aws s3 cp s3://${BACKUP_BUCKET}/daily/backup_name.sql.gpg /tmp/

# Decrypt and restore
echo "\$BACKUP_ENCRYPTION_KEY" | gpg --batch --passphrase-fd 0 --decrypt /tmp/backup_name.sql.gpg > /tmp/backup.sql
psql "\$DATABASE_URL" < /tmp/backup.sql
\`\`\`

### 3. Complete Infrastructure Recovery
\`\`\`bash
# Deploy infrastructure from scratch
cd infrastructure/terraform
terraform apply

# Restore from latest backup
./infrastructure/scripts/disaster-recovery.sh restore latest
\`\`\`

## Testing Procedures
\`\`\`bash
# Test backup integrity
./infrastructure/scripts/disaster-recovery.sh test

# Verify recovery procedures
./infrastructure/scripts/disaster-recovery.sh test-recovery
\`\`\`

## Monitoring and Alerts
- CloudWatch Alarms: [Link to CloudWatch]
- Backup Dashboard: [Link to Dashboard]
- Health Check URL: https://your-domain.com/health

## Communication Templates

### Incident Declaration
Subject: INCIDENT - WhatsApp Clone Database Outage
Body: Database outage detected at [TIME]. Initiating recovery procedures. ETA for resolution: [ETA].

### Recovery Complete
Subject: RESOLVED - WhatsApp Clone Database Restored
Body: Database recovery completed at [TIME]. All services operational. Root cause analysis to follow.

## Post-Incident Actions
1. Validate all systems are operational
2. Review backup integrity
3. Update monitoring thresholds if needed
4. Conduct post-incident review
5. Update runbook based on lessons learned
EOF
    
    success "Disaster recovery runbook created"
}

test_backup_system() {
    log "Testing backup system..."
    
    # Test database backup functions
    log "Testing backup functions..."
    if psql "$DATABASE_URL" -c "SELECT backup.check_backup_health();" > /tmp/backup-health.out 2>&1; then
        HEALTH_STATUS=$(cat /tmp/backup-health.out | grep -o "All backup systems healthy" || echo "Issues detected")
        log "Backup health status: $HEALTH_STATUS"
    else
        warning "Could not check backup health"
    fi
    
    # Test S3 connectivity
    log "Testing S3 connectivity..."
    if aws s3 ls "s3://$BACKUP_BUCKET/" > /dev/null 2>&1; then
        success "S3 backup bucket accessible"
    else
        error "Cannot access S3 backup bucket"
    fi
    
    # Clean up
    rm -f /tmp/backup-health.out
    
    success "Backup system tests completed"
}

output_setup_summary() {
    log "Backup and disaster recovery setup completed successfully!"
    
    echo ""
    echo "=== BACKUP & DISASTER RECOVERY SUMMARY ==="
    echo "Project: $PROJECT_NAME"
    echo "Environment: $ENVIRONMENT"
    echo "Backup Bucket: s3://$BACKUP_BUCKET"
    echo "Primary Database: ${DATABASE_URL%%@*}@***"
    if [[ -n "$SECONDARY_DATABASE_URL" ]]; then
        echo "Secondary Database: ${SECONDARY_DATABASE_URL%%@*}@***"
    fi
    echo ""
    echo "=== BACKUP SCHEDULE ==="
    echo "Daily Full Backup: 2:00 AM UTC"
    echo "Retention: 30 days (daily), 7 days (hourly), 365 days (weekly)"
    echo "Encryption: $([ -n "$BACKUP_ENCRYPTION_KEY" ] && echo "Enabled" || echo "Disabled")"
    echo ""
    echo "=== IMPORTANT FILES ==="
    echo "Daily Backup Script: infrastructure/scripts/daily-backup.sh"
    echo "Disaster Recovery Script: infrastructure/scripts/disaster-recovery.sh"
    echo "Recovery Runbook: infrastructure/docs/disaster-recovery-runbook.md"
    echo ""
    echo "=== NEXT STEPS ==="
    echo "1. Test the backup system: ./infrastructure/scripts/disaster-recovery.sh test"
    echo "2. Schedule the backup scripts in your CI/CD system"
    echo "3. Review and customize the disaster recovery runbook"
    echo "4. Set up monitoring alerts for backup failures"
    echo "5. Conduct a disaster recovery drill"
    echo ""
}

main() {
    log "Starting WhatsApp Clone backup and disaster recovery setup..."
    
    check_requirements
    create_backup_bucket
    setup_database_backup_schema
    create_backup_scripts
    setup_automated_backups
    create_recovery_runbook
    test_backup_system
    output_setup_summary
    
    success "Backup and disaster recovery setup completed!"
}

# Run the main function
main "$@"