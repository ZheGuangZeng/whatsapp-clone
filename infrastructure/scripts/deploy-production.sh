#!/bin/bash
set -e

# WhatsApp Clone - Complete Production Infrastructure Deployment Script
# Orchestrates the entire production infrastructure deployment process

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="${PROJECT_NAME:-whatsapp-clone}"
ENVIRONMENT="${ENVIRONMENT:-production}"
AWS_REGION="${AWS_REGION:-ap-southeast-1}"
DOMAIN_NAME="${DOMAIN_NAME:-}"
SSL_CERTIFICATE_ARN="${SSL_CERTIFICATE_ARN:-}"
ALERT_EMAIL="${ALERT_EMAIL:-}"

# Infrastructure Components
DEPLOY_TERRAFORM="${DEPLOY_TERRAFORM:-true}"
DEPLOY_SUPABASE="${DEPLOY_SUPABASE:-true}"
DEPLOY_CDN="${DEPLOY_CDN:-true}"
DEPLOY_MONITORING="${DEPLOY_MONITORING:-true}"
DEPLOY_BACKUP="${DEPLOY_BACKUP:-true}"

# Required Environment Variables
REQUIRED_VARS=(
    "DOMAIN_NAME"
    "SSL_CERTIFICATE_ARN" 
    "ALERT_EMAIL"
    "SUPABASE_PRIMARY_PROJECT_REF"
    "SUPABASE_DB_PASSWORD"
    "DATABASE_URL"
)

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

section() {
    echo -e "${PURPLE}
==============================================================================
$1
==============================================================================${NC}"
}

check_prerequisites() {
    section "CHECKING PREREQUISITES"
    
    log "Validating environment and dependencies..."
    
    # Check required tools
    local tools=("aws" "terraform" "psql" "supabase" "kubectl" "helm" "jq" "git")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            error "Required tool '$tool' is not installed"
        fi
        log "✓ $tool is available"
    done
    
    # Check AWS authentication
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS CLI is not configured or user not authenticated"
    fi
    log "✓ AWS authentication verified"
    
    # Check required environment variables
    local missing_vars=()
    for var in "${REQUIRED_VARS[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("$var")
        else
            log "✓ $var is set"
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        error "Missing required environment variables: ${missing_vars[*]}"
    fi
    
    # Check Git status
    if [[ -n "$(git status --porcelain)" ]]; then
        warning "Working directory has uncommitted changes"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    success "Prerequisites check completed"
}

deploy_terraform_infrastructure() {
    if [[ "$DEPLOY_TERRAFORM" != "true" ]]; then
        log "Skipping Terraform deployment"
        return 0
    fi
    
    section "DEPLOYING TERRAFORM INFRASTRUCTURE"
    
    log "Initializing and deploying AWS infrastructure..."
    
    cd infrastructure/terraform
    
    # Initialize Terraform
    log "Initializing Terraform..."
    if ! terraform init; then
        error "Terraform initialization failed"
    fi
    
    # Plan deployment
    log "Creating Terraform plan..."
    if ! terraform plan \
        -var="project_name=$PROJECT_NAME" \
        -var="environment=$ENVIRONMENT" \
        -var="region=$AWS_REGION" \
        -var="domain_name=$DOMAIN_NAME" \
        -var="ssl_certificate_arn=$SSL_CERTIFICATE_ARN" \
        -out=tfplan; then
        error "Terraform planning failed"
    fi
    
    # Apply infrastructure
    log "Applying Terraform configuration..."
    if ! terraform apply tfplan; then
        error "Terraform apply failed"
    fi
    
    # Export outputs
    log "Exporting Terraform outputs..."
    export VPC_ID=$(terraform output -raw vpc_id)
    export EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
    export ALB_DNS_NAME=$(terraform output -raw alb_dns_name)
    export RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
    
    cd - > /dev/null
    
    success "Terraform infrastructure deployed successfully"
}

deploy_supabase_production() {
    if [[ "$DEPLOY_SUPABASE" != "true" ]]; then
        log "Skipping Supabase deployment"
        return 0
    fi
    
    section "CONFIGURING SUPABASE PRODUCTION"
    
    log "Setting up production Supabase configuration..."
    
    # Make sure setup script is executable
    chmod +x infrastructure/scripts/setup-production-supabase.sh
    
    # Run Supabase setup
    if ! ./infrastructure/scripts/setup-production-supabase.sh; then
        error "Supabase production setup failed"
    fi
    
    success "Supabase production environment configured"
}

