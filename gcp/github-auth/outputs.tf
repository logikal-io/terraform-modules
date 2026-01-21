output "workload_identity_provider" {
  description = "The full identifier of the GitHub workload identity pool provider"
  value = google_iam_workload_identity_pool_provider.github.name
}

output "service_accounts" {
  value = {
    for service_account in keys(var.service_account_accesses) :
    service_account => google_service_account.github_actions[service_account]
  }
  description = "The service accounts used with GitHub Actions"
}

output "service_account_emails" {
  value = {
    for service_account in keys(var.service_account_accesses) :
    service_account => google_service_account.github_actions[service_account].email
  }
  description = "The email addresses of the Google service accounts used with GitHub Actions"
}
