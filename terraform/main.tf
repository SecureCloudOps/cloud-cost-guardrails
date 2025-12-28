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
  name = "${var.project}-budget-alerts"
  tags = local.mandatory_tags
}

resource "aws_sns_topic_subscription" "budget_email" {
  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "email"
  endpoint  = var.budget_alert_email

  # SNS subscriptions do not support tags.
}

resource "aws_budgets_budget" "monthly_cost_guardrail" {
  name              = "${var.project}-${var.env}-monthly-budget"
  budget_type       = "COST"
  limit_amount      = var.budget_amount
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  budget_description = "Guardrail budget for ${var.project} in ${var.env}"

  notification {
    comparison_operator = "GREATER_THAN"
    notification_type   = "FORECASTED"
    threshold           = 80
    threshold_type      = "PERCENTAGE"

    subscriber {
      address          = aws_sns_topic.budget_alerts.arn
      subscription_type = "SNS"
    }
  }

  notification {
    comparison_operator = "GREATER_THAN"
    notification_type   = "ACTUAL"
    threshold           = 100
    threshold_type      = "PERCENTAGE"

    subscriber {
      address          = aws_sns_topic.budget_alerts.arn
      subscription_type = "SNS"
    }
  }

  tags = local.mandatory_tags
}
