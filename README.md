# cloud-cost-guardrails

Security-first AWS cost guardrails built with Terraform, CI scanning, and serverless-first components.

## Project overview
- Enforces cost governance with mandatory tagging and single-region scope.
- Establishes clear ownership for every stack via required metadata.
- Surfaces drift risk early through CI enforcement (fmt, validate, plan).
- Blocks secret leaks with gitleaks and Terraform static checks.
- Lays groundwork for alerting/cleanup automation (TTL tagging) without deploying resources yet.

## Execution Model
- Terraform commands are **never run locally**; everything executes via GitHub Actions.
- Pull requests trigger validation-only workflows (fmt, validate, plan with safe flags).
- Apply and destroy are performed by GitHub Actions jobs, not developer workstations.
- No developer machine needs AWS access; credentials stay within CI-controlled environments.

## OIDC Authentication
- GitHub Actions assumes an AWS IAM role via OpenID Connect; no static AWS keys are stored or used.
- Trust is restricted to this repo, `main` branch, and the deploy/destroy workflows.
- AWS access is short-lived and scoped by least-privilege IAM policies for budgets, SNS, and future Terraform state.

## AWS Budget Alerts
- Creates a low-limit monthly cost budget with alerts at 80% (forecasted) and 100% (actual) of spend.
- Alerts publish to an SNS topic and notify via email (address provided via variables, never hardcoded).
- Intended as a demo-friendly guardrail to cap unexpected spend; no always-on compute is added.
- Budgets and alerts are created/removed only through GitHub Actions deploy/destroy workflows.

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
