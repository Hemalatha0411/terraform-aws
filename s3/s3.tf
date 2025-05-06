# Create S3 Buckets
resource "aws_s3_bucket" "upload_bucket" {
  bucket        = var.upload_bucket
  force_destroy = true
}

resource "aws_s3_bucket" "download_bucket" {
  bucket        = var.download_bucket
  force_destroy = true
}

resource "aws_s3_bucket" "app_data_bucket" {
  bucket        = var.app_data_bucket
  force_destroy = true
}
# Enable Versioning for Buckets
resource "aws_s3_bucket_versioning" "upload_bucket_versioning" {
  bucket = aws_s3_bucket.upload_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "download_bucket_versioning" {
  bucket = aws_s3_bucket.download_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "app_data_bucket_versioning" {
  bucket = aws_s3_bucket.app_data_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}
# Define Ownership Controls for Buckets
resource "aws_s3_bucket_ownership_controls" "upload_bucket_ownership" {
  bucket = aws_s3_bucket.upload_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_ownership_controls" "download_bucket_ownership" {
  bucket = aws_s3_bucket.download_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_ownership_controls" "app_data_bucket_ownership" {
  bucket = aws_s3_bucket.app_data_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Server-Side Encryption Configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "upload_bucket_encryption" {
  bucket = aws_s3_bucket.upload_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "download_bucket_encryption" {
  bucket = aws_s3_bucket.download_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_data_bucket_encryption" {
  bucket = aws_s3_bucket.app_data_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle Configuration for Upload Bucket
resource "aws_s3_bucket_lifecycle_configuration" "upload_bucket_lifecycle" {
  bucket = aws_s3_bucket.upload_bucket.id

  rule {
    id     = "archive-and-delete-rule"
    status = "Enabled"

    filter {
      prefix = "" # Apply rule to all objects
    }

    expiration {
      days = 90 # Delete after 90 days
    }

    transition {
      days          = 60 # Archive after 60 days
      storage_class = "GLACIER"
    }
  }
}

# Lifecycle Configuration for Download Bucket
resource "aws_s3_bucket_lifecycle_configuration" "download_bucket_lifecycle" {
  bucket = aws_s3_bucket.download_bucket.id

  rule {
    id     = "archive-and-delete-rule"
    status = "Enabled"

    filter {
      prefix = "" # Apply rule to all objects
    }

    expiration {
      days = 90 # Delete after 90 days
    }

    transition {
      days          = 60 # Archive after 60 days
      storage_class = "GLACIER"
    }
  }
}

# Lifecycle Configuration for App Data Bucket
resource "aws_s3_bucket_lifecycle_configuration" "app_data_bucket_lifecycle" {
  bucket = aws_s3_bucket.app_data_bucket.id

  rule {
    id     = "archive-and-delete-rule"
    status = "Enabled"

    filter {
      prefix = "" # Apply rule to all objects
    }

    expiration {
      days = 90 # Delete after 90 days
    }

    transition {
      days          = 60 # Archive after 60 days
      storage_class = "GLACIER"
    }
  }
}

# Define IAM Role for S3 Scoped Access
resource "aws_iam_role" "s3_access_role" {
  name = var.s3_access_role

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com" # or another service you intend
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Define Scoped IAM Policies
resource "aws_iam_policy" "s3_policy" {
  name   = var.s3_policy
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = [
          aws_s3_bucket.upload_bucket.arn,
          "${aws_s3_bucket.upload_bucket.arn}/*",
          aws_s3_bucket.download_bucket.arn,
          "${aws_s3_bucket.download_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.s3_access_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}
