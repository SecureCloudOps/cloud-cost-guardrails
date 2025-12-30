# Terraform resources are limited to cost guardrails (tags, budgets, alerts).
# Guardrail ensures all mandatory tags are provided before applying.

resource "terraform_data" "mandatory_tags_guardrail" {
  lifecycle {
    precondition {
      condition     = length(local.missing_or_empty_mandatory_tags) == 0
      error_message = "Mandatory tags missing or empty: ${local.missing_or_empty_mandatory_tags}"
    }
  }
}

resource "aws_sns_topic" "budget_alerts" {
  name              = "${var.project}-budget-alerts"
  kms_master_key_id = aws_kms_key.sns_budget_alerts.arn
  tags              = local.mandatory_tags
}

resource "aws_sns_topic_subscription" "budget_email" {
  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "email"
  endpoint  = var.budget_alert_email

  # SNS subscriptions do not support tags.
}

resource "aws_budgets_budget" "monthly_cost_guardrail" {
  name         = "${var.project}-${var.env}-monthly-budget"
  budget_type  = "COST"
  limit_amount = var.budget_amount
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator       = "GREATER_THAN"
    notification_type         = "FORECASTED"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    subscriber_sns_topic_arns = [aws_sns_topic.budget_alerts.arn]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    notification_type         = "ACTUAL"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    subscriber_sns_topic_arns = [aws_sns_topic.budget_alerts.arn]
  }

  tags = local.mandatory_tags
}

resource "aws_kms_key" "sns_budget_alerts" {
  description             = "KMS key for SNS budget alert topics"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowAccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowSNSUse"
        Effect    = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action    = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey",
        ]
        Resource  = "*"
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
  tags = local.mandatory_tags
}
