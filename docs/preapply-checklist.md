# Pre-Apply Checklist (senior-level)

Use this checklist before any `terraform apply`. Keep scope tight, public-safe, and fully reversible.

## Local checks
- `terraform -chdir=terraform fmt -recursive`
- `terraform -chdir=terraform init -backend=false -lock=false`
- `terraform -chdir=terraform validate`
- `terraform -chdir=terraform plan -lock=false -input=false -refresh=false -no-color`

## Public repo safety
- `git status` is clean; no untracked or staged state/plan files.
- No `terraform.tfvars` or real env values committed (only `.example` files tracked).
- No `.terraform/`, `*.tfstate*`, or plan outputs present.
- Run `gitleaks detect -c .gitleaks.toml` (expect no findings).

## CI checks
- Latest GitHub Actions workflow runs are green (Terraform fmt/validate/plan, Checkov, Gitleaks).
- Branch protection rules enforced (status checks required, no force pushes).

## Terraform sanity checks
- Variables supplied locally via `terraform.tfvars` or `-var` flags; nothing hardcoded in code.
- No backend configured yet; local state only.
- Mandatory cost tags populated (Project, Owner, Env, CostCenter, TTL); no empty/placeholder values.
- No real emails, ARNs, account IDs, or secrets in code or vars.

## Go / No-Go
- **Go** if: local checks pass; gitleaks clean; CI green; mandatory tags set; state/plan files not tracked.
- **No-Go** if: any validation/plan fails; tags missing; CI failing; repo shows tfvars/state/plan files; secrets or identifiers detected.

## Troubleshooting quick wins
- Format/validate errors: rerun `terraform fmt`, fix inputs, then `terraform validate`.
- Tag precondition failure: check `terraform.tfvars` for empty/missing mandatory tags; remove whitespace-only values.
- Init/plan errors about backend: ensure `-backend=false` is set; remove any accidental backend blocks.
- Gitleaks finding: rotate and remove the secret from history; replace with placeholder; re-run scan.
- Missing provider/version issues: run `terraform init -upgrade -backend=false -lock=false` and retry.
