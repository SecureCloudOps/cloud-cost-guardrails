# Use the expected SNS topic name without depending on the topic resource so the
# bootstrap IAM-only apply does not try to create SNS/Budget resources. The
# wildcarded ARN is constrained to the topic name pattern while avoiding
# account/region hardcoding.
locals {
  github_actions_policy_name = "${var.project}-${var.env}-gha-terraform"
  sns_topic_name = "${var.project}-budget-alerts"
  sns_topic_arns = [
    "arn:aws:sns:*:*:${local.sns_topic_name}",
    "arn:aws:sns:*:*:${local.sns_topic_name}:*",
  ]
}

data "aws_iam_policies" "github_actions" {
  count       = var.detect_existing_github_actions_iam ? 1 : 0
  scope       = "Local"
  name_regex  = "^${local.github_actions_policy_name}$"
  path_prefix = "/"
}

locals {
  github_actions_policy_exists = var.detect_existing_github_actions_iam && length(try(data.aws_iam_policies.github_actions[0].arns, [])) > 0
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
    resources = ["*"] # Budgets are account-scoped; AWS does not support resource-level ARNs for budgets.
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
    resources = local.sns_topic_arns
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
    resources = ["*"] # Scope to state bucket/table ARNs when backend is defined.
  }
}

resource "aws_iam_policy" "github_actions" {
  count       = local.github_actions_policy_exists ? 0 : 1
  name        = local.github_actions_policy_name
  description = "Least-privilege policy for GitHub Actions Terraform (budgets, SNS alerts, future state backend)."
  policy      = data.aws_iam_policy_document.github_actions_permissions.json
  tags        = local.mandatory_tags
}

locals {
  github_actions_policy_arn = local.github_actions_policy_exists ? data.aws_iam_policies.github_actions[0].arns[0] : aws_iam_policy.github_actions[0].arn
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = local.github_actions_role_name_final
  policy_arn = local.github_actions_policy_arn
}
