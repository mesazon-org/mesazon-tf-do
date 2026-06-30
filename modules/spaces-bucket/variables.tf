variable "environment" {
  description = "Environment name, combined with the raw name and region to build the final bucket name (dev, prod)."
  type        = string
}

variable "region" {
  description = "DigitalOcean Spaces region slug (e.g., fra1)."
  type        = string
}

variable "bucket_name_raw" {
  description = "The raw name for the bucket, which will be combined with the region and environment to create the final name."
  type        = string
}

variable "acl" {
  description = "Canned ACL applied to the bucket (private, public-read)."
  type        = string
  default     = "private"
}

variable "force_destroy" {
  description = "Allow Terraform to destroy the bucket even if it still contains objects."
  type        = bool
  default     = false
}

variable "access_key_permission" {
  description = "Permission granted to the scoped access key (read, readwrite, fullaccess)."
  type        = string
  default     = "readwrite"
}
