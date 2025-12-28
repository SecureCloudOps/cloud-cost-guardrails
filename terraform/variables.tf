variable "aws_region" {
  description = "AWS region for all resources. Use a single region for simplicity."
  type        = string

  validation {
    condition     = length(trim(var.aws_region)) > 0
    error_message = "aws_region must be a non-empty string."
  }
}

variable "project" {
  description = "Human-friendly project identifier used for tagging."
  type        = string

  validation {
    condition     = length(trim(var.project)) > 0
    error_message = "project must be a non-empty string."
  }
}

variable "owner" {
  description = "Owner responsible for the stack (e.g., team or email-alias)."
  type        = string

  validation {
    condition     = length(trim(var.owner)) > 0
    error_message = "owner must be a non-empty string."
  }
}

variable "env" {
  description = "Deployment stage."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], lower(var.env))
    error_message = "env must be one of: dev, staging, prod."
  }
}

variable "cost_center" {
  description = "Cost center or billing code for chargeback."
  type        = string

  validation {
    condition     = length(trim(var.cost_center)) > 0
    error_message = "cost_center must be a non-empty string."
  }
}

variable "ttl" {
  description = "Time-to-live marker (e.g., 30d); used to enforce cleanup."
  type        = string

  validation {
    condition     = length(trim(var.ttl)) > 0
    error_message = "ttl must be a non-empty string."
  }
}

variable "extra_tags" {
  description = "Additional tags to include on all resources."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.extra_tags :
      length(trim(k)) > 0 && length(trim(v)) > 0
    ])
    error_message = "extra_tags keys and values must be non-empty strings."
  }
}
