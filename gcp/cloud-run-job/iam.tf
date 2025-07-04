# Service accounts
resource "google_service_account" "this" {
  count = var.service_account_email == null ? 1 : 0

  account_id = "${var.name}-job"
}

locals {
  service_account_email = coalesce(
    var.service_account_email,
    one(google_service_account.this[*].email,
  ))
}

# Artifact repository write access
resource "google_artifact_registry_repository_iam_member" "publisher" {
  count = var.image == null && var.publisher_service_account_email != null ? 1 : 0

  location = one(google_artifact_registry_repository.this[*].location)
  repository = one(google_artifact_registry_repository.this[*].name)
  role = "roles/artifactregistry.writer"
  member = "serviceAccount:${var.publisher_service_account_email}"
}

# Job update access
resource "google_cloud_run_v2_job_iam_member" "job_update_access_for_publisher" {
  count = var.publisher_service_account_email != null ? 1 : 0

  name = google_cloud_run_v2_job.this.name
  location = google_cloud_run_v2_job.this.location
  role = "roles/run.developer"
  member = "serviceAccount:${var.publisher_service_account_email}"
}

resource "google_service_account_iam_member" "service_user_access_for_publisher" {
  count = var.publisher_service_account_email != null && var.service_account_email == null ? 1 : 0

  service_account_id = one(google_service_account.this[*].id)
  role = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${var.publisher_service_account_email}"
}


# Logging access
resource "google_project_iam_member" "logging_access_for_service_user" {
  count = var.service_account_email == null ? 1 : 0

  project = var.project_id
  role = "roles/logging.logWriter"
  member = "serviceAccount:${one(google_service_account.this[*].email)}"
}

# Secret access
resource "google_secret_manager_secret_iam_member" "secret_access_for_service_user" {
  for_each = toset(
    var.service_account_email == null ? concat(values(var.env_secrets), var.secret_ids) : []
  )

  project = var.project_id
  secret_id = each.key
  role = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${one(google_service_account.this[*].email)}"
}

# Database access
# See https://cloud.google.com/sql/docs/mysql/iam-conditions (under section "specific instances")
resource "google_project_iam_member" "cloud_sql_access_for_service_account" {
  for_each = toset(
    var.service_account_email == null ?
    [for instance in var.cloud_sql_instances : instance.name] : []
  )

  project = var.project_id
  role = "roles/cloudsql.client"
  member = "serviceAccount:${one(google_service_account.this[*].email)}"
  condition {
    title = "instance-${each.key}"
    expression = join(" && ", [
      "resource.type == 'sqladmin.googleapis.com/Instance'",
      "resource.name == '${join("/", [
        "projects", var.project_id,
        "instances", each.key,
      ])}'",
    ])
  }
}
