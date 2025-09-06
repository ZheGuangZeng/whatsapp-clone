#!/bin/bash

# WhatsApp Clone Disaster Recovery Script
# Automated failover and recovery procedures for multi-region deployment

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="${PROJECT_NAME:-whatsapp-clone}"
ENVIRONMENT="${ENVIRONMENT:-production}"
PRIMARY_REGION="${PRIMARY_REGION:-ap-southeast-1}"
SECONDARY_REGION="${SECONDARY_REGION:-ap-northeast-1}"

# AWS Configuration
PRIMARY_CLUSTER="${PROJECT_NAME}-${ENVIRONMENT}-sg"
SECONDARY_CLUSTER="${PROJECT_NAME}-${ENVIRONMENT}-jp"
ROUTE53_HOSTED_ZONE_ID="${ROUTE53_HOSTED_ZONE_ID}"
DOMAIN_NAME="${DOMAIN_NAME:-whatsappclone.com}"

# Recovery Configuration
RECOVERY_TIMEOUT="${RECOVERY_TIMEOUT:-1800}"  # 30 minutes
HEALTH_CHECK_INTERVAL="${HEALTH_CHECK_INTERVAL:-30}"  # 30 seconds
MAX_HEALTH_CHECK_FAILURES="${MAX_HEALTH_CHECK_FAILURES:-3}"

# Logging
LOG_DIR="/var/log/disaster-recovery"
LOG_FILE="${LOG_DIR}/disaster-recovery-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2
}

warning() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $*" | tee -a "$LOG_FILE"
}

# Check prerequisites
check_prerequisites() {
    local deps=("aws" "kubectl" "dig")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            error "Required dependency '$dep' is not installed"
            exit 1
        fi
    done
    
    # Check AWS credentials
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        error "AWS credentials not configured"
        exit 1
    fi
    
    # Check environment variables
    local required_vars=("ROUTE53_HOSTED_ZONE_ID")
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            error "Required environment variable $var is not set"
            exit 1
        fi
    done
    
    log "Prerequisites check passed"
}

# Health check function
health_check() {
    local region="$1"
    local endpoint="$2"
    
    local health_url="https://${endpoint}/health"
    local response_code
    
    response_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$health_url" || echo "000")
    
    if [[ "$response_code" == "200" ]]; then
        return 0
    else
        return 1
    fi
}

# Check primary region health
check_primary_health() {
    local primary_endpoint="${PRIMARY_REGION}.${DOMAIN_NAME}"
    local failures=0
    
    log "Checking primary region health: $primary_endpoint"
    
    for ((i=1; i<=MAX_HEALTH_CHECK_FAILURES; i++)); do
        if health_check "$PRIMARY_REGION" "$primary_endpoint"; then
            log "Primary region health check passed (attempt $i)"
            return 0
        else
            failures=$i
            warning "Primary region health check failed (attempt $i)"
            
            if [[ $i -lt $MAX_HEALTH_CHECK_FAILURES ]]; then
                sleep "$HEALTH_CHECK_INTERVAL"
            fi
        fi
    done
    
    error "Primary region failed $failures consecutive health checks"
    return 1
}

# Check secondary region readiness
check_secondary_readiness() {
    local secondary_endpoint="${SECONDARY_REGION}.${DOMAIN_NAME}"
    
    log "Checking secondary region readiness: $secondary_endpoint"
    
    # Check if secondary region is healthy
    if health_check "$SECONDARY_REGION" "$secondary_endpoint"; then
        log "Secondary region is healthy and ready"
        
        # Check Kubernetes cluster status
        aws eks update-kubeconfig --region "$SECONDARY_REGION" --name "$SECONDARY_CLUSTER"
        
        if kubectl cluster-info >/dev/null 2>&1; then
            log "Secondary Kubernetes cluster is accessible"
            
            # Check if application pods are ready
            local ready_pods
            ready_pods=$(kubectl get pods -l app=whatsapp-clone-web -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | wc -w)
            
            if [[ "$ready_pods" -gt 0 ]]; then
                log "Secondary region has $ready_pods ready application pods"
                return 0
            else
                error "Secondary region has no ready application pods"
                return 1
            fi
        else
            error "Secondary Kubernetes cluster is not accessible"
            return 1
        fi
    else
        error "Secondary region health check failed"
        return 1
    fi
}

