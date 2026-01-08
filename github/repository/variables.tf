variable "name" {
  description = "The name of the repository"
  type = string

  validation {
    condition = can(regex("^[a-z0-9-]+$", var.name))
    error_message = "Only lowercase alphanumeric characters and hyphens are allowed in names."
  }
}

variable "description" {
  description = "The description of the repository"
  type = string
}

variable "topics" {
  description = "The repository topics"
  type = list(string)
}

variable "homepage" {
  description = "The URL of the project's homepage"
  type = string
  default = ""
}

variable "status_checks" {
  description = "The name of the status checks that must pass before merging"
  type = list(string)
  default = []
}

variable "enforce_checks_for_admins" {
  description = "Whether to enforce checks for repository administrators too"
  type = bool
  default = true
}

variable "vulnerability_alerts" {
  description = "Whether to enable vulnerability alerts"
  type = bool
  default = null # defaults to not var.archived
}

variable "visibility" {
  description = "The visibility of the repository (either 'private' or 'public')"
  type = string
  default = "private"
}

variable "archived" {
  description = "Whether the repository is archived"
  type = bool
  default = false
}
