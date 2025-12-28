provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.mandatory_tags
  }

  # Allow `terraform plan` to run in CI without AWS credentials; OIDC creds
  # will be provided only in deploy/destroy workflows.
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}
