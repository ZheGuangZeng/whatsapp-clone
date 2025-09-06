# WhatsApp Clone Infrastructure & Deployment Guide

## Overview

This deployment guide provides comprehensive instructions for deploying the WhatsApp Clone infrastructure across multiple regions with China network optimization, monitoring, and disaster recovery capabilities.

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                        Global CDN (CloudFront)                  │
│                     China-Optimized Routing                     │
└─────────────────────┬───────────────────────────────────────────┘
                      │
          ┌───────────┴───────────┐
          │                       │
┌─────────▼─────────┐    ┌─────────▼─────────┐
│   Singapore       │    │     Japan         │
│   (Primary)       │    │  (Secondary)      │
│                   │    │                   │
│ ┌───────────────┐ │    │ ┌───────────────┐ │
│ │ EKS Cluster   │ │    │ │ EKS Cluster   │ │
│ │ (10-200 pods) │ │    │ │ (3-100 pods)  │ │
│ └───────────────┘ │    │ └───────────────┘ │
│                   │    │                   │
│ ┌───────────────┐ │    │ ┌───────────────┐ │
│ │ Supabase      │ │    │ │ Supabase      │ │
│ │ (Primary)     │◄├────┤►│ (Replica)     │ │
│ └───────────────┘ │    │ └───────────────┘ │
└───────────────────┘    └───────────────────┘
```

## Prerequisites

### Required Tools
- [Docker](https://docs.docker.com/get-docker/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) >= 1.5
- [Supabase CLI](https://supabase.com/docs/guides/cli)
- [Flutter](https://flutter.dev/docs/get-started/install) >= 3.24.0

### AWS Account Setup
- AWS Account with appropriate permissions
- Domain registered in Route53
- SSL certificate in ACM (us-east-1 for CloudFront)
- IAM roles for EKS, Lambda@Edge, and other services

### Supabase Setup
- Supabase organization account
- Projects created in Singapore and Japan regions
- Database schemas synchronized between regions

## Deployment Steps

### 1. Environment Configuration

Create environment-specific configuration files:

```bash
# Copy example configurations
cp infrastructure/kubernetes/overlays/production/production.env.example \
   infrastructure/kubernetes/overlays/production/production.env

# Update with your actual values
vim infrastructure/kubernetes/overlays/production/production.env
```

Required environment variables:
```bash
# Supabase Configuration
SUPABASE_URL=https://your-singapore-project.supabase.co
SUPABASE_ANON_KEY=your-singapore-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-singapore-service-role-key

# Japan Supabase (for failover)
SUPABASE_URL_JAPAN=https://your-japan-project.supabase.co
SUPABASE_ANON_KEY_JAPAN=your-japan-anon-key

# LiveKit Configuration
LIVEKIT_URL=wss://whatsappclone.livekit.cloud
LIVEKIT_API_KEY=your-production-livekit-api-key
LIVEKIT_API_SECRET=your-production-livekit-api-secret

# Monitoring
SENTRY_DSN=https://your-sentry-dsn@sentry.io/project-id

# Domain and SSL
DOMAIN_NAME=whatsappclone.com
SSL_CERTIFICATE_ARN=arn:aws:acm:us-east-1:account:certificate/cert-id
```

### 2. Infrastructure Deployment (Terraform)

Deploy the core infrastructure:

```bash
cd infrastructure/terraform

# Initialize Terraform
terraform init

# Plan deployment
terraform plan \
  -var="project_name=whatsapp-clone" \
  -var="environment=production" \
  -var="domain_name=whatsappclone.com" \
  -var="ssl_certificate_arn=arn:aws:acm:us-east-1:account:certificate/cert-id"

# Apply infrastructure
terraform apply
```

This creates:
- EKS clusters in Singapore and Japan
- RDS Aurora PostgreSQL cluster
- ElastiCache Redis cluster
- Application Load Balancers
- CloudFront distribution with China optimization
- Route53 DNS configuration
- VPC, subnets, security groups
- IAM roles and policies

### 3. Kubernetes Application Deployment

Deploy the WhatsApp Clone application:

```bash
# Update kubeconfig for Singapore cluster
aws eks update-kubeconfig \
  --region ap-southeast-1 \
  --name whatsapp-clone-production-sg

