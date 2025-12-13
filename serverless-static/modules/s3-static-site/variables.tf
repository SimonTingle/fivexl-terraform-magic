variable "bucket_name_prefix" {
  description = "A unique prefix for the S3 bucket name."
  type        = string
}

variable "index_document" {
  description = "The default index document (e.g., index.html)."
  type        = string
  default     = "index.html"
}

variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
}
