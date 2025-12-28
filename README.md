# cloud-cost-guardrails

Security-first AWS cost guardrails built with Terraform, CI scanning, and serverless-first components.

## Project overview
- Enforces cost governance with mandatory tagging and single-region scope.
- Establishes clear ownership for every stack via required metadata.
- Surfaces drift risk early through CI enforcement (fmt, validate, plan).
- Blocks secret leaks with gitleaks and Terraform static checks.
- Lays groundwork for alerting/cleanup automation (TTL tagging) without deploying resources yet.

## Mandatory Cost Tags
- `Project`: Human-friendly project identifier.
- `Owner`: Accountable team or alias.
- `Env`: Deployment stage (`dev`, `staging`, `prod`).
- `CostCenter`: Billing or chargeback code.
- `TTL`: Time-to-live indicator to drive cleanup automation.

## CI Guardrails
- Terraform `fmt`, `validate`, and a no-backend `plan` with safe flags.
- Checkov security/compliance scan against `terraform/`.
- Gitleaks secret scan using `.gitleaks.toml`.
- Branch protection should require all CI checks to pass before merge.

## Redactions
- No Terraform backend config, state files, or plan artifacts are committed.
- No `terraform.tfvars` or real environment values are stored—only examples.
- No AWS identifiers, ARNs, account IDs, secrets, or tokens appear in the repo.

## Getting started
1. Copy `terraform.tfvars.example` to `terraform.tfvars` and customize locally without committing sensitive values.
2. Initialize without a backend until one is chosen:
   ```bash
   terraform -chdir=terraform init -backend=false
   ```
3. Run static checks locally:
   ```bash
   terraform -chdir=terraform fmt -recursive
   terraform -chdir=terraform validate
   terraform -chdir=terraform plan -lock=false -input=false -refresh=false -no-color
   ```
4. Add AWS serverless resources gradually, keeping scope tight and avoiding secrets in code or state.
