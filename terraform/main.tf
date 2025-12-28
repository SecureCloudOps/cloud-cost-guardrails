# Terraform scaffold intentionally contains no resources yet.
# Guardrail ensures all mandatory tags are provided before applying.

resource "terraform_data" "mandatory_tags_guardrail" {
  lifecycle {
    precondition {
      condition     = length(local.missing_or_empty_mandatory_tags) == 0
      error_message = "Mandatory tags missing or empty: ${local.missing_or_empty_mandatory_tags}"
    }
  }
}
