variable "role_name" {
  description = "Name for the IAM role"
  type        = string
}

variable "trusted_service" {
  description = "AWS service that can assume this role (e.g. ec2.amazonaws.com, lambda.amazonaws.com)"
  type        = string
}

variable "allowed_s3_bucket_arns" {
  description = "List of S3 bucket ARNs this role is allowed to access (empty = no S3 access)"
  type        = list(string)
  default     = []
}

# The paved road: a role that starts with ZERO permissions.
# Teams explicitly grant only what they need via variables, nothing is broad by default.
resource "aws_iam_role" "this" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = var.trusted_service
        }
      }
    ]
  })

  tags = {
    ManagedBy = "Terraform"
    Module    = "least-privilege-iam"
  }
}

# Only attached if the team actually requested S3 access — least privilege by design
resource "aws_iam_role_policy" "s3_access" {
  count = length(var.allowed_s3_bucket_arns) > 0 ? 1 : 0

  name = "${var.role_name}-s3-access"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        # Scoped to exact buckets only — never "Resource": "*"
        Resource = [for arn in var.allowed_s3_bucket_arns : "${arn}/*"]
      }
    ]
  })
}

output "role_arn" {
  value = aws_iam_role.this.arn
}

output "role_name" {
  value = aws_iam_role.this.name
}
