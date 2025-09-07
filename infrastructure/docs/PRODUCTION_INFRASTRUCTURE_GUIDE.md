# WhatsApp Clone - Production Infrastructure Guide

## Overview

This guide provides comprehensive documentation for the WhatsApp Clone production infrastructure, designed for scalability, security, and reliability in multi-region deployment with China network optimization.

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                    Global CDN (CloudFront)                     │
│              China-Optimized + Lambda@Edge Functions           │
└─────────────────────┬───────────────────────────────────────────┘
                      │
          ┌───────────┴───────────┐
          │                       │
┌─────────▼─────────┐    ┌─────────▼─────────┐
│   Singapore       │    │     Japan         │
│   (Primary)       │    │  (Secondary)      │
│                   │    │                   │
│ ┌───────────────┐ │    │ ┌───────────────┐ │
│ │ Flutter App   │ │    │ │ Flutter App   │ │
│ │ (Mobile/Web)  │ │    │ │ (Replica)     │ │
│ └───────────────┘ │    │ └───────────────┘ │
│                   │    │                   │
│ ┌───────────────┐ │    │ ┌───────────────┐ │
│ │ Supabase      │ │    │ │ Supabase      │ │
│ │ (Primary DB)  │◄├────┤►│ (Replica DB)  │ │
│ └───────────────┘ │    │ └───────────────┘ │
│                   │    │                   │
│ ┌───────────────┐ │    │ ┌───────────────┐ │
│ │ LiveKit       │ │    │ │ LiveKit       │ │
│ │ (Video/Audio) │ │    │ │ (Backup)      │ │
│ └───────────────┘ │    │ └───────────────┘ │
└───────────────────┘    └───────────────────┘
```

## Infrastructure Components

### 1. Multi-Environment Configuration

The infrastructure supports three environments:

- **Development**: Local development and testing
- **Staging**: Pre-production testing and validation  
- **Production**: Live production environment

#### Environment Files

- `.env.production` - Production configuration
- `.env.staging` - Staging configuration
- `lib/core/config/environment_config.dart` - Flutter environment management

### 2. Supabase Database Infrastructure

#### Primary Database (Singapore)
- **URL**: `https://your-production-project-sg.supabase.co`
- **Features**: 
  - Row-level security (RLS) enabled
  - Real-time subscriptions
  - Automated backups
  - Performance monitoring

#### Secondary Database (Japan)
- **URL**: `https://your-production-project-jp.supabase.co`
- **Purpose**: Failover and read replicas for China users
- **Replication**: Near real-time replication

#### Security Configuration
```sql
-- Row-level security policies
CREATE POLICY "Users can only view their own data" ON users
  FOR ALL USING (auth.uid() = id);

-- Storage bucket policies
CREATE POLICY "Users can upload their own files" ON storage.objects
  FOR INSERT WITH CHECK (auth.uid()::text = (storage.foldername(name))[1]);
```

### 3. CDN and Asset Delivery

#### CloudFront Configuration
- **Primary Origin**: Supabase Singapore storage
- **Secondary Origin**: Supabase Japan storage (failover)
- **Edge Locations**: Global including China
- **Caching Strategy**: 
  - Static assets: 1 year TTL
  - User content: 30 days TTL
  - API responses: No cache

#### Lambda@Edge Functions

**Intelligent Routing** (`lambda-edge-intelligent-routing.js`):
- Routes Chinese users to Japan origin for better performance
- Optimizes content delivery based on geographic location
- Handles failover scenarios

**Security Headers** (`lambda-edge-security-headers.js`):
- Adds comprehensive security headers
- Implements CORS policies
- Enforces HTTPS everywhere

### 4. Flutter Application Configuration

#### Environment Management
```dart
// lib/core/config/environment_config.dart
class EnvironmentConfig {
  static AppEnvironmentConfig get config {
    switch (_currentEnvironment) {
      case Environment.production:
        return AppEnvironmentConfig.production();
      case Environment.staging:
        return AppEnvironmentConfig.staging();
      default:
        return AppEnvironmentConfig.development();
    }
  }
}
```

