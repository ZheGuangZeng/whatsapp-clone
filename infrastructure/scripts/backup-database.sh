#!/bin/bash

# WhatsApp Clone Database Backup Script
# Supports both Supabase and self-hosted PostgreSQL
# Includes encrypted backups and multi-region replication

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="${PROJECT_NAME:-whatsapp-clone}"
ENVIRONMENT="${ENVIRONMENT:-production}"
BACKUP_DIR="${BACKUP_DIR:-/opt/backups}"
S3_BUCKET="${S3_BUCKET:-whatsapp-clone-backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
ENCRYPTION_KEY_ID="${ENCRYPTION_KEY_ID:-alias/whatsapp-clone-backup}"

# Logging
LOG_FILE="${BACKUP_DIR}/backup-$(date +%Y%m%d).log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2
}

# Check dependencies
check_dependencies() {
    local deps=("pg_dump" "aws" "gpg")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            error "Required dependency '$dep' is not installed"
            exit 1
        fi
    done
    
    log "All dependencies are available"
}

# Get database connection info
get_db_config() {
    if [[ "${DB_TYPE:-supabase}" == "supabase" ]]; then
        # Supabase configuration
        DB_HOST="${SUPABASE_DB_HOST:-db.${SUPABASE_PROJECT_REF}.supabase.co}"
        DB_PORT="${SUPABASE_DB_PORT:-5432}"
        DB_NAME="${SUPABASE_DB_NAME:-postgres}"
        DB_USER="${SUPABASE_DB_USER:-postgres}"
        DB_PASSWORD="${SUPABASE_DB_PASSWORD}"
    else
        # Self-hosted PostgreSQL
        DB_HOST="${DB_HOST:-localhost}"
        DB_PORT="${DB_PORT:-5432}"
        DB_NAME="${DB_NAME:-whatsappclone}"
        DB_USER="${DB_USER:-postgres}"
        DB_PASSWORD="${DB_PASSWORD}"
    fi
    
    if [[ -z "${DB_PASSWORD:-}" ]]; then
        error "Database password not provided"
        exit 1
    fi
    
    export PGPASSWORD="$DB_PASSWORD"
}

# Create database backup
create_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${PROJECT_NAME}_${ENVIRONMENT}_${timestamp}.sql"
    local backup_path="${BACKUP_DIR}/${backup_file}"
    
    log "Starting database backup: $backup_file"
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Create the backup
    if pg_dump \
        --host="$DB_HOST" \
        --port="$DB_PORT" \
        --username="$DB_USER" \
        --dbname="$DB_NAME" \
        --no-password \
        --verbose \
        --format=custom \
        --compress=9 \
        --no-owner \
        --no-privileges \
        --exclude-schema=information_schema \
        --exclude-schema=pg_catalog \
        --file="$backup_path"; then
        
        log "Database backup completed: $backup_path"
        
        # Get backup size
        local backup_size=$(du -h "$backup_path" | cut -f1)
        log "Backup size: $backup_size"
        
        echo "$backup_path"
    else
        error "Database backup failed"
        exit 1
    fi
}

# Encrypt backup
encrypt_backup() {
    local backup_path="$1"
    local encrypted_path="${backup_path}.gpg"
    
    log "Encrypting backup: $(basename "$backup_path")"
    
    if gpg --symmetric \
        --cipher-algo AES256 \
        --compress-algo 2 \
        --s2k-mode 3 \
        --s2k-digest-algo SHA512 \
        --s2k-count 65536 \
        --batch \
        --yes \
        --passphrase="${BACKUP_ENCRYPTION_PASSPHRASE}" \
        --output "$encrypted_path" \
        "$backup_path"; then
        
        log "Backup encrypted: $(basename "$encrypted_path")"
        
        # Remove unencrypted backup
        rm "$backup_path"
        
        echo "$encrypted_path"
    else
        error "Backup encryption failed"
        exit 1
    fi
}

# Upload to S3
upload_to_s3() {
    local backup_path="$1"
    local s3_key="database-backups/${ENVIRONMENT}/$(basename "$backup_path")"
    
    log "Uploading backup to S3: s3://${S3_BUCKET}/${s3_key}"
    
    if aws s3 cp "$backup_path" "s3://${S3_BUCKET}/${s3_key}" \
        --server-side-encryption aws:kms \
        --ssm-kms-key-id "$ENCRYPTION_KEY_ID" \
        --storage-class STANDARD_IA; then
        
        log "Backup uploaded successfully"
        
        # Verify upload
        if aws s3 ls "s3://${S3_BUCKET}/${s3_key}" >/dev/null 2>&1; then
            log "Backup upload verified"
        else
            error "Backup upload verification failed"
            exit 1
        fi
    else
        error "Backup upload failed"
        exit 1
    fi
}

