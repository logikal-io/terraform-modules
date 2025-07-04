# Service accounts
resource "google_service_account" "this" {
  account_id = "${var.name}-service"
}

# Artifact repository write access
resource "google_artifact_registry_repository_iam_member" "publisher" {
  count = var.image == null && var.publisher_service_account_email != null ? 1 : 0

  location = one(google_artifact_registry_repository.this[*].location)
  repository = one(google_artifact_registry_repository.this[*].name)
  role = "roles/artifactregistry.writer"
  member = "serviceAccount:${var.publisher_service_account_email}"
}

# Public service access
resource "google_cloud_run_v2_service_iam_member" "service_public_access" {
  name = google_cloud_run_v2_service.this.name
  location = google_cloud_run_v2_service.this.location
  role = "roles/run.invoker"
  member = "allUsers"
}

# Service update access
resource "google_cloud_run_v2_service_iam_member" "service_update_access_for_publisher" {
  count = var.publisher_service_account_email != null ? 1 : 0

  name = google_cloud_run_v2_service.this.name
  location = google_cloud_run_v2_service.this.location
  role = "roles/run.developer"
  member = "serviceAccount:${var.publisher_service_account_email}"
}

resource "google_service_account_iam_member" "service_user_access_for_publisher" {
  count = var.publisher_service_account_email != null ? 1 : 0

  service_account_id = google_service_account.this.id
  role = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${var.publisher_service_account_email}"
}

# Logging access
resource "google_project_iam_member" "logging_access_for_service_user" {
  project = var.project_id
  role = "roles/logging.logWriter"
  member = "serviceAccount:${google_service_account.this.email}"
}

# Secret access
resource "google_secret_manager_secret_iam_member" "secret_access_for_service_user" {
  for_each = toset(concat(values(var.env_secrets), var.secret_ids))

  project = var.project_id
  secret_id = each.key
  role = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${google_service_account.this.email}"
}

# Database access
# See https://cloud.google.com/sql/docs/mysql/iam-conditions (under section "specific instances")
resource "google_project_iam_member" "cloud_sql_access_for_service_account" {
  for_each = toset([for instance in var.cloud_sql_instances : instance.name])

  project = var.project_id
  role = "roles/cloudsql.client"
  member = "serviceAccount:${google_service_account.this.email}"
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
