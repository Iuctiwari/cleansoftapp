# Uptime alerts by email.
#  - Route 53 health checks hit the public HTTPS endpoints the app uses every 30 s
#    from several AWS locations; an alarm emails when one fails for ~1–2 minutes.
#    (~$0.50/month per check.) Their metrics live in us-east-1, so those alarms
#    and their SNS topic are created there.
#  - EC2 status-check alarms (free): auto-recover on AWS hardware faults, email on
#    either check failing, and on sustained high CPU.
# Each SNS topic emails a confirmation link once — click it or no alerts arrive.

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project   = "nexoraa-cleansoft"
      ManagedBy = "terraform"
    }
  }
}

locals {
  alert_email   = coalesce(var.alert_email, var.budget_email)
  public_domain = "${replace(aws_eip.server.public_ip, ".", "-")}.sslip.io"

  uptime_checks = {
    login  = { host = "auth.${local.public_domain}", path = "/api/v1/health/live" }
    orders = { host = "order.${local.public_domain}", path = "/api/v1/health" }
    admin  = { host = "admin.${local.public_domain}", path = "/api/v1/health" }
  }
}

# ── HTTPS uptime checks (us-east-1) ──────────────────────────────────────────

resource "aws_sns_topic" "uptime_alerts" {
  provider = aws.us_east_1
  name     = "${local.name}-uptime-alerts"
}

resource "aws_sns_topic_subscription" "uptime_email" {
  provider  = aws.us_east_1
  topic_arn = aws_sns_topic.uptime_alerts.arn
  protocol  = "email"
  endpoint  = local.alert_email
}

resource "aws_route53_health_check" "uptime" {
  for_each          = local.uptime_checks
  fqdn              = each.value.host
  port              = 443
  type              = "HTTPS"
  resource_path     = each.value.path
  request_interval  = 30
  failure_threshold = 3
  measure_latency   = true

  tags = { Name = "${local.name}-${each.key}" }
}

resource "aws_cloudwatch_metric_alarm" "uptime" {
  provider            = aws.us_east_1
  for_each            = local.uptime_checks
  alarm_name          = "${local.name}-${each.key}-down"
  alarm_description   = "https://${each.value.host}${each.value.path} is not answering — the app's ${each.key} is down."
  namespace           = "AWS/Route53"
  metric_name         = "HealthCheckStatus"
  dimensions          = { HealthCheckId = aws_route53_health_check.uptime[each.key].id }
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  comparison_operator = "LessThanThreshold"
  threshold           = 1
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.uptime_alerts.arn]
  ok_actions          = [aws_sns_topic.uptime_alerts.arn] # "back up" email too
}

# ── EC2 server alarms (ap-south-1, free) ─────────────────────────────────────

resource "aws_sns_topic" "server_alerts" {
  name = "${local.name}-server-alerts"
}

resource "aws_sns_topic_subscription" "server_email" {
  topic_arn = aws_sns_topic.server_alerts.arn
  protocol  = "email"
  endpoint  = local.alert_email
}

resource "aws_cloudwatch_metric_alarm" "server_system_check" {
  alarm_name          = "${local.name}-server-system-check"
  alarm_description   = "AWS hardware/network problem under the server — automatically recovering it."
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed_System"
  dimensions          = { InstanceId = aws_instance.server.id }
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  alarm_actions = [
    "arn:aws:automate:${var.aws_region}:ec2:recover",
    aws_sns_topic.server_alerts.arn,
  ]
}

resource "aws_cloudwatch_metric_alarm" "server_instance_check" {
  alarm_name          = "${local.name}-server-instance-check"
  alarm_description   = "The server's operating system is not responding — rebooting it."
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed_Instance"
  dimensions          = { InstanceId = aws_instance.server.id }
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 3
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  alarm_actions = [
    "arn:aws:automate:${var.aws_region}:ec2:reboot",
    aws_sns_topic.server_alerts.arn,
  ]
}

resource "aws_cloudwatch_metric_alarm" "server_cpu" {
  alarm_name          = "${local.name}-server-cpu-high"
  alarm_description   = "Server CPU above 90% for 15 minutes — the app may be slow; consider a bigger instance."
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  dimensions          = { InstanceId = aws_instance.server.id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  comparison_operator = "GreaterThanThreshold"
  threshold           = 90
  alarm_actions       = [aws_sns_topic.server_alerts.arn]
}