# Cross-region replication
replicate_backup() {
    local backup_path="$1"
    local secondary_region="${SECONDARY_REGION:-ap-northeast-1}"
    local secondary_bucket="${S3_BUCKET}-${secondary_region}"
    local s3_key="database-backups/${ENVIRONMENT}/$(basename "$backup_path")"
    
    log "Replicating backup to secondary region: $secondary_region"
    
    # Copy to secondary region bucket
    if aws s3 cp "s3://${S3_BUCKET}/${s3_key}" "s3://${secondary_bucket}/${s3_key}" \
        --source-region "${AWS_REGION:-ap-southeast-1}" \
        --region "$secondary_region" \
        --server-side-encryption aws:kms \
        --ssm-kms-key-id "$ENCRYPTION_KEY_ID"; then
        
        log "Backup replicated to secondary region"
    else
        error "Backup replication failed"
        exit 1
    fi
}

# Clean up old backups
cleanup_old_backups() {
    log "Cleaning up backups older than $RETENTION_DAYS days"
    
    # Clean up local backups
    if [[ -d "$BACKUP_DIR" ]]; then
        find "$BACKUP_DIR" -name "${PROJECT_NAME}_${ENVIRONMENT}_*.sql.gpg" \
            -mtime +$RETENTION_DAYS -delete
        log "Local backup cleanup completed"
    fi
    
    # Clean up S3 backups
    local cutoff_date=$(date -d "$RETENTION_DAYS days ago" +%Y-%m-%d)
    
    aws s3api list-objects-v2 \
        --bucket "$S3_BUCKET" \
        --prefix "database-backups/${ENVIRONMENT}/" \
        --query "Contents[?LastModified<'${cutoff_date}'].Key" \
        --output text | while read -r key; do
        
        if [[ -n "$key" ]]; then
            aws s3 rm "s3://${S3_BUCKET}/${key}"
            log "Deleted old backup: $key"
        fi
    done
    
    log "S3 backup cleanup completed"
}

# Validate backup integrity
validate_backup() {
    local backup_path="$1"
    
    log "Validating backup integrity: $(basename "$backup_path")"
    
    # Test if backup file can be read by pg_restore
    if pg_restore --list "$backup_path" >/dev/null 2>&1; then
        log "Backup validation successful"
    else
        error "Backup validation failed - backup may be corrupted"
        exit 1
    fi
}

# Send notification
send_notification() {
    local status="$1"
    local backup_file="$2"
    local backup_size="${3:-unknown}"
    
    local sns_topic="${SNS_TOPIC_ARN:-arn:aws:sns:${AWS_REGION}:${AWS_ACCOUNT_ID}:whatsapp-clone-alerts}"
    
    local subject="Database Backup ${status}: ${PROJECT_NAME}-${ENVIRONMENT}"
    local message="
Database backup ${status,,} at $(date)

Project: ${PROJECT_NAME}
Environment: ${ENVIRONMENT}
Backup File: ${backup_file}
Backup Size: ${backup_size}
Retention: ${RETENTION_DAYS} days

$(if [[ "$status" == "FAILED" ]]; then
    echo "Please check the backup logs for details."
else
    echo "Backup has been encrypted and stored securely."
fi)
"
    
    if aws sns publish \
        --topic-arn "$sns_topic" \
        --subject "$subject" \
        --message "$message" >/dev/null 2>&1; then
        
        log "Notification sent successfully"
    else
        error "Failed to send notification"
    fi
}

# Main backup process
main() {
    local start_time=$(date +%s)
    
    log "Starting backup process for ${PROJECT_NAME}-${ENVIRONMENT}"
    
    # Validate prerequisites
    check_dependencies
    get_db_config
    
    # Perform backup
    local backup_path
    local backup_size
    
    if backup_path=$(create_backup); then
        
        # Validate backup
        validate_backup "$backup_path"
        
        # Get backup size before encryption
        backup_size=$(du -h "$backup_path" | cut -f1)
        
        # Encrypt backup
        if [[ "${ENCRYPT_BACKUP:-true}" == "true" ]]; then
            backup_path=$(encrypt_backup "$backup_path")
        fi
        
        # Upload to S3
        upload_to_s3 "$backup_path"
        
        # Replicate to secondary region
        if [[ "${ENABLE_REPLICATION:-true}" == "true" ]]; then
            replicate_backup "$backup_path"
        fi
        
        # Clean up old backups
        cleanup_old_backups
        
        # Calculate duration
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        log "Backup process completed successfully in ${duration} seconds"
        
        # Send success notification
        send_notification "SUCCESS" "$(basename "$backup_path")" "$backup_size"
        
        # Clean up local backup if upload was successful
        rm -f "$backup_path"
        
    else
        error "Backup process failed"
        send_notification "FAILED" "N/A" "N/A"
        exit 1
    fi
}

# Handle script interruption
trap 'error "Backup process interrupted"; exit 1' INT TERM

# Run main function
main "$@"