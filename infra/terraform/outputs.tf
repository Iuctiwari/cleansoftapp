output "public_ip" {
  description = "Fixed public IP of the server (add to MongoDB Atlas Network Access if 0.0.0.0/0 isn't allowed)."
  value       = aws_eip.server.public_ip
}

output "public_domain" {
  description = "Base domain deploy.sh uses for HTTPS (e.g. https://auth.<this>/api)."
  value       = "${replace(aws_eip.server.public_ip, ".", "-")}.sslip.io"
}

output "instance_id" {
  value = aws_instance.server.id
}

output "apk_download_url" {
  description = "Public link after uploading the APK as apk/app-release.apk."
  value       = "https://${aws_s3_bucket.downloads.bucket_regional_domain_name}/apk/app-release.apk"
}

output "backups_bucket" {
  description = "Private bucket with the nightly database backups."
  value       = aws_s3_bucket.backups.bucket
}

output "downloads_bucket" {
  value = aws_s3_bucket.downloads.bucket
}

output "github_actions_variables" {
  description = "Add each of these under GitHub repo -> Settings -> Secrets and variables -> Actions -> Variables."
  value = {
    AWS_REGION          = var.aws_region
    AWS_DEPLOY_ROLE_ARN = aws_iam_role.github_deploy.arn
    AWS_INSTANCE_ID     = aws_instance.server.id
    PUBLIC_DOMAIN       = "${replace(aws_eip.server.public_ip, ".", "-")}.sslip.io"
  }
}
