terraform {
  required_version = "~> 1.0"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 5.9"
    }
  }
}

# Identity pool provider
resource "google_project_service" "iam" {
  service = "iam.googleapis.com"
}

resource "google_iam_workload_identity_pool" "ci_cd" {
  workload_identity_pool_id = "ci-cd"
  display_name = "CI/CD tasks"

  depends_on = [google_project_service.iam]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id = google_iam_workload_identity_pool.ci_cd.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions"
  display_name = "GitHub Actions"
  attribute_mapping = {
    "google.subject" = "assertion.sub"
    "attribute.actor" = "assertion.actor"
    "attribute.aud" = "assertion.aud"
    "attribute.repository" = "assertion.repository"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Service accounts
resource "google_service_account" "github_actions" {
  for_each = var.service_account_accesses

  account_id = each.key

  depends_on = [google_project_service.iam]
}

resource "google_service_account_iam_binding" "ci_cd" {
  for_each = var.service_account_accesses

  service_account_id = google_service_account.github_actions[each.key].name
  role = "roles/iam.workloadIdentityUser"
  members = [
    for repository in each.value : join("/", [
      "principalSet://iam.googleapis.com",
      google_iam_workload_identity_pool.ci_cd.name,
      "attribute.repository/${repository}",
    ])
  ]
}