#### Production Features
- Analytics enabled
- Crash reporting via Sentry
- Performance monitoring
- Offline sync capabilities
- Push notifications

### 5. Monitoring and Alerting

#### CloudWatch Alarms
- **High Error Rate**: >5% error rate triggers alert
- **High Latency**: >2 second response time
- **Database Issues**: Connection failures, slow queries
- **Security Events**: WAF blocked requests, unusual traffic

#### Dashboards
- **Application Performance**: Request rates, error rates, response times
- **Infrastructure Health**: CPU, memory, disk usage
- **Security Metrics**: Blocked requests, failed authentications
- **Regional Performance**: China vs global performance comparison

#### Alert Channels
- Email notifications to operations team
- Slack integration for real-time alerts
- SMS alerts for critical issues (optional)

### 6. Backup and Disaster Recovery

#### Backup Strategy
- **Daily Full Backups**: Complete database dump at 2 AM UTC
- **Hourly Incremental**: Transaction log backups
- **Weekly Archives**: Long-term retention (365 days)
- **Cross-Region Replication**: Backups stored in multiple regions

#### Recovery Procedures
```bash
# Initiate disaster recovery
./infrastructure/scripts/disaster-recovery.sh failover

# Restore from specific backup
./infrastructure/scripts/disaster-recovery.sh restore <backup-id>

# Test recovery procedures
./infrastructure/scripts/disaster-recovery.sh test
```

#### Recovery Objectives
- **RTO (Recovery Time Objective)**: 4 hours for critical services
- **RPO (Recovery Point Objective)**: 15 minutes maximum data loss

## Deployment Guide

### Prerequisites

1. **Tools Installation**:
   ```bash
   # AWS CLI
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip && sudo ./aws/install
   
   # Terraform
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip && sudo mv terraform /usr/local/bin/
   
   # Supabase CLI
   npm install -g @supabase/cli
   
   # Flutter
   # Follow instructions at: https://docs.flutter.dev/get-started/install
   ```

2. **Environment Variables**:
   ```bash
   export PROJECT_NAME="whatsapp-clone"
   export ENVIRONMENT="production"
   export AWS_REGION="ap-southeast-1"
   export DOMAIN_NAME="your-production-domain.com"
   export SSL_CERTIFICATE_ARN="arn:aws:acm:us-east-1:123456789012:certificate/your-cert-id"
   export ALERT_EMAIL="alerts@your-company.com"
   export SUPABASE_PRIMARY_PROJECT_REF="your-singapore-project-ref"
   export SUPABASE_DB_PASSWORD="your-secure-password"
   export DATABASE_URL="postgresql://user:password@host:port/database"
   ```

### Deployment Process

#### 1. Full Production Deployment
```bash
# Complete infrastructure deployment
./infrastructure/scripts/deploy-production.sh deploy
```

#### 2. Partial Deployments
```bash
# Infrastructure only
./infrastructure/scripts/deploy-production.sh infrastructure-only

# Monitoring and backup only
./infrastructure/scripts/deploy-production.sh monitoring-only

# Terraform infrastructure only
./infrastructure/scripts/deploy-production.sh terraform-only
```

#### 3. Individual Components
```bash
# Supabase production setup
./infrastructure/scripts/setup-production-supabase.sh

# CDN deployment
./infrastructure/scripts/deploy-cdn.sh

# Monitoring setup
./infrastructure/scripts/setup-monitoring.sh

# Backup configuration
./infrastructure/scripts/setup-backup-recovery.sh
```

### Post-Deployment Verification

1. **Health Checks**:
   ```bash
   # Test database connectivity
   psql "$DATABASE_URL" -c "SELECT 1;"
   
   # Test CDN endpoints
   curl -I "https://cdn.your-domain.com"
   
   # Verify monitoring
   aws cloudwatch describe-alarms --region ap-southeast-1
   ```

2. **Smoke Tests**:
   ```bash
   # Run disaster recovery test
   ./infrastructure/scripts/disaster-recovery.sh test
   
   # Check backup system health
   psql "$DATABASE_URL" -c "SELECT backup.check_backup_health();"
   ```

