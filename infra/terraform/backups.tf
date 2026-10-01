# Daily MongoDB backups. The server runs infra/aws-ec2/backup-db.sh every night
# (cron) and uploads a compressed dump here. Private bucket; backups are deleted
# automatically after var.backup_retention_days.

resource "aws_s3_bucket" "backups" {
  bucket = "${local.name}-db-backups-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "backups" {
  bucket                  = aws_s3_bucket.backups.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "expire-old-backups"
    status = "Enabled"
    filter {}
    expiration {
      days = var.backup_retention_days
    }
  }
}

# The server may upload and list backups — nothing else in S3.
resource "aws_iam_role_policy" "server_backups" {
  name = "upload-db-backups"
  role = aws_iam_role.server.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject"]
        Resource = "${aws_s3_bucket.backups.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.backups.arn
      },
      {
        # backup-db.sh emails an alert through this topic when a backup fails.
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.server_alerts.arn
      },
    ]
  })
}

output "backup_cron_command" {
  description = "Run once in the server terminal to schedule nightly backups (02:00 IST)."
  value       = "bash ~/nexoraa-cleansoft/infra/aws-ec2/backup-db.sh --install-cron ${aws_s3_bucket.backups.bucket} ${aws_sns_topic.server_alerts.arn}"
}
