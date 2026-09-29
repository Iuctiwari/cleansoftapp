# Nexoraa CleanSoft on AWS: one EC2 server running every backend service (see
# infra/aws-ec2 for what runs on it), a fixed public IP, an S3 bucket for the
# APK download, a budget alert, and a GitHub Actions deploy role (OIDC + SSM,
# so GitHub never holds an SSH key or long-lived AWS credentials).

data "aws_caller_identity" "current" {}

locals {
  name = "nexoraa"
}

# ── Server ────────────────────────────────────────────────────────────────────

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# AWS-managed list of the IP ranges EC2 Instance Connect (the browser terminal)
# connects from in this region.
data "aws_ec2_managed_prefix_list" "instance_connect" {
  name = "com.amazonaws.${var.aws_region}.ec2-instance-connect"
}

resource "aws_security_group" "server" {
  name        = "${local.name}-server"
  description = "Nexoraa server: HTTPS for the app, SSH only for the browser terminal"
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.server.id
  # Rule descriptions allow only a-zA-Z0-9. _-:/()#,@[]+=&;{}!$* (no apostrophes).
  description = "HTTP (LetsEncrypt challenge + redirect to HTTPS)"
  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.server.id
  description       = "HTTPS (mobile app to Caddy)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "ssh_instance_connect" {
  security_group_id = aws_security_group.server.id
  description       = "SSH from EC2 Instance Connect (browser terminal)"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  prefix_list_id    = data.aws_ec2_managed_prefix_list.instance_connect.id
}

resource "aws_vpc_security_group_ingress_rule" "ssh_admin" {
  count             = var.admin_ssh_cidr == null ? 0 : 1
  security_group_id = aws_security_group.server.id
  description       = "SSH from the admin own IP"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.admin_ssh_cidr
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.server.id
  description       = "Outbound: MongoDB Atlas, GitHub, npm, LetsEncrypt, email/payment APIs"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# Instance role: lets AWS Systems Manager run the deploy command sent by GitHub
# Actions (the SSM agent is preinstalled on Ubuntu AMIs).
resource "aws_iam_role" "server" {
  name = "${local.name}-server"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "server_ssm" {
  role       = aws_iam_role.server.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "server" {
  name = "${local.name}-server"
  role = aws_iam_role.server.name
}

resource "aws_instance" "server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.server.id]
  iam_instance_profile   = aws_iam_instance_profile.server.name

  root_block_device {
    volume_type = "gp3"
    volume_size = var.disk_size_gb
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required" # IMDSv2 only; deploy.sh already uses it
  }

  tags = { Name = "${local.name}-server" }

  lifecycle {
    # A newer Ubuntu image must never silently rebuild (and wipe) the server.
    ignore_changes = [ami]
  }
}

resource "aws_eip" "server" {
  domain   = "vpc"
  instance = aws_instance.server.id
  tags     = { Name = "${local.name}-server" }
}

# ── S3: public APK downloads (only the apk/ folder is public) ─────────────────

resource "aws_s3_bucket" "downloads" {
  bucket = "${local.name}-app-downloads-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "downloads" {
  bucket                  = aws_s3_bucket.downloads.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "downloads_public_apk" {
  bucket = aws_s3_bucket.downloads.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicApkDownload"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.downloads.arn}/apk/*"
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.downloads]
}

# ── Budget alert ──────────────────────────────────────────────────────────────

resource "aws_budgets_budget" "monthly" {
  name         = "${local.name}-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_email]
  }
}

# ── GitHub Actions deploy role (OIDC, no stored AWS keys) ─────────────────────

resource "aws_iam_openid_connect_provider" "github" {
  count           = var.create_github_oidc_provider ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

locals {
  github_oidc_provider_arn = (
    var.create_github_oidc_provider
    ? aws_iam_openid_connect_provider.github[0].arn
    : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
  )
}

resource "aws_iam_role" "github_deploy" {
  name = "${local.name}-github-deploy"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.github_oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          # Only workflow runs on the deploy branch of this repo can assume it.
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:ref:refs/heads/${var.deploy_branch}"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "github_deploy" {
  name = "run-deploy-on-server"
  role = aws_iam_role.github_deploy.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SendDeployCommandToThisServerOnly"
        Effect = "Allow"
        Action = "ssm:SendCommand"
        Resource = [
          aws_instance.server.arn,
          "arn:aws:ssm:${var.aws_region}::document/AWS-RunShellScript",
        ]
      },
      {
        Sid      = "ReadCommandResults"
        Effect   = "Allow"
        Action   = ["ssm:GetCommandInvocation", "ssm:ListCommandInvocations"]
        Resource = "*"
      },
    ]
  })
}
