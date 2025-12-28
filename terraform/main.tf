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

  tags = local.mandatory_tags
}

# Budget notifications are defined separately to align with the AWS provider schema.
# Tags are not supported on budget notifications.
resource "aws_budgets_budget_notification" "forecasted_80" {
  budget_name         = aws_budgets_budget.monthly_cost_guardrail.name
  comparison_operator = "GREATER_THAN"
  notification_type   = "FORECASTED"
  threshold           = 80
  threshold_type      = "PERCENTAGE"
  subscriber_sns_topic_arns = [
    aws_sns_topic.budget_alerts.arn
  ]
}

resource "aws_budgets_budget_notification" "actual_100" {
  budget_name         = aws_budgets_budget.monthly_cost_guardrail.name
  comparison_operator = "GREATER_THAN"
  notification_type   = "ACTUAL"
  threshold           = 100
  threshold_type      = "PERCENTAGE"
  subscriber_sns_topic_arns = [
    aws_sns_topic.budget_alerts.arn
  ]
}
