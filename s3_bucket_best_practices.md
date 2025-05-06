
# Terraform Best Practices for Production-Ready S3 Buckets

## 1. Security
- Avoid using `force_destroy = true` in production environments. Set `force_destroy = false` to prevent accidental deletion.
- Enforce encryption using AWS KMS:
  ```hcl
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = "alias/my-key"
      }
    }
  }
  ```
- Use bucket policies to enforce secure transport (HTTPS-only):
  ```hcl
  resource "aws_s3_bucket_policy" "https_only" {
    bucket = aws_s3_bucket.example.id
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Sid: "AllowSSLRequestsOnly",
          Effect: "Deny",
          Principal: "*",
          Action: "s3:*",
          Resource: [
            "${aws_s3_bucket.example.arn}",
            "${aws_s3_bucket.example.arn}/*"
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
  ```

## 2. Monitoring and Auditing
- Enable S3 access logging to a separate log bucket.
- Enable AWS CloudTrail to log all S3 API activity.

## 3. Lifecycle Management
- Set up object lifecycle policies to transition objects to lower-cost storage and delete old data:
  ```hcl
  lifecycle_rule {
    id      = "archive-and-delete"
    enabled = true
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
    abort_incomplete_multipart_upload_days = 7
  }
  ```

## 4. IAM and Access Control
- Use least privilege principle for IAM policies.
- Avoid using wide `s3:*` actions in production. Prefer specific actions such as `s3:GetObject`, `s3:PutObject`.
- Consider using condition keys like `aws:SourceVpc`, `aws:SourceIp`, or `aws:userid` in policies.

## 5. Naming Conventions and Tagging
- Use consistent bucket naming schemes (e.g., `<env>-<app>-<purpose>`).
- Apply tags for resource identification and cost tracking:
  ```hcl
  tags = {
    Environment = "production"
    Owner       = "devops"
    Project     = "my-app"
  }
  ```

## 6. Maintainability
- Use `for_each` or modules to avoid code duplication when provisioning multiple buckets.
- Keep sensitive variables such as bucket names and KMS keys in `terraform.tfvars` or a secure variable file.

## 7. Other Recommendations
- Regularly audit bucket policies and access logs.
- Set `object_ownership = "BucketOwnerEnforced"` to prevent ACLs.
- Monitor bucket usage and storage class transitions for cost optimization.
