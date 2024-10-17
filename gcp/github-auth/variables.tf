variable "github_organization" {
  description = "The GitHub organization to which the authentication should be restricted to"
  type = string
}

variable "service_account_accesses" {
  description = "A mapping of service account names and repositories (as org/repo) they can access"
  type = map(list(string))
}
