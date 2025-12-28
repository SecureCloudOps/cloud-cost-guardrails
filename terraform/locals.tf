locals {
  mandatory_tag_keys = [
    "Project",
    "Owner",
    "Env",
    "CostCenter",
    "TTL",
  ]

  mandatory_tags = merge(
    var.extra_tags,
    {
      Project    = var.project
      Owner      = var.owner
      Env        = lower(var.env)
      CostCenter = var.cost_center
      TTL        = var.ttl
    }
  )

  missing_or_empty_mandatory_tags = [
    for key in local.mandatory_tag_keys : key
    if !contains(local.mandatory_tags, key) || length(trim(local.mandatory_tags[key])) == 0
  ]
}
