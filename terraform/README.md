# Terraform configuration

This project is executed exclusively via GitHub Actions.

## Workflow coverage
- Validate: PR workflows run `terraform fmt`, `terraform validate`, and a safe `terraform plan` (no backend, no refresh, no prompts).
- Apply: Executed by GitHub Actions when explicitly triggered; never from developer machines.
- Destroy: Executed by GitHub Actions with the same guardrails; no local runs.
- Budgets/SNS alerts: Applied only through the deploy workflow once credentials are wired via OIDC.
- IAM OIDC: Provisioned to let GitHub Actions assume a least-privilege role (budgets, SNS, future state) via OpenID Connect; no static keys.

## Why CI-only
- Centralized credentials: no AWS access from developer workstations.
- Deterministic runs: consistent Terraform versioning and flags enforced in CI.
- Cost control: all applies/destroys are auditable and scoped to single-region, destroyable stacks.

## Notes
- Keep everything AWS-only, single-account, single-region, and destroyable with `terraform destroy` (run in CI).
- Avoid data sources or variables that reveal real account details in this public repo.