## Security Hardening

### Database Security
- Row-level security (RLS) enabled on all tables
- Encrypted connections (SSL/TLS)
- Regular security updates
- Access logging and monitoring

### Network Security
- VPC isolation with private subnets
- Security groups with minimal access
- WAF protection against common attacks
- DDoS protection via CloudFront

### Application Security
- HTTPS enforced everywhere
- Security headers via Lambda@Edge
- JWT token validation
- Input sanitization and validation

### Compliance Features
- Data encryption at rest and in transit
- Audit logging for all database operations
- Backup encryption with key rotation
- GDPR compliance for data handling

## Performance Optimization

### China Network Optimization
- CDN edge locations in China
- Intelligent routing via Lambda@Edge
- Japan region as fallback for Chinese users
- Optimized caching strategies

### Mobile Performance
- Asset compression and optimization
- Progressive image loading
- Offline sync capabilities
- Connection pooling

### Database Performance
- Connection pooling with PgBouncer
- Read replicas for scaling
- Query optimization and indexing
- Performance monitoring and alerting

## Troubleshooting Guide

### Common Issues

#### 1. Database Connection Failures
```bash
# Check database health
psql "$DATABASE_URL" -c "SELECT version();"

# View connection pool status
psql "$DATABASE_URL" -c "SELECT * FROM pg_stat_activity;"

# Check Supabase status
curl "https://your-project.supabase.co/rest/v1/health"
```

#### 2. CDN Performance Issues
```bash
# Check CloudFront distribution
aws cloudfront get-distribution --id YOUR_DISTRIBUTION_ID

# View Lambda@Edge logs
aws logs filter-log-events --log-group-name "/aws/lambda/us-east-1.intelligent-routing"

# Test CDN cache
curl -I "https://cdn.your-domain.com/test-file" | grep -i cache
```

#### 3. High Error Rates
```bash
# Check application logs
aws logs filter-log-events --log-group-name "/application/whatsapp-clone/production/app" \
  --filter-pattern "ERROR"

# View CloudWatch metrics
aws cloudwatch get-metric-statistics --namespace "whatsapp-clone/Application" \
  --metric-name "ErrorRate" --start-time 2024-01-01T00:00:00Z --end-time 2024-01-01T23:59:59Z \
  --period 300 --statistics Average
```

### Emergency Procedures

#### 1. Database Failover
```bash
# Switch to secondary database
export DATABASE_URL="$SECONDARY_DATABASE_URL"

# Update DNS or load balancer configuration
# (Manual step - update your DNS provider)

# Verify failover
psql "$DATABASE_URL" -c "SELECT now();"
```

#### 2. Rollback Deployment
```bash
# Switch DNS back to previous environment
# Scale down problematic resources
terraform destroy -target=aws_instance.problematic_instance

# Restore from backup if needed
./infrastructure/scripts/disaster-recovery.sh restore latest
```

## Maintenance and Operations

### Daily Operations
- Monitor CloudWatch dashboards
- Review backup completion status
- Check error rates and performance metrics
- Verify security alerts

### Weekly Operations
- Review and rotate secrets
- Update dependencies
- Performance optimization review
- Security patch assessment

### Monthly Operations
- Disaster recovery drill
- Cost optimization review
- Security audit
- Infrastructure capacity planning

## Support and Documentation

### Key Resources
- **Infrastructure Code**: `/infrastructure` directory
- **Deployment Scripts**: `/infrastructure/scripts`
- **Documentation**: `/infrastructure/docs`
- **Monitoring**: AWS CloudWatch Console
- **Logs**: CloudWatch Logs and Supabase Dashboard

### Emergency Contacts
- **Infrastructure Team**: infrastructure@your-company.com
- **Database Team**: database@your-company.com
- **Security Team**: security@your-company.com
- **On-call Engineer**: See PagerDuty or on-call schedule

### External Resources
- [Supabase Documentation](https://supabase.com/docs)
- [AWS CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [Flutter Production Deployment](https://docs.flutter.dev/deployment)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

*This documentation is maintained as part of the WhatsApp Clone production infrastructure. Last updated: $(date)*