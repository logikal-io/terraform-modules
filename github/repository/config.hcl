include "config" {
  path = find_in_parent_folders("config.hcl")
  expose = true
}

locals {
  config = include.config
}
