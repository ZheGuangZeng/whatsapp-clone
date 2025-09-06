# WhatsApp Clone Multi-Region Infrastructure
# Terraform configuration for AWS EKS, RDS, ElastiCache, and CloudFront

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
  }

  backend "s3" {
    # Configure this for your environment
    bucket = "whatsapp-clone-terraform-state"
    key    = "infrastructure/terraform.tfstate"
    region = "ap-southeast-1"
    
    # State locking
    dynamodb_table = "whatsapp-clone-terraform-locks"
    encrypt        = true
  }
}

# Local variables
locals {
  project_name = var.project_name
  environment  = var.environment
  region       = var.region
  
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    Region      = local.region
    ManagedBy   = "terraform"
    Owner       = "whatsapp-clone-team"
    CostCenter  = "engineering"
  }

  # Multi-region configuration
  regions = {
    primary = {
      region = "ap-southeast-1" # Singapore
      az_count = 3
    }
    secondary = {
      region = "ap-northeast-1" # Japan
      az_count = 3
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Configuration
module "vpc" {
  source = "./modules/vpc"
  
  project_name = local.project_name
  environment  = local.environment
  region       = local.region
  
  cidr_block           = var.vpc_cidr
  availability_zones   = data.aws_availability_zones.available.names
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  
  enable_nat_gateway = true
  enable_vpn_gateway = false
  
  tags = local.common_tags
}

# EKS Cluster
module "eks" {
  source = "./modules/eks"
  
  project_name = local.project_name
  environment  = local.environment
  
  cluster_name    = "${local.project_name}-${local.environment}"
  cluster_version = var.kubernetes_version
  
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  
  node_groups = var.eks_node_groups
  
  # OIDC Provider for IRSA
  enable_irsa = true
  
  tags = local.common_tags
}

# RDS Aurora PostgreSQL for Supabase-compatible database
module "rds" {
  source = "./modules/rds"
  
  project_name = local.project_name
  environment  = local.environment
  
  engine         = "aurora-postgresql"
  engine_version = "15.4"
  
  cluster_identifier = "${local.project_name}-${local.environment}"
  database_name      = var.database_name
  master_username    = var.database_username
  
  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.db_subnet_group_name
  
  instance_class = var.rds_instance_class
  instance_count = var.rds_instance_count
  
  backup_retention_period = 7
  preferred_backup_window = "03:00-04:00"
  
  # Multi-AZ for high availability
  multi_az = true
  
  # Performance Insights
  performance_insights_enabled = true
  
  tags = local.common_tags
}

# ElastiCache Redis for session management and caching
module "elasticache" {
  source = "./modules/elasticache"
  
  project_name = local.project_name
  environment  = local.environment
  
  cluster_id = "${local.project_name}-${local.environment}-redis"
  
  node_type           = var.redis_node_type
  num_cache_nodes     = var.redis_num_nodes
  parameter_group     = "default.redis7"
  port               = 6379
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  # Backup configuration
  snapshot_retention_limit = 3
  snapshot_window          = "03:00-05:00"
  
  tags = local.common_tags
}

# CloudFront CDN for global content delivery
module "cloudfront" {
  source = "./modules/cloudfront"
  
  project_name = local.project_name
  environment  = local.environment
  
  # Origins configuration
  origins = {
    primary = {
      domain_name = var.primary_domain
      origin_id   = "primary-alb"
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
    secondary = {
      domain_name = var.secondary_domain
      origin_id   = "secondary-alb"
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }
  
  # China-optimized edge locations
  price_class = "PriceClass_All"
  
  # Caching behavior for Flutter web app
  default_cache_behavior = {
    target_origin_id       = "primary-alb"
    viewer_protocol_policy = "redirect-to-https"
    compress              = true
    
    cached_methods = ["GET", "HEAD"]
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    
    # TTL settings for static assets
    default_ttl = 86400  # 1 day
    max_ttl     = 31536000  # 1 year
    min_ttl     = 0
  }
  
  tags = local.common_tags
}

# Route53 DNS for multi-region routing
module "route53" {
  source = "./modules/route53"
  
  project_name = local.project_name
  environment  = local.environment
  
  domain_name = var.domain_name
  
  # Health checks for automatic failover
  health_checks = {
    primary = {
      fqdn = var.primary_domain
      port = 443
      type = "HTTPS"
      path = "/health"
    }
    secondary = {
      fqdn = var.secondary_domain
      port = 443
      type = "HTTPS"
      path = "/health"
    }
  }
  
  # Geolocation routing for China optimization
  records = {
    primary = {
      name = var.domain_name
      type = "A"
      alias = {
        name    = module.cloudfront.domain_name
        zone_id = module.cloudfront.hosted_zone_id
      }
      set_identifier = "primary"
      geolocation_routing_policy = {
        continent = "AS"
      }
    }
    china = {
      name = var.domain_name
      type = "A"
      alias = {
        name    = module.cloudfront.domain_name
        zone_id = module.cloudfront.hosted_zone_id
      }
      set_identifier = "china"
      geolocation_routing_policy = {
        country = "CN"
      }
    }
  }
  
  tags = local.common_tags
}

# Application Load Balancer
module "alb" {
  source = "./modules/alb"
  
  project_name = local.project_name
  environment  = local.environment
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids
  
  # SSL certificate
  certificate_arn = var.ssl_certificate_arn
  
  # Security groups
  security_group_ids = [module.security_groups.alb_security_group_id]
  
  # Target groups for EKS
  target_groups = {
    web = {
      name     = "${local.project_name}-${local.environment}-web"
      port     = 80
      protocol = "HTTP"
      health_check = {
        path    = "/health"
        matcher = "200"
      }
    }
  }
  
  tags = local.common_tags
}

# Security Groups
module "security_groups" {
  source = "./modules/security-groups"
  
  project_name = local.project_name
  environment  = local.environment
  
  vpc_id = module.vpc.vpc_id
  
  tags = local.common_tags
}

# Monitoring and Logging
module "monitoring" {
  source = "./modules/monitoring"
  
  project_name = local.project_name
  environment  = local.environment
  
  eks_cluster_name = module.eks.cluster_name
  rds_cluster_id   = module.rds.cluster_id
  
  # CloudWatch Log Groups
  log_groups = [
    "/aws/eks/${module.eks.cluster_name}/cluster",
    "/aws/rds/cluster/${module.rds.cluster_id}/error",
    "/aws/rds/cluster/${module.rds.cluster_id}/general",
    "/aws/rds/cluster/${module.rds.cluster_id}/slowquery"
  ]
  
  # SNS Topic for alerts
  sns_topic_name = "${local.project_name}-${local.environment}-alerts"
  
  tags = local.common_tags
}