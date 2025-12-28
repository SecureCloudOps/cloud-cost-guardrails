output "mandatory_tags" {
  description = "Mandatory tags applied to all resources."
  value       = local.mandatory_tags
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions Terraform (use in deploy/destroy workflows)."
  value       = local.github_actions_role_arn
  sensitive   = false
}
