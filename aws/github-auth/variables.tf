variable "project_id" {
  description = "The project ID to use"
  type = string
}

variable "role_accesses" {
  description = "A mapping of role names and repositories (as org/repo) they can access"
  type = map(list(string))
}
