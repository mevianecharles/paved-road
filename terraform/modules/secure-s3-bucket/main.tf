variable "bucket_name" {
  description = "Base name for the bucket (will be combined with environment and account ID for global uniqueness)"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

data "aws_caller_identity" "current" {}

locals {
  full_bucket_name = "${var.bucket_name}-${var.environment}-${data.aws_caller_identity.current.account_id}"
}

# The paved road: every team gets this, nobody configures a bucket by hand
resource "aws_s3_bucket" "this" {
  bucket = local.full_bucket_name

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "secure-s3-bucket"
  }
}

# Encryption at rest — always on, no opt-out
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block all public access — always on, no opt-out
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning — protects against accidental deletion/overwrite
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Access logging — every access is recorded for audit
resource "aws_s3_bucket_logging" "this" {
  bucket = aws_s3_bucket.this.id

  target_bucket = aws_s3_bucket.this.id
  target_prefix = "access-logs/"
}

# Lifecycle rule — old versions cleaned up automatically, controls cost
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

output "bucket_id" {
  value = aws_s3_bucket.this.id
}

output "bucket_arn" {
  value = aws_s3_bucket.this.arn
}
