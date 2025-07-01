provider "aws" {
  region = var.aws_region
}

resource "random_id" "ct_bucket_id" {
  byte_length = 4
}

# ----------------------------------------
# Redshift Logging Bucket
# ----------------------------------------
resource "aws_s3_bucket" "redshift_logs" {
  bucket = var.log_bucket_name
}

resource "aws_s3_bucket_public_access_block" "redshift_logs_block" {
  bucket = aws_s3_bucket.redshift_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "redshift_logs_versioning" {
  bucket = aws_s3_bucket.redshift_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ----------------------------------------
# CloudTrail Logging Bucket
# ----------------------------------------
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "cloudtrail-logs-${random_id.ct_bucket_id.hex}"
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs_block" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs_versioning" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ----------------------------------------
# AWS Account ID
# ----------------------------------------
data "aws_caller_identity" "current" {}

# ----------------------------------------
# CloudTrail Bucket Policy (FIXED)
# ----------------------------------------
resource "aws_s3_bucket_policy" "cloudtrail_logs_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action   = "s3:GetBucketAcl",
        Resource = "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs.id}"
      },
      {
        Sid    = "AWSCloudTrailWrite",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs.id}/AWSLogs/066342034198/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# ----------------------------------------
# CloudTrail (FIXED)
# ----------------------------------------
resource "aws_cloudtrail" "this" {
  name                          = "redshift-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail_logs_policy]
}

# ----------------------------------------
# VPC using AWS VPC Module
# ----------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "redshift-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_dns_support   = true
  enable_dns_hostnames = true
}

# ----------------------------------------
# Redshift Cluster Module
# ----------------------------------------
module "redshift" {
  source = "./modules/redshift"

  cluster_identifier = "my-redshift-cluster"
  node_type          = "ra3.xlplus"
  number_of_nodes    = 2
  database_name      = "mydb"
  master_username    = "admin"
  master_password    = var.master_password

  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  allowed_ips     = ["18.233.156.9/32"]
  log_bucket_name = var.log_bucket_name
}

