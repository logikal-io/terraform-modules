variable "service_account_accesses" {
  description = "A mapping of service account names and repositories (as org/repo) they can access"
  type = map(list(string))
}