deploy_cdn_infrastructure() {
    if [[ "$DEPLOY_CDN" != "true" ]]; then
        log "Skipping CDN deployment"
        return 0
    fi
    
    section "DEPLOYING CDN INFRASTRUCTURE"
    
    log "Setting up CloudFront CDN with Lambda@Edge..."
    
    # Make sure CDN script is executable
    chmod +x infrastructure/scripts/deploy-cdn.sh
    
    # Deploy CDN
    if ! ./infrastructure/scripts/deploy-cdn.sh; then
        error "CDN deployment failed"
    fi
    
    success "CDN infrastructure deployed successfully"
}

deploy_monitoring_system() {
    if [[ "$DEPLOY_MONITORING" != "true" ]]; then
        log "Skipping monitoring deployment"
        return 0
    fi
    
    section "SETTING UP MONITORING AND ALERTING"
    
    log "Configuring CloudWatch monitoring and alerting..."
    
    # Make sure monitoring script is executable
    chmod +x infrastructure/scripts/setup-monitoring.sh
    
    # Deploy monitoring
    if ! ./infrastructure/scripts/setup-monitoring.sh; then
        error "Monitoring setup failed"
    fi
    
    success "Monitoring and alerting configured"
}

deploy_backup_system() {
    if [[ "$DEPLOY_BACKUP" != "true" ]]; then
        log "Skipping backup system deployment"
        return 0
    fi
    
    section "CONFIGURING BACKUP AND DISASTER RECOVERY"
    
    log "Setting up automated backups and disaster recovery..."
    
    # Make sure backup script is executable
    chmod +x infrastructure/scripts/setup-backup-recovery.sh
    
    # Deploy backup system
    if ! ./infrastructure/scripts/setup-backup-recovery.sh; then
        error "Backup system setup failed"
    fi
    
    success "Backup and disaster recovery configured"
}

