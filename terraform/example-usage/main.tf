# This is what a developer writes — that's it. No security expertise required.
# They just call the module, and encryption, public-access-block, versioning,
# logging, and least-privilege IAM are all handled for them automatically.

module "app_uploads_bucket" {
  source      = "../modules/secure-s3-bucket"
  bucket_name = "app-uploads"
  environment = "dev"
}

module "app_role" {
  source          = "../modules/least-privilege-iam"
  role_name       = "app-uploads-role"
  trusted_service = "ec2.amazonaws.com"

  # Explicitly scoped — only this one bucket, nothing broader
  allowed_s3_bucket_arns = [module.app_uploads_bucket.bucket_arn]
}

terraform {
  backend "s3" {
    bucket = "amzn-s3-tfstate-file-277140629239-eu-north-1-an"
    key    = "satcorporation-paved-road/terraform/example-usage/terraform.tfstate"
    region = "eu-north-1"
  }
}