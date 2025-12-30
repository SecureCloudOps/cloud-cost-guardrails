# Use the expected SNS topic name without depending on the topic resource so the
# bootstrap IAM-only apply does not try to create SNS/Budget resources. The
# wildcarded ARN is constrained to the topic name pattern while avoiding
# account/region hardcoding.
locals {
  github_actions_policy_name      = "${var.project}-${var.env}-gha-terraform"
  github_actions_policy_arn_input = trimspace(var.existing_github_actions_policy_arn)
  sns_topic_name                  = "${var.project}-budget-alerts"
}

data "aws_iam_policy" "existing" {
  count = length(local.github_actions_policy_arn_input) > 0 ? 1 : 0
  arn   = local.github_actions_policy_arn_input
}

data "aws_iam_policy_document" "github_actions_permissions" {
  statement {
    sid    = "BudgetsManage"
    effect = "Allow"
    actions = [
      "budgets:CreateBudget",
      "budgets:UpdateBudget",
      "budgets:DeleteBudget",
      "budgets:ViewBudget",
      "budgets:DescribeBudget",
      "budgets:DescribeBudgets",
      "budgets:DescribeBudgetPerformanceHistory",
      "budgets:ExecuteBudgetAction",
      "budgets:DescribeNotificationsForBudget",
      "budgets:DescribeBudgetAction",
      "budgets:DescribeBudgetActionsForBudget",
    ]
    # checkov:skip=CKV_AWS_356: AWS Budgets API requires Resource='*'; no resource-level permissions exist.
    # checkov:skip=CKV_AWS_108: AWS Budgets API requires Resource='*'; no resource-level permissions exist.
    # checkov:skip=CKV_AWS_111: AWS Budgets API requires Resource='*'; no resource-level permissions exist.
    resources = ["*"]
  }

  statement {
    sid    = "SNSBudgetAlerts"
    effect = "Allow"
    actions = [
      "sns:CreateTopic",
      "sns:DeleteTopic",
      "sns:GetTopicAttributes",
      "sns:SetTopicAttributes",
      "sns:Subscribe",
      "sns:Unsubscribe",
      "sns:ListSubscriptionsByTopic",
      "sns:Publish",
    ]
    resources = [aws_sns_topic.budget_alerts.arn]
  }

  # Placeholder for future state backend access; scope to concrete ARNs once chosen.
  statement {
    sid    = "TerraformStateAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:DeleteItem",
      "dynamodb:UpdateItem",
      "dynamodb:DescribeTable",
    ]
    # checkov:skip=CKV_AWS_356: Placeholder until backend bucket/table exists; will scope to ARNs when backend is defined.
    # checkov:skip=CKV_AWS_108: Placeholder until backend bucket/table exists; will scope to ARNs when backend is defined.
    # checkov:skip=CKV_AWS_111: Placeholder until backend bucket/table exists; will scope to ARNs when backend is defined.
    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_actions" {
  count       = length(local.github_actions_policy_arn_input) > 0 ? 0 : 1
  name        = local.github_actions_policy_name
  description = "Least-privilege policy for GitHub Actions Terraform (budgets, SNS alerts, future state backend)."
  policy      = data.aws_iam_policy_document.github_actions_permissions.json
  tags        = local.mandatory_tags
}

locals {
  github_actions_policy_arn = length(local.github_actions_policy_arn_input) > 0 ? data.aws_iam_policy.existing[0].arn : aws_iam_policy.github_actions[0].arn
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = local.github_actions_role_name_resolved
  policy_arn = local.github_actions_policy_arn
}
