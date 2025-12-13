output "website_url" {
  description = "The public URL of the Dev Static Website (via CloudFront)"
  value       = module.static_website.website_url
}
