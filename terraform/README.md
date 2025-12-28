# Terraform configuration

Minimal scaffold with mandatory tagging guardrails. No resources or backend are configured yet.

## Local usage (from repo root)
1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in placeholders (do not commit `terraform.tfvars`).
2. Run formatting, init, validate, and plan:
   ```bash
   terraform -chdir=terraform fmt -recursive
   terraform -chdir=terraform init -backend=false -lock=false
   terraform -chdir=terraform validate
   terraform -chdir=terraform plan -lock=false -input=false -refresh=false -no-color
   ```

## Notes
- Keep everything AWS-only, single-account, single-region, and destroyable with `terraform destroy`.
- Avoid data sources or variables that reveal real account details in this public repo.
