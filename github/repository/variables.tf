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

variable "visibility" {
  description = "The visibility of the repository (either 'private' or 'public')"
  type = string
  default = "private"
}
