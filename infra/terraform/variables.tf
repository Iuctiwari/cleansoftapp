variable "aws_region" {
  description = "AWS region for everything. Mumbai is closest to the app's users."
  type        = string
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "EC2 size. t3.small (2 GB) runs all 14 services with swap; t3.medium if memory gets tight."
  type        = string
  default     = "t3.small"
}

variable "disk_size_gb" {
  description = "Root disk size."
  type        = number
  default     = 30
}

variable "admin_ssh_cidr" {
  description = "Optional: your own IP as x.x.x.x/32 for direct SSH. Leave null to use only the browser terminal."
  type        = string
  default     = null
}

variable "budget_email" {
  description = "Email that receives the monthly budget alerts."
  type        = string
}

variable "monthly_budget_usd" {
  description = "Alert when forecast/actual monthly spend passes this amount."
  type        = number
  default     = 10
}

variable "github_repository" {
  description = "owner/name of the GitHub repo allowed to deploy."
  type        = string
  default     = "official-nexoraatech/nexoraa-cleansoft"
}

variable "deploy_branch" {
  description = "Only GitHub Actions runs on this branch may deploy."
  type        = string
  default     = "iuc"
}

variable "alert_email" {
  description = "Email for downtime/server alerts. Defaults to budget_email."
  type        = string
  default     = null
}

variable "backup_retention_days" {
  description = "How long daily database backups are kept in S3."
  type        = number
  default     = 30
}

variable "create_github_oidc_provider" {
  description = "Set false if this AWS account already has the token.actions.githubusercontent.com OIDC provider."
  type        = bool
  default     = true
}
