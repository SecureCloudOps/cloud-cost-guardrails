locals {
  github_actions_role_name_input = trimspace(var.existing_github_actions_role_name)
  github_actions_role_name       = "${var.project}-${var.env}-gha-terraform"
  github_actions_role_name_final = length(local.github_actions_role_name_input) > 0 ? local.github_actions_role_name_input : local.github_actions_role_name
  github_subjects_allowed = concat(
    [
      for workflow in var.github_workflows :
      "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${var.github_branch}:workflow:${workflow}"
    ],
    [
      "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${var.github_branch}:workflow:ci.yml",
      # Wildcard entry covers PR refs and feature branches for same-repo runs.
      "repo:${var.github_owner}/${var.github_repo}:*",
    ],
  )
}

# Discover existing role (if provided) to avoid EntityAlreadyExists during bootstrap.
data "aws_iam_role" "existing" {
  count = length(local.github_actions_role_name_input) > 0 ? 1 : 0
  name  = local.github_actions_role_name_input
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    sid     = "GitHubOIDCTrust"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
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
  count              = length(local.github_actions_role_name_input) > 0 ? 0 : 1
  name               = local.github_actions_role_name_final
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  description = "Role assumed by GitHub Actions (deploy/destroy) via OIDC for Terraform operations."
  tags        = local.mandatory_tags
}

locals {
  github_actions_role_name_resolved = length(local.github_actions_role_name_input) > 0 ? data.aws_iam_role.existing[0].name : aws_iam_role.github_actions_terraform[0].name
  github_actions_role_arn_resolved  = length(local.github_actions_role_name_input) > 0 ? data.aws_iam_role.existing[0].arn : aws_iam_role.github_actions_terraform[0].arn
}