update_flutter_configuration() {
    section "UPDATING FLUTTER CONFIGURATION"
    
    log "Updating Flutter app with production configuration..."
    
    # Update Flutter environment configuration
    cat > .env.production.local << EOF
# Generated production configuration
ENVIRONMENT=production
SUPABASE_URL=${SUPABASE_URL:-https://${SUPABASE_PRIMARY_PROJECT_REF}.supabase.co}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
CDN_URL=https://cdn.${DOMAIN_NAME}
API_BASE_URL=https://api.${DOMAIN_NAME}
LIVEKIT_URL=${LIVEKIT_URL}
ENABLE_ANALYTICS=true
ENABLE_CRASH_REPORTING=true
ENABLE_PERFORMANCE_MONITORING=true
EOF
    
    # Build Flutter app for production
    log "Building Flutter app for production..."
    if command -v flutter &> /dev/null; then
        flutter clean
        flutter pub get
        
        # Build for different platforms
        if [[ "${BUILD_ANDROID:-false}" == "true" ]]; then
            log "Building Android APK..."
            flutter build apk --release --dart-define-from-file=.env.production.local
        fi
        
        if [[ "${BUILD_IOS:-false}" == "true" ]]; then
            log "Building iOS app..."
            flutter build ios --release --dart-define-from-file=.env.production.local
        fi
        
        if [[ "${BUILD_WEB:-true}" == "true" ]]; then
            log "Building web app..."
            flutter build web --release --dart-define-from-file=.env.production.local
        fi
    else
        warning "Flutter not found, skipping app build"
    fi
    
    success "Flutter configuration updated"
}

run_smoke_tests() {
    section "RUNNING SMOKE TESTS"
    
    log "Performing post-deployment validation..."
    
    # Test database connectivity
    log "Testing database connectivity..."
    if psql "$DATABASE_URL" -c "SELECT 1;" > /dev/null 2>&1; then
        success "✓ Database connection successful"
    else
        error "✗ Database connection failed"
    fi
    
    # Test CDN endpoints
    log "Testing CDN endpoints..."
    local cdn_url="https://cdn.${DOMAIN_NAME}"
    if curl -s -o /dev/null -w "%{http_code}" "$cdn_url" | grep -q "200\|403"; then
        success "✓ CDN endpoint accessible"
    else
        warning "⚠ CDN endpoint not yet accessible (DNS propagation may be pending)"
    fi
    
    # Test monitoring alerts
    log "Testing monitoring system..."
    if aws cloudwatch describe-alarms --region "$AWS_REGION" --alarm-names "${PROJECT_NAME}-${ENVIRONMENT}-application-health-composite" &> /dev/null; then
        success "✓ Monitoring alarms configured"
    else
        warning "⚠ Some monitoring alarms may not be active yet"
    fi
    
    # Test backup system
    log "Testing backup system..."
    if aws s3 ls "s3://${PROJECT_NAME}-${ENVIRONMENT}-backups" &> /dev/null; then
        success "✓ Backup system accessible"
    else
        warning "⚠ Backup system may need manual verification"
    fi
    
    success "Smoke tests completed"
}

create_deployment_summary() {
    section "DEPLOYMENT SUMMARY"
    
    local summary_file="deployment-summary-$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$summary_file" << EOF
# WhatsApp Clone Production Deployment Summary

**Deployment Date:** $(date)
**Environment:** $ENVIRONMENT
**Region:** $AWS_REGION
**Domain:** $DOMAIN_NAME

## Infrastructure Components Deployed

### Core Infrastructure
- [${DEPLOY_TERRAFORM:-false}] Terraform AWS Infrastructure (VPC, EKS, RDS, etc.)
- [${DEPLOY_SUPABASE:-false}] Supabase Production Configuration
- [${DEPLOY_CDN:-false}] CloudFront CDN with Lambda@Edge
- [${DEPLOY_MONITORING:-false}] CloudWatch Monitoring and Alerting
- [${DEPLOY_BACKUP:-false}] Automated Backup and Disaster Recovery

### Endpoints and URLs
- **Main Application:** https://$DOMAIN_NAME
- **CDN Assets:** https://cdn.$DOMAIN_NAME
- **API Endpoint:** https://api.$DOMAIN_NAME
- **Admin Dashboard:** https://admin.$DOMAIN_NAME

### AWS Resources
- **VPC ID:** ${VPC_ID:-N/A}
- **EKS Cluster:** ${EKS_CLUSTER_NAME:-N/A}
- **Load Balancer:** ${ALB_DNS_NAME:-N/A}
- **Database:** ${RDS_ENDPOINT:-N/A}

### Monitoring and Alerting
- **CloudWatch Dashboard:** [Link](https://console.aws.amazon.com/cloudwatch/home?region=$AWS_REGION#dashboards:name=${PROJECT_NAME}-${ENVIRONMENT}-overview)
- **SNS Topic:** ${PROJECT_NAME}-${ENVIRONMENT}-alerts
- **Alert Email:** $ALERT_EMAIL

### Backup Configuration
- **S3 Backup Bucket:** ${PROJECT_NAME}-${ENVIRONMENT}-backups
- **Backup Schedule:** Daily at 2:00 AM UTC
- **Retention:** 30 days (daily), 365 days (weekly)

## Security Configuration
- SSL/TLS certificates configured via ACM
- WAF protection enabled on CloudFront
- Row-level security enabled on database
- Encrypted backups with rotation
- VPC network isolation

## Next Steps
1. **DNS Configuration:** Ensure DNS records point to the correct endpoints
2. **SSL Verification:** Verify SSL certificates are properly configured
3. **Monitoring Setup:** Confirm all alerts are working correctly
4. **Backup Testing:** Test backup and restore procedures
5. **Load Testing:** Perform load testing to validate performance
6. **Security Audit:** Conduct security review and penetration testing
7. **Documentation:** Update operational runbooks and procedures

## Support and Maintenance
- **Infrastructure Code:** \`infrastructure/\` directory
- **Deployment Scripts:** \`infrastructure/scripts/\`
- **Monitoring Dashboards:** Available in AWS CloudWatch
- **Disaster Recovery:** See \`infrastructure/docs/disaster-recovery-runbook.md\`

## Rollback Procedures
In case of critical issues:
1. Switch DNS to previous environment
2. Scale down new infrastructure
3. Restore from latest backup if needed
4. Investigate and fix issues before retry

---
*This deployment was automated using the WhatsApp Clone production deployment pipeline.*
EOF
    
    log "Deployment summary saved to: $summary_file"
    
    success "Production deployment completed successfully!"
    
    echo ""
    echo "🎉 WhatsApp Clone Production Infrastructure Deployed! 🎉"
    echo ""
    echo "Key URLs:"
    echo "  Application: https://$DOMAIN_NAME"
    echo "  CDN: https://cdn.$DOMAIN_NAME" 
    echo "  Monitoring: https://console.aws.amazon.com/cloudwatch/home?region=$AWS_REGION"
    echo ""
    echo "Next Steps:"
    echo "  1. Test all endpoints and functionality"
    echo "  2. Monitor CloudWatch dashboards for any issues"
    echo "  3. Verify backup procedures are working"
    echo "  4. Conduct load testing and security review"
    echo ""
    echo "For support and troubleshooting, see: $summary_file"
    echo ""
}

cleanup_on_error() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        error "Deployment failed with exit code $exit_code"
        log "Check the logs above for specific error details"
        log "You may need to manually clean up partially deployed resources"
    fi
    exit $exit_code
}

main() {
    # Set up error handling
    trap cleanup_on_error EXIT
    
    section "WHATSAPP CLONE PRODUCTION DEPLOYMENT"
    log "Starting complete production infrastructure deployment..."
    log "Project: $PROJECT_NAME"
    log "Environment: $ENVIRONMENT"
    log "Region: $AWS_REGION"
    log "Domain: $DOMAIN_NAME"
    
    # Execute deployment phases
    check_prerequisites
    deploy_terraform_infrastructure
    deploy_supabase_production
    deploy_cdn_infrastructure
    deploy_monitoring_system
    deploy_backup_system
    update_flutter_configuration
    run_smoke_tests
    create_deployment_summary
    
    # Clear error trap on successful completion
    trap - EXIT
    
    success "🚀 Production deployment completed successfully! 🚀"
}

# Handle command line arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "terraform-only")
        DEPLOY_SUPABASE=false
        DEPLOY_CDN=false
        DEPLOY_MONITORING=false
        DEPLOY_BACKUP=false
        main
        ;;
    "infrastructure-only")
        DEPLOY_TERRAFORM=true
        DEPLOY_SUPABASE=true
        DEPLOY_CDN=true
        DEPLOY_MONITORING=false
        DEPLOY_BACKUP=false
        main
        ;;
    "monitoring-only")
        DEPLOY_TERRAFORM=false
        DEPLOY_SUPABASE=false
        DEPLOY_CDN=false
        DEPLOY_MONITORING=true
        DEPLOY_BACKUP=true
        main
        ;;
    "help")
        echo "Usage: $0 [deploy|terraform-only|infrastructure-only|monitoring-only|help]"
        echo ""
        echo "Commands:"
        echo "  deploy              - Full production deployment (default)"
        echo "  terraform-only      - Deploy only Terraform infrastructure"
        echo "  infrastructure-only - Deploy infrastructure without monitoring"
        echo "  monitoring-only     - Deploy only monitoring and backup systems"
        echo "  help               - Show this help message"
        echo ""
        echo "Environment Variables:"
        echo "  PROJECT_NAME                   - Project name (default: whatsapp-clone)"
        echo "  ENVIRONMENT                    - Environment (default: production)"
        echo "  AWS_REGION                     - AWS region (default: ap-southeast-1)"
        echo "  DOMAIN_NAME                    - Production domain name (required)"
        echo "  SSL_CERTIFICATE_ARN            - ACM certificate ARN (required)"
        echo "  ALERT_EMAIL                    - Email for alerts (required)"
        echo "  SUPABASE_PRIMARY_PROJECT_REF   - Primary Supabase project (required)"
        echo "  SUPABASE_DB_PASSWORD           - Database password (required)"
        echo "  DATABASE_URL                   - Database connection URL (required)"
        echo ""
        ;;
    *)
        error "Unknown command: $1. Use 'help' for usage information."
        ;;
esac