# Update Route53 DNS records for failover
update_dns_failover() {
    local target_region="$1"
    
    log "Updating DNS records to point to $target_region"
    
    local target_endpoint
    if [[ "$target_region" == "secondary" ]]; then
        target_endpoint="${SECONDARY_REGION}.${DOMAIN_NAME}"
    else
        target_endpoint="${PRIMARY_REGION}.${DOMAIN_NAME}"
    fi
    
    # Get the ALB DNS name for the target region
    local alb_dns_name
    if [[ "$target_region" == "secondary" ]]; then
        alb_dns_name=$(aws elbv2 describe-load-balancers \
            --region "$SECONDARY_REGION" \
            --query "LoadBalancers[?contains(LoadBalancerName, '${PROJECT_NAME}')].DNSName" \
            --output text)
    else
        alb_dns_name=$(aws elbv2 describe-load-balancers \
            --region "$PRIMARY_REGION" \
            --query "LoadBalancers[?contains(LoadBalancerName, '${PROJECT_NAME}')].DNSName" \
            --output text)
    fi
    
    if [[ -z "$alb_dns_name" ]]; then
        error "Could not find ALB DNS name for $target_region region"
        return 1
    fi
    
    # Create Route53 change batch
    local change_batch=$(cat <<EOF
{
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "${DOMAIN_NAME}",
                "Type": "A",
                "AliasTarget": {
                    "DNSName": "${alb_dns_name}",
                    "EvaluateTargetHealth": true,
                    "HostedZoneId": "$(aws elbv2 describe-load-balancers --region ${target_region/secondary/$SECONDARY_REGION} --region ${target_region/primary/$PRIMARY_REGION} --query "LoadBalancers[0].CanonicalHostedZoneId" --output text)"
                }
            }
        },
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "www.${DOMAIN_NAME}",
                "Type": "A",
                "AliasTarget": {
                    "DNSName": "${alb_dns_name}",
                    "EvaluateTargetHealth": true,
                    "HostedZoneId": "$(aws elbv2 describe-load-balancers --region ${target_region/secondary/$SECONDARY_REGION} --region ${target_region/primary/$PRIMARY_REGION} --query "LoadBalancers[0].CanonicalHostedZoneId" --output text)"
                }
            }
        }
    ]
}
EOF
)
    
    # Submit DNS change
    local change_id
    change_id=$(aws route53 change-resource-record-sets \
        --hosted-zone-id "$ROUTE53_HOSTED_ZONE_ID" \
        --change-batch "$change_batch" \
        --query 'ChangeInfo.Id' \
        --output text)
    
    if [[ -n "$change_id" ]]; then
        log "DNS change submitted: $change_id"
        
        # Wait for DNS change to propagate
        log "Waiting for DNS change to propagate..."
        aws route53 wait resource-record-sets-changed --id "$change_id"
        
        log "DNS failover completed to $target_region region"
        return 0
    else
        error "Failed to submit DNS change"
        return 1
    fi
}

