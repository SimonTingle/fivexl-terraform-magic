# File: serverless-static/modules/s3-static-site/main.tf

# 1. S3 Bucket for Content
resource "aws_s3_bucket" "content" {
  # Bucket name must be unique globally, using prefix passed from environment
  bucket = "${var.bucket_name_prefix}-content"

  # Enforce encryption at rest (Good Security Practice)
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = var.tags
}

# Enable S3 bucket versioning (Crucial for state recovery and content history)
resource "aws_s3_bucket_versioning" "content" {
  bucket = aws_s3_bucket.content.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 2. Origin Access Control (OAC) for secure connection between CloudFront and S3
# This makes the S3 bucket private, forcing access through CloudFront (Secure Design)
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.bucket_name_prefix}-oac"
  description                       = "OAC for static website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 3. CloudFront Distribution (The Static Endpoint - DNS name stays the same)
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.content.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.content.id
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN for ${var.bucket_name_prefix} static website"
  default_root_object = var.index_document # Passed from the environment variable

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.content.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # TLS is optional, so we use the default CloudFront certificate
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = var.tags
}

# 4. S3 Bucket Policy to allow ONLY CloudFront OAC access (Security)
resource "aws_s3_bucket_policy" "content" {
  bucket = aws_s3_bucket.content.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

# Data source for the S3 Policy document (Restricts access to OAC only)
data "aws_iam_policy_document" "s3_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.content.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}
