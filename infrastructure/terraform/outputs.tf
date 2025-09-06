# Outputs for WhatsApp Clone Infrastructure

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

# EKS Outputs
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "eks_cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = module.eks.cluster_version
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks.cluster_security_group_id
}

output "eks_node_groups" {
  description = "EKS node groups"
  value       = module.eks.node_groups
}

output "eks_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.eks.oidc_issuer_url
}

# RDS Outputs
output "rds_cluster_id" {
  description = "RDS cluster identifier"
  value       = module.rds.cluster_id
}

output "rds_cluster_endpoint" {
  description = "RDS cluster endpoint"
  value       = module.rds.cluster_endpoint
  sensitive   = true
}

output "rds_cluster_reader_endpoint" {
  description = "RDS cluster reader endpoint"
  value       = module.rds.cluster_reader_endpoint
  sensitive   = true
}

output "rds_cluster_port" {
  description = "RDS cluster port"
  value       = module.rds.cluster_port
}

output "rds_cluster_database_name" {
  description = "RDS cluster database name"
  value       = module.rds.cluster_database_name
}

output "rds_cluster_master_username" {
  description = "RDS cluster master username"
  value       = module.rds.cluster_master_username
  sensitive   = true
}

# Redis Outputs
output "redis_cluster_id" {
  description = "ElastiCache Redis cluster ID"
  value       = module.elasticache.cluster_id
}

output "redis_primary_endpoint" {
  description = "ElastiCache Redis primary endpoint"
  value       = module.elasticache.primary_endpoint
  sensitive   = true
}

output "redis_configuration_endpoint" {
  description = "ElastiCache Redis configuration endpoint"
  value       = module.elasticache.configuration_endpoint
  sensitive   = true
}

# CloudFront Outputs
output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_distribution_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cloudfront.domain_name
}

output "cloudfront_distribution_hosted_zone_id" {
  description = "CloudFront distribution hosted zone ID"
  value       = module.cloudfront.hosted_zone_id
}

# ALB Outputs
output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.alb.dns_name
}

output "alb_zone_id" {
  description = "Application Load Balancer zone ID"
  value       = module.alb.zone_id
}

output "alb_arn" {
  description = "Application Load Balancer ARN"
  value       = module.alb.arn
}

# Route53 Outputs
output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = module.route53.zone_id
}

output "route53_name_servers" {
  description = "Route53 name servers"
  value       = module.route53.name_servers
}

# Security Group Outputs
output "security_group_ids" {
  description = "Security group IDs"
  value = {
    alb_security_group = module.security_groups.alb_security_group_id
    eks_security_group = module.security_groups.eks_security_group_id
    rds_security_group = module.security_groups.rds_security_group_id
    redis_security_group = module.security_groups.redis_security_group_id
  }
}

# Monitoring Outputs
output "monitoring_sns_topic_arn" {
  description = "SNS topic ARN for monitoring alerts"
  value       = module.monitoring.sns_topic_arn
}

output "monitoring_log_groups" {
  description = "CloudWatch log groups"
  value       = module.monitoring.log_groups
}

# Connection Information for Applications
output "database_connection_string" {
  description = "Database connection string (without credentials)"
  value       = "postgresql://${module.rds.cluster_endpoint}:${module.rds.cluster_port}/${module.rds.cluster_database_name}"
  sensitive   = true
}

output "redis_connection_string" {
  description = "Redis connection string"
  value       = "redis://${module.elasticache.primary_endpoint}:6379"
  sensitive   = true
}

# Regional Information
output "region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}

output "account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

# Configuration Summary
output "deployment_summary" {
  description = "Deployment summary information"
  value = {
    project_name         = var.project_name
    environment         = var.environment
    region              = data.aws_region.current.name
    kubernetes_version  = var.kubernetes_version
    domain_name         = var.domain_name
    multi_region_enabled = var.enable_multi_region
    china_optimization  = var.enable_china_optimization
    monitoring_enabled  = var.enable_monitoring
    backup_enabled      = var.enable_backup
  }
}