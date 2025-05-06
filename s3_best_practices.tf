
# Variables (to be defined in variables.tf or tfvars file)
# variable "upload_bucket" {}
# variable "download_bucket" {}
# variable "app_data_bucket" {}
# variable "logging_bucket" {}
# variable "s3_access_role" {}
# variable "s3_policy" {}

locals {
  buckets = {
    upload   = var.upload_bucket
    download = var.download_bucket
    app_data = var.app_data_bucket
  }
}

# Create S3 Buckets with Best Practices
resource "aws_s3_bucket" "buckets" {
  for_each      = local.buckets
  bucket        = each.value
  force_destroy = false

  tags = {
    Environment = "production"
    Owner       = "devops-team"
    Project     = "my-app"
  }
}

# Enable Versioning
resource "aws_s3_bucket_versioning" "versioning" {
  for_each = aws_s3_bucket.buckets

  bucket = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Ownership Controls
resource "aws_s3_bucket_ownership_controls" "ownership" {
  for_each = aws_s3_bucket.buckets

  bucket = each.value.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Server-Side Encryption with KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  for_each = aws_s3_bucket.buckets

  bucket = each.value.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = "alias/aws/s3"
    }
  }
}

# Lifecycle Rules (corrected)
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  for_each = aws_s3_bucket.buckets

  bucket = each.value.id

  rule {
    id     = "lifecycle-rule"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Access Logging (enabled on all buckets, logs go to a separate logging bucket)
resource "aws_s3_bucket_logging" "logging" {
  for_each = aws_s3_bucket.buckets

  bucket        = each.value.id
  target_bucket = var.logging_bucket
  target_prefix = "${each.key}/logs/"
}

# Bucket Policy to Enforce HTTPS-Only Access
resource "aws_s3_bucket_policy" "https_only" {
  for_each = aws_s3_bucket.buckets

  bucket = each.value.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "AllowSSLRequestsOnly",
        Effect: "Deny",
        Principal: "*",
        Action: "s3:*",
        Resource: [
          each.value.arn,
          "${each.value.arn}/*"
        ],
        Condition: {
          Bool: {
            "aws:SecureTransport": "false"
          }
        }
      }
    ]
  })
}

# IAM Role for S3 Access
resource "aws_iam_role" "s3_access_role" {
  name = var.s3_access_role

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy Scoped to Specific Buckets and Actions
resource "aws_iam_policy" "s3_policy" {
  name = var.s3_policy

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ],
        Resource = flatten([
          for bucket in aws_s3_bucket.buckets : [
            bucket.arn,
            "${bucket.arn}/*"
          ]
        ])
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.s3_access_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}