# Deploy to Singapore (Primary)
cd infrastructure/kubernetes/overlays/production
kustomize build . | kubectl apply -f -

# Verify deployment
kubectl rollout status deployment/whatsapp-clone-web -n whatsapp-clone-prod
kubectl get pods -n whatsapp-clone-prod

# Update kubeconfig for Japan cluster  
aws eks update-kubeconfig \
  --region ap-northeast-1 \
  --name whatsapp-clone-production-jp

# Deploy to Japan (Secondary)
kustomize build . | kubectl apply -f -
kubectl rollout status deployment/whatsapp-clone-web -n whatsapp-clone-prod
```

### 4. Monitoring Setup

Deploy monitoring stack:

```bash
# Create monitoring namespace
kubectl create namespace monitoring

# Deploy Prometheus
kubectl apply -f infrastructure/monitoring/prometheus-config.yaml

# Import Grafana dashboard
# Use the JSON in infrastructure/monitoring/grafana-dashboard.json
```

### 5. Database Setup and Migration

Set up Supabase databases:

```bash
# Singapore (Primary)
supabase link --project-ref YOUR_SINGAPORE_PROJECT_REF
supabase db push

# Japan (Secondary)  
supabase link --project-ref YOUR_JAPAN_PROJECT_REF
supabase db push

# Set up replication (manual process)
# Follow instructions in infrastructure/supabase/multi-region-setup.md
```

### 6. CDN and DNS Configuration

The CloudFront distribution is automatically configured via Terraform. Verify:

```bash
# Check CloudFront distribution
aws cloudfront list-distributions --query 'DistributionList.Items[?Comment==`WhatsApp Clone CDN with China optimization`]'

# Test DNS resolution
dig whatsappclone.com
dig www.whatsappclone.com
```

### 7. Load Testing

Run performance validation:

```bash
cd infrastructure/testing

# Install dependencies
npm install

# Run smoke test
npm run test:smoke

# Run load test
npm run test:load

# Run China network simulation
npm run test:china
```

## Monitoring & Observability

### Metrics and Dashboards

Access monitoring interfaces:
- **Grafana**: `https://monitoring.whatsappclone.com`
- **Prometheus**: `https://prometheus.whatsappclone.com`  
- **Supabase Dashboard**: Singapore & Japan project dashboards

### Key Metrics to Monitor

1. **Application Performance**
   - Request rate (target: >1000 req/sec)
   - Response time p95 (target: <2s)
   - Error rate (target: <5%)

2. **Infrastructure Health**
   - Pod CPU/Memory utilization
   - Database connection pool usage
   - Cache hit rates

3. **User Experience**
   - Message delivery latency
   - Meeting join time
   - File upload/download speeds

### Alerting

Alerts are configured for:
- High error rates (>5%)
- Slow response times (p95 >2s)
- Pod restarts
- Database connection issues
- Service outages

Notifications sent via:
- SNS topic: `whatsapp-clone-alerts`
- Slack webhook (configure in SNS)
- Email notifications

## Disaster Recovery

### Automatic Failover

The disaster recovery system monitors primary region health:

```bash
# Start monitoring daemon
./infrastructure/scripts/disaster-recovery.sh monitor

# Manual failover (if needed)
./infrastructure/scripts/disaster-recovery.sh failover

# Manual failback (when primary is healthy)
./infrastructure/scripts/disaster-recovery.sh failback
```

### Backup Procedures

Automated daily backups:

```bash
# Set up backup cron job
crontab -e

# Add daily backup at 2 AM
0 2 * * * /path/to/infrastructure/scripts/backup-database.sh
```

Backups are:
- Encrypted with GPG
- Stored in S3 with cross-region replication
- Retained for 30 days
- Validated for integrity

### Recovery Testing

Monthly recovery tests:
1. Simulate primary region failure
2. Verify automatic failover
3. Test application functionality
4. Measure recovery time (target: <30 minutes)
5. Document any issues

