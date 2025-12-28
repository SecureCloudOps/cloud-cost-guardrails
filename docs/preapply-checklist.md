# Pre-Apply Checklist (senior-level)

Use this checklist before any `terraform apply`. All Terraform execution happens in GitHub Actions only.

## Local checks
- No local Terraform runs. Verify code quality via static review and CI status.

## Public repo safety
- `git status` is clean; no untracked or staged state/plan files.
- No `terraform.tfvars` or real env values committed (only `.example` files tracked).
- No `.terraform/`, `*.tfstate*`, or plan outputs present.
- Run `gitleaks detect -c .gitleaks.toml` (expect no findings).

## CI checks
- Latest GitHub Actions workflow runs are green (Terraform fmt/validate/plan, Checkov, Gitleaks).
- Branch protection rules enforced (status checks required, no force pushes).

## Terraform sanity checks
- Variables supplied to CI via approved mechanisms (e.g., GitHub Actions secrets/vars); nothing hardcoded in code.
- No backend configured yet; state remains ephemeral in CI runs unless configured later.
- Mandatory cost tags populated (Project, Owner, Env, CostCenter, TTL); no empty/placeholder values.
- No real emails, ARNs, account IDs, or secrets in code or vars.

## Go / No-Go
- **Go** if: CI checks pass (fmt/validate/plan, Checkov, Gitleaks); mandatory tags set; repo clean (no tfvars/state/plan files tracked); branch protection satisfied.
- **No-Go** if: any CI check fails; tags missing; repo shows tfvars/state/plan files; secrets or identifiers detected.

## Troubleshooting quick wins
- Format/validate errors: fix code per Terraform diagnostics; rerun CI.
- Tag precondition failure: adjust variables passed to CI to ensure mandatory tags are non-empty and whitespace-free.
- Init/plan errors about backend: remove any backend blocks; CI runs with `-backend=false`.
- Gitleaks finding: rotate and remove the secret from history; replace with placeholder; re-run scan.
- Missing provider/version issues: ensure CI pins the intended Terraform and provider versions; re-run workflow.
