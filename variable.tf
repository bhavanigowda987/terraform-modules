variable "aws_region" {
  default = "us-east-1"
}

variable "master_password" {
  description = "Redshift master password"
  type        = string
  sensitive   = true
}

variable "log_bucket_name" {
  description = "S3 bucket name for Redshift logs"
  type        = string
}

