# Variables for WhatsApp Clone Infrastructure

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "whatsapp-clone"
}

variable "environment" {
  description = "Environment (development, staging, production)"
  type        = string
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
}

# EKS Configuration
variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "eks_node_groups" {
  description = "EKS node groups configuration"
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
    disk_size      = number
    desired_size   = number
    max_size       = number
    min_size       = number
    labels         = map(string)
    taints         = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
  
  default = {
    web = {
      instance_types = ["m5.large"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 50
      desired_size   = 3
      max_size       = 100
      min_size       = 2
      labels = {
        role = "web"
      }
      taints = []
    }
    compute = {
      instance_types = ["c5.xlarge"]
      capacity_type  = "SPOT"
      disk_size      = 100
      desired_size   = 2
      max_size       = 50
      min_size       = 1
      labels = {
        role = "compute"
      }
      taints = []
    }
  }
}

# RDS Configuration
variable "database_name" {
  description = "Name of the database"
  type        = string
  default     = "whatsappclone"
}

variable "database_username" {
  description = "Username for database"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.r6g.large"
}

variable "rds_instance_count" {
  description = "Number of RDS instances"
  type        = number
  default     = 2
}

# Redis Configuration
variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.r6g.large"
}

variable "redis_num_nodes" {
  description = "Number of Redis cache nodes"
  type        = number
  default     = 3
}

# Domain Configuration
variable "domain_name" {
  description = "Primary domain name"
  type        = string
  default     = "whatsappclone.com"
}

variable "primary_domain" {
  description = "Primary ALB domain"
  type        = string
  default     = "sg.whatsappclone.com"
}

variable "secondary_domain" {
  description = "Secondary ALB domain"
  type        = string
  default     = "jp.whatsappclone.com"
}

variable "ssl_certificate_arn" {
  description = "SSL certificate ARN for ALB"
  type        = string
  default     = ""
}

# Feature Flags
variable "enable_china_optimization" {
  description = "Enable China network optimization"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable comprehensive monitoring"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable automated backup"
  type        = bool
  default     = true
}

# Cost Optimization
variable "use_spot_instances" {
  description = "Use spot instances for cost optimization"
  type        = bool
  default     = false
}

variable "auto_scaling_enabled" {
  description = "Enable auto-scaling"
  type        = bool
  default     = true
}

# Multi-region Configuration
variable "enable_multi_region" {
  description = "Enable multi-region deployment"
  type        = bool
  default     = true
}

variable "secondary_region" {
  description = "Secondary AWS region for disaster recovery"
  type        = string
  default     = "ap-northeast-1"
}

# Monitoring Configuration
variable "enable_performance_insights" {
  description = "Enable RDS Performance Insights"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# Security Configuration
variable "enable_waf" {
  description = "Enable AWS WAF for security"
  type        = bool
  default     = true
}

variable "enable_shield" {
  description = "Enable AWS Shield Advanced"
  type        = bool
  default     = false
}

# Backup Configuration
variable "backup_retention_days" {
  description = "Database backup retention in days"
  type        = number
  default     = 7
}

variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery for RDS"
  type        = bool
  default     = true
}