# File: serverless-static/modules/s3-static-site/outputs.tf

output "website_url" {
  description = "The CloudFront Distribution Domain Name (the public URL)"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}
