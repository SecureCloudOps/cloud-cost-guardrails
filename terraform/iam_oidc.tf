locals {
  github_oidc_url      = "https://token.actions.githubusercontent.com"
  github_oidc_audience = "sts.amazonaws.com"
}

# Resolve the GitHub OIDC provider certificate thumbprint dynamically to avoid
# hardcoding values or passing them via workflow inputs.
data "tls_certificate" "github_oidc" {
  url = local.github_oidc_url
}

# GitHub Actions OIDC provider for short-lived, keyless auth.
# Tags are not supported on IAM OIDC providers.
resource "aws_iam_openid_connect_provider" "github" {
  url             = local.github_oidc_url
  client_id_list  = [local.github_oidc_audience]
  thumbprint_list = [data.tls_certificate.github_oidc.certificates[0].sha1_fingerprint]
}
