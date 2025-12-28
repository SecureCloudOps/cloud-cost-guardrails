locals {
  github_actions_role_name = "${var.project}-${var.env}-gha-terraform"
  github_subjects_allowed = [
    for workflow in var.github_workflows :
    "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${var.github_branch}:workflow:${workflow}"
  ]
}

# Discover existing role (if created outside this state) to avoid EntityAlreadyExists during bootstrap.
data "aws_iam_roles" "github_actions" {
  count       = var.detect_existing_github_actions_iam ? 1 : 0
  name_regex  = "^${local.github_actions_role_name}$"
  path_prefix = "/"
}

locals {
  github_actions_role_exists = var.detect_existing_github_actions_iam && length(try(data.aws_iam_roles.github_actions[0].names, [])) > 0
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
  count              = local.github_actions_role_exists ? 0 : 1
  name               = local.github_actions_role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  description = "Role assumed by GitHub Actions (deploy/destroy) via OIDC for Terraform operations."
  tags        = local.mandatory_tags
}

locals {
  github_actions_role_name_final = local.github_actions_role_exists ? data.aws_iam_roles.github_actions[0].names[0] : aws_iam_role.github_actions_terraform[0].name
  github_actions_role_arn        = local.github_actions_role_exists ? data.aws_iam_roles.github_actions[0].arns[0]  : aws_iam_role.github_actions_terraform[0].arn
}