# Scale up secondary region
scale_secondary_region() {
    log "Scaling up secondary region infrastructure"
    
    # Update kubeconfig for secondary region
    aws eks update-kubeconfig --region "$SECONDARY_REGION" --name "$SECONDARY_CLUSTER"
    
    # Scale up application replicas
    local desired_replicas="${FAILOVER_REPLICAS:-20}"
    
    kubectl scale deployment whatsapp-clone-web --replicas="$desired_replicas" -n whatsapp-clone-prod
    
    # Wait for pods to be ready
    log "Waiting for pods to be ready in secondary region..."
    kubectl rollout status deployment/whatsapp-clone-web -n whatsapp-clone-prod --timeout=300s
    
    local ready_replicas
    ready_replicas=$(kubectl get deployment whatsapp-clone-web -n whatsapp-clone-prod -o jsonpath='{.status.readyReplicas}')
    
    log "Secondary region scaled to $ready_replicas ready replicas"
    
    # Update HPA settings for higher capacity
    kubectl patch hpa whatsapp-clone-web-hpa -n whatsapp-clone-prod -p '{
        "spec": {
            "minReplicas": '$desired_replicas',
            "maxReplicas": 300
        }
    }'
    
    log "Secondary region scaling completed"
}

# Database failover procedures
database_failover() {
    log "Initiating database failover procedures"
    
    # If using RDS Multi-AZ, initiate manual failover
    if [[ "${DB_TYPE:-rds}" == "rds" ]]; then
        local db_cluster_id="${PROJECT_NAME}-${ENVIRONMENT}"
        
        log "Initiating RDS Aurora failover for cluster: $db_cluster_id"
        
        aws rds failover-db-cluster \
            --db-cluster-identifier "$db_cluster_id" \
            --target-db-instance-identifier "${db_cluster_id}-instance-2"
        
        # Wait for failover to complete
        log "Waiting for database failover to complete..."
        aws rds wait db-cluster-available --db-cluster-identifier "$db_cluster_id"
        
        log "Database failover completed"
    fi
    
    # Update connection strings in Kubernetes secrets
    log "Updating database connection strings in secondary region"
    
    # This would typically involve updating the database endpoints
    # in the application configuration to point to the failed-over database
}

# Send disaster recovery notification
send_dr_notification() {
    local status="$1"
    local region="$2"
    local reason="${3:-Manual failover}"
    
    local sns_topic="${SNS_TOPIC_ARN:-arn:aws:sns:${PRIMARY_REGION}:${AWS_ACCOUNT_ID}:whatsapp-clone-alerts}"
    
    local subject="🚨 DISASTER RECOVERY ${status}: ${PROJECT_NAME}-${ENVIRONMENT}"
    local message="
DISASTER RECOVERY EVENT

Project: ${PROJECT_NAME}
Environment: ${ENVIRONMENT}
Timestamp: $(date)
Action: ${status}
Target Region: ${region}
Reason: ${reason}

$(if [[ "$status" == "FAILOVER_INITIATED" ]]; then
    echo "Traffic is being redirected to the secondary region."
    echo "Primary region: $PRIMARY_REGION (FAILED)"
    echo "Secondary region: $SECONDARY_REGION (ACTIVE)"
elif [[ "$status" == "FAILOVER_COMPLETED" ]]; then
    echo "Failover has been completed successfully."
    echo "All traffic is now routed to: $region"
    echo "Please monitor the application closely."
elif [[ "$status" == "FAILBACK_COMPLETED" ]]; then
    echo "Failback to primary region has been completed."
    echo "Normal operations have been restored."
fi)

This is an automated message from the disaster recovery system.
"
    
    aws sns publish \
        --topic-arn "$sns_topic" \
        --subject "$subject" \
        --message "$message" \
        --region "$PRIMARY_REGION"
    
    log "Disaster recovery notification sent"
}

# Main failover process
failover_to_secondary() {
    local reason="${1:-Primary region failure detected}"
    
    log "=== INITIATING DISASTER RECOVERY FAILOVER ==="
    log "Reason: $reason"
    
    send_dr_notification "FAILOVER_INITIATED" "$SECONDARY_REGION" "$reason"
    
    # Check if secondary region is ready
    if ! check_secondary_readiness; then
        error "Secondary region is not ready for failover"
        send_dr_notification "FAILOVER_FAILED" "$SECONDARY_REGION" "Secondary region not ready"
        exit 1
    fi
    
    # Scale up secondary region
    scale_secondary_region
    
    # Database failover
    database_failover
    
    # Update DNS to point to secondary region
    if update_dns_failover "secondary"; then
        log "=== DISASTER RECOVERY FAILOVER COMPLETED ==="
        send_dr_notification "FAILOVER_COMPLETED" "$SECONDARY_REGION" "$reason"
        
        # Record failover state
        echo "SECONDARY" > /tmp/active_region
        echo "$(date)" > /tmp/failover_timestamp
        
        return 0
    else
        error "DNS failover failed"
        send_dr_notification "FAILOVER_FAILED" "$SECONDARY_REGION" "DNS update failed"
        return 1
    fi
}