## Performance Optimization

### China Network Optimization

Special optimizations for Chinese users:
- **CDN Edge Locations**: All global locations including China
- **Intelligent Routing**: Lambda@Edge routes China traffic to Japan
- **Compressed Responses**: Gzip/Brotli compression enabled
- **Optimized Caching**: Longer TTL for static assets
- **Connection Persistence**: Keep-alive enabled

### Auto-scaling Configuration

- **Minimum replicas**: 10 (production)
- **Maximum replicas**: 200 (production)  
- **Scale-up triggers**: CPU >70%, Memory >80%
- **Scale-down**: Gradual with 5-minute stabilization

### Database Optimization

- **Connection pooling**: PgBouncer configuration
- **Read replicas**: Japan instance for read queries
- **Performance insights**: Enabled for query optimization
- **Automated backups**: Daily with point-in-time recovery

## Security

### Network Security
- VPC with private subnets for databases
- Security groups with minimal required ports
- WAF rules for common attacks
- DDoS protection with CloudFront

### Application Security
- Row-level security (RLS) in Supabase
- JWT token authentication
- HTTPS everywhere with TLS 1.2+
- Security headers via CloudFront

### Data Protection
- Encrypted backups
- Encryption at rest (RDS, S3)
- Encryption in transit (TLS)
- Secure secrets management (Kubernetes secrets)

## Cost Optimization

### Resource Sizing
- **Production**: Optimized for performance and reliability
- **Staging**: Scaled-down versions for testing
- **Development**: Minimal resources for development

### Spot Instances
- Used for non-critical workloads
- Compute-heavy tasks (image processing)
- Development environments

### Auto-scaling Benefits
- Scale down during low usage
- Scale up during peak times
- Cost savings of 40-60% vs fixed capacity

## Troubleshooting

### Common Issues

1. **Pod startup failures**
   ```bash
   kubectl describe pod <pod-name> -n whatsapp-clone-prod
   kubectl logs <pod-name> -n whatsapp-clone-prod
   ```

2. **Database connection issues**
   ```bash
   # Check database status
   aws rds describe-db-clusters --db-cluster-identifier whatsapp-clone-production
   
   # Test connection
   psql -h db.your-project.supabase.co -U postgres -d postgres
   ```

3. **CDN cache issues**
   ```bash
   # Invalidate CloudFront cache
   aws cloudfront create-invalidation \
     --distribution-id E1234567890123 \
     --paths "/*"
   ```

4. **High latency from China**
   ```bash
   # Check Lambda@Edge logs
   aws logs filter-log-events \
     --log-group-name /aws/lambda/us-east-1.whatsapp-clone-intelligent-routing
   ```

### Health Check Commands

```bash
# Application health
curl -s https://whatsappclone.com/health

# Database health
supabase status --project-ref YOUR_PROJECT_REF

# Kubernetes health
kubectl get nodes
kubectl get pods --all-namespaces
kubectl top nodes
kubectl top pods -n whatsapp-clone-prod
```

## Maintenance

### Regular Tasks

**Weekly:**
- Review monitoring dashboards
- Check error rates and performance
- Validate backup completion
- Review security logs

**Monthly:**
- Update dependencies
- Run disaster recovery test
- Review cost optimization opportunities
- Security patches

**Quarterly:**
- Load testing with increased traffic
- Disaster recovery full test
- Infrastructure review and optimization
- Security audit

## Support and Documentation

- **Runbooks**: `/infrastructure/runbooks/`
- **Architecture Docs**: `/docs/architecture/`
- **API Documentation**: Generated from OpenAPI specs
- **Monitoring Guides**: Grafana dashboard documentation

For issues and support:
1. Check monitoring dashboards first
2. Review relevant runbooks
3. Check application logs
4. Escalate to on-call engineer if needed

---

**Deployment completed successfully!** 🎉

The WhatsApp Clone is now running with:
- Multi-region high availability
- China-optimized performance  
- Comprehensive monitoring
- Automated disaster recovery
- Production-grade security
- 99.5% uptime SLA capability

Monitor the application at: https://whatsappclone.com