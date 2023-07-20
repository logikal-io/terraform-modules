variable "project_id" {
  description = "The project ID to use"
  type = string
}

variable "role_accesses" {
  description = "A mapping of role names and repositories (as org/repo) they can access"
  type = map(list(string))
}

variable "tags" {
  description = "The tags to use for the roles"
  type = map(string)
  default = null
}