# Failback to primary region
failback_to_primary() {
    log "=== INITIATING FAILBACK TO PRIMARY REGION ==="
    
    # Check if primary region is healthy
    if ! check_primary_health; then
        error "Primary region is still not healthy - cannot failback"
        return 1
    fi
    
    # Update kubeconfig for primary region
    aws eks update-kubeconfig --region "$PRIMARY_REGION" --name "$PRIMARY_CLUSTER"
    
    # Ensure primary region is scaled properly
    kubectl scale deployment whatsapp-clone-web --replicas=10 -n whatsapp-clone-prod
    kubectl rollout status deployment/whatsapp-clone-web -n whatsapp-clone-prod --timeout=300s
    
    # Update DNS back to primary region
    if update_dns_failover "primary"; then
        log "=== FAILBACK TO PRIMARY REGION COMPLETED ==="
        send_dr_notification "FAILBACK_COMPLETED" "$PRIMARY_REGION" "Primary region recovered"
        
        # Clear failover state
        rm -f /tmp/active_region /tmp/failover_timestamp
        
        # Scale down secondary region to save costs
        aws eks update-kubeconfig --region "$SECONDARY_REGION" --name "$SECONDARY_CLUSTER"
        kubectl scale deployment whatsapp-clone-web --replicas=3 -n whatsapp-clone-prod
        
        return 0
    else
        error "Failback DNS update failed"
        return 1
    fi
}

# Health monitoring daemon
monitoring_daemon() {
    log "Starting disaster recovery monitoring daemon"
    
    while true; do
        if [[ ! -f /tmp/active_region || "$(cat /tmp/active_region)" == "PRIMARY" ]]; then
            # We're currently using primary region
            if ! check_primary_health; then
                warning "Primary region health check failed - initiating automatic failover"
                failover_to_secondary "Automatic failover due to primary region failure"
            fi
        else
            # We're currently using secondary region
            if check_primary_health; then
                log "Primary region is healthy again - consider manual failback"
                # Note: Automatic failback is typically not recommended
                # Require manual intervention for failback
            fi
        fi
        
        sleep "$HEALTH_CHECK_INTERVAL"
    done
}

# Command line interface
case "${1:-monitor}" in
    "failover")
        check_prerequisites
        failover_to_secondary "Manual failover initiated"
        ;;
    "failback")
        check_prerequisites
        failback_to_primary
        ;;
    "health-check")
        check_prerequisites
        if check_primary_health; then
            echo "Primary region is healthy"
            exit 0
        else
            echo "Primary region is not healthy"
            exit 1
        fi
        ;;
    "monitor")
        check_prerequisites
        monitoring_daemon
        ;;
    "status")
        if [[ -f /tmp/active_region ]]; then
            echo "Active region: $(cat /tmp/active_region)"
            if [[ -f /tmp/failover_timestamp ]]; then
                echo "Last failover: $(cat /tmp/failover_timestamp)"
            fi
        else
            echo "Active region: PRIMARY (default)"
        fi
        ;;
    *)
        echo "Usage: $0 {failover|failback|health-check|monitor|status}"
        echo ""
        echo "Commands:"
        echo "  failover     - Manually initiate failover to secondary region"
        echo "  failback     - Manually failback to primary region"
        echo "  health-check - Check primary region health"
        echo "  monitor      - Start monitoring daemon"
        echo "  status       - Show current active region"
        exit 1
        ;;
esac