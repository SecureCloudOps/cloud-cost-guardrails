locals {
  github_oidc_url      = "https://token.actions.githubusercontent.com"
  github_oidc_audience = "sts.amazonaws.com"
}

# Resolve the GitHub OIDC provider certificate thumbprint dynamically to avoid
# hardcoding values or passing them via workflow inputs.
data "tls_certificate" "github_oidc" {
  url = local.github_oidc_url
}

# Use the existing GitHub Actions OIDC provider (global IAM resource).
data "aws_iam_openid_connect_provider" "github" {
  url = local.github_oidc_url
}
