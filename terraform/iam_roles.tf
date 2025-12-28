locals {
  github_subjects_allowed = [
    for workflow in var.github_workflows :
    "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${var.github_branch}:workflow:${workflow}"
  ]
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    sid     = "GitHubOIDCTrust"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Restrict to this repository, main branch, and specific workflows.
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.github_subjects_allowed
    }
  }
}

resource "aws_iam_role" "github_actions_terraform" {
  name               = "${var.project}-${var.env}-gha-terraform"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  description = "Role assumed by GitHub Actions (deploy/destroy) via OIDC for Terraform operations."
  tags        = local.mandatory_tags
}
