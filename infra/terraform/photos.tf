# Photos the worker takes when collecting an online order (shown to the customer
# on their request). Private bucket: the phone uploads with a short-lived signed
# link from marketplace-service and the customer views through another one.
# Photos are deleted automatically after var.pickup_photo_retention_days.

variable "pickup_photo_retention_days" {
  description = "How long pickup photos are kept before S3 deletes them."
  type        = number
  default     = 180
}

resource "aws_s3_bucket" "pickup_photos" {
  bucket = "${local.name}-pickup-photos-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "pickup_photos" {
  bucket                  = aws_s3_bucket.pickup_photos.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pickup_photos" {
  bucket = aws_s3_bucket.pickup_photos.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "pickup_photos" {
  bucket = aws_s3_bucket.pickup_photos.id

  rule {
    id     = "expire-old-photos"
    status = "Enabled"
    filter {}
    expiration {
      days = var.pickup_photo_retention_days
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

# The server signs links with its own role: it can write and read photos, nothing else.
resource "aws_iam_role_policy" "server_pickup_photos" {
  name = "pickup-photos"
  role = aws_iam_role.server.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject"]
        Resource = "${aws_s3_bucket.pickup_photos.arn}/pickups/*"
      },
    ]
  })
}

output "pickup_photos_bucket" {
  description = "Set as PICKUP_PHOTOS_BUCKET in the server's marketplace-service env."
  value       = aws_s3_bucket.pickup_photos.bucket
}
