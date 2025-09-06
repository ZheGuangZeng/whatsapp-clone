# CloudFront CDN Configuration with China Optimization
# Provides global content delivery with special optimizations for China users

locals {
  # Origins configuration
  origins = {
    primary_app = {
      domain_name = var.primary_alb_dns_name
      origin_id   = "primary-app-origin"
      custom_origin_config = {
        http_port                = 80
        https_port               = 443
        origin_protocol_policy   = "https-only"
        origin_ssl_protocols     = ["TLSv1.2"]
        origin_keepalive_timeout = 60
        origin_read_timeout      = 60
      }
    }
    secondary_app = {
      domain_name = var.secondary_alb_dns_name
      origin_id   = "secondary-app-origin"
      custom_origin_config = {
        http_port                = 80
        https_port               = 443
        origin_protocol_policy   = "https-only"
        origin_ssl_protocols     = ["TLSv1.2"]
        origin_keepalive_timeout = 60
        origin_read_timeout      = 60
      }
    }
    supabase_storage_sg = {
      domain_name = "${var.singapore_supabase_project_ref}.supabase.co"
      origin_id   = "supabase-storage-sg"
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
    supabase_storage_jp = {
      domain_name = "${var.japan_supabase_project_ref}.supabase.co"
      origin_id   = "supabase-storage-jp"
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  # Geo-location based origin selection
  china_optimized_behavior = {
    target_origin_id       = "secondary-app-origin"  # Japan closer to China
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    
    # Optimized caching for China users
    default_ttl = 300     # 5 minutes for dynamic content
    max_ttl     = 86400   # 1 day for static content
    min_ttl     = 0
    
    forwarded_values = {
      query_string = true
      headers      = ["Authorization", "CloudFront-Forwarded-Proto", "Host"]
      cookies = {
        forward = "none"
      }
    }
  }
}

# Main CloudFront distribution
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "WhatsApp Clone CDN with China optimization"
  
  # Use all edge locations including China
  price_class = "PriceClass_All"
  
  # Origins
  dynamic "origin" {
    for_each = local.origins
    content {
      domain_name = origin.value.domain_name
      origin_id   = origin.value.origin_id
      
      dynamic "custom_origin_config" {
        for_each = origin.value.custom_origin_config != null ? [origin.value.custom_origin_config] : []
        content {
          http_port                = custom_origin_config.value.http_port
          https_port               = custom_origin_config.value.https_port
          origin_protocol_policy   = custom_origin_config.value.origin_protocol_policy
          origin_ssl_protocols     = custom_origin_config.value.origin_ssl_protocols
          origin_keepalive_timeout = lookup(custom_origin_config.value, "origin_keepalive_timeout", 5)
          origin_read_timeout      = lookup(custom_origin_config.value, "origin_read_timeout", 30)
        }
      }
      
      # Custom headers for origin identification
      custom_header {
        name  = "CloudFront-Region"
        value = var.aws_region
      }
      
      custom_header {
        name  = "X-Forwarded-Proto"
        value = "https"
      }
    }
  }
  
  # Default cache behavior (Global users)
  default_cache_behavior {
    target_origin_id       = "primary-app-origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]
    
    # TTL settings for Flutter web app
    default_ttl = 86400   # 1 day
    max_ttl     = 31536000 # 1 year
    min_ttl     = 0
    
    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Accept-Language", "CloudFront-Forwarded-Proto"]
      
      cookies {
        forward = "none"
      }
    }
    
    # Lambda@Edge function for intelligent routing
    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = aws_lambda_function.intelligent_routing.qualified_arn
      include_body = false
    }
    
    # Response headers security
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
  }
  
  # API endpoints cache behavior
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    target_origin_id = "primary-app-origin"
    
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]
    
    # Short TTL for API responses
    default_ttl = 0
    max_ttl     = 300  # 5 minutes max
    min_ttl     = 0
    
    forwarded_values {
      query_string = true
      headers      = ["*"]
      
      cookies {
        forward = "all"
      }
    }
  }
  
  # Static assets cache behavior (Flutter JS, CSS, etc.)
  ordered_cache_behavior {
    path_pattern     = "/flutter*"
    target_origin_id = "primary-app-origin"
    
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    
    # Long TTL for static Flutter assets
    default_ttl = 31536000  # 1 year
    max_ttl     = 31536000  # 1 year
    min_ttl     = 86400     # 1 day minimum
    
    forwarded_values {
      query_string = false
      
      cookies {
        forward = "none"
      }
    }
  }
  
  # Supabase Storage behavior (Singapore)
  ordered_cache_behavior {
    path_pattern     = "/storage/sg/*"
    target_origin_id = "supabase-storage-sg"
    
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    
    default_ttl = 86400   # 1 day for media files
    max_ttl     = 604800  # 1 week
    min_ttl     = 3600    # 1 hour
    
    forwarded_values {
      query_string = false
      headers      = ["Authorization"]
      
      cookies {
        forward = "none"
      }
    }
  }
  
  # Supabase Storage behavior (Japan - for China users)
  ordered_cache_behavior {
    path_pattern     = "/storage/jp/*"
    target_origin_id = "supabase-storage-jp"
    
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    
    default_ttl = 86400
    max_ttl     = 604800
    min_ttl     = 3600
    
    forwarded_values {
      query_string = false
      headers      = ["Authorization"]
      
      cookies {
        forward = "none"
      }
    }
  }
  
  # Geographic restrictions (None - serve globally including China)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  # SSL Certificate
  viewer_certificate {
    acm_certificate_arn      = var.ssl_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  
  # Custom error responses
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
    error_caching_min_ttl = 300
  }
  
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
    error_caching_min_ttl = 300
  }
  
  # Aliases (domain names)
  aliases = [
    var.domain_name,
    "www.${var.domain_name}",
    "cdn.${var.domain_name}"
  ]
  
  tags = var.tags
}

# Response headers policy for security
resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "${var.project_name}-security-headers"
  
  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
    }
    
    content_type_options {
      override = true
    }
    
    frame_options {
      frame_option = "SAMEORIGIN"
      override     = true
    }
    
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }
  
  custom_headers_config {
    items {
      header   = "X-XSS-Protection"
      value    = "1; mode=block"
      override = true
    }
    
    items {
      header   = "Permissions-Policy"
      value    = "accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()"
      override = true
    }
  }
}

# Lambda@Edge function for intelligent routing based on geography
resource "aws_lambda_function" "intelligent_routing" {
  filename         = "intelligent_routing.zip"
  function_name    = "${var.project_name}-intelligent-routing"
  role            = aws_iam_role.lambda_edge_role.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "nodejs18.x"
  timeout         = 5
  
  # Must be published for Lambda@Edge
  publish = true
  
  tags = var.tags
}

# Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "intelligent_routing.zip"
  source {
    content = templatefile("${path.module}/lambda/intelligent_routing.js", {
      secondary_origin_id = "secondary-app-origin"
      primary_origin_id   = "primary-app-origin"
    })
    filename = "index.js"
  }
}

# IAM role for Lambda@Edge
resource "aws_iam_role" "lambda_edge_role" {
  name = "${var.project_name}-lambda-edge-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "edgelambda.amazonaws.com"
          ]
        }
      }
    ]
  })
  
  tags = var.tags
}

# IAM policy for Lambda@Edge
resource "aws_iam_role_policy_attachment" "lambda_edge_policy" {
  role       = aws_iam_role.lambda_edge_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Origin Access Control for S3 integration (if needed)
resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "${var.project_name}-oac"
  description                       = "Origin Access Control for WhatsApp Clone"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Variables for the module
variable "project_name" {
  description = "Project name"
  type        = string
}

variable "domain_name" {
  description = "Primary domain name"
  type        = string
}

variable "ssl_certificate_arn" {
  description = "SSL certificate ARN"
  type        = string
}

variable "primary_alb_dns_name" {
  description = "Primary ALB DNS name"
  type        = string
}

variable "secondary_alb_dns_name" {
  description = "Secondary ALB DNS name"
  type        = string
}

variable "singapore_supabase_project_ref" {
  description = "Singapore Supabase project reference"
  type        = string
}

variable "japan_supabase_project_ref" {
  description = "Japan Supabase project reference"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

# Outputs
output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.main.id
}

output "domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "hosted_zone_id" {
  description = "CloudFront hosted zone ID for Route53"
  value       = aws_cloudfront_distribution.main.hosted_zone_id
}