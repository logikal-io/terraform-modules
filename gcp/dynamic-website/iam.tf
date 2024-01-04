# Service account
resource "google_service_account" "website_service" {
  account_id = "${var.name}-website-service"
}

# Secret access
resource "google_secret_manager_secret_iam_member" "secret_access_for_website_service_user" {
  for_each = toset([
    google_secret_manager_secret.website_secret_key.secret_id,
    google_secret_manager_secret.website_database_secrets.secret_id,
  ])

  project = var.project_id
  secret_id = each.key
  role = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${google_service_account.website_service.email}"
}

# Database access
resource "google_project_iam_member" "cloud_sql_access_for_website_service_user" {
  project = var.project_id
  role = "roles/cloudsql.client"
  member = "serviceAccount:${google_service_account.website_service.email}"
  condition {
    title = "website_instance"
    expression = join(" && ", [
      "resource.type == 'sqladmin.googleapis.com/Instance'",
      "resource.name == '${join("/", [
        "projects", var.project_id,
        "instances", google_sql_database_instance.website.name,
      ])}'",
    ])
  }
}

# Public service access
resource "google_cloud_run_v2_service_iam_member" "service_public_access" {
  name = google_cloud_run_v2_service.website.name
  location = google_cloud_run_v2_service.website.location
  role = "roles/run.invoker"
  member = "allUsers"
}

# Artifact repository write access
resource "google_artifact_registry_repository_iam_member" "website_publisher" {
  location = google_artifact_registry_repository.website.location
  repository = google_artifact_registry_repository.website.name
  role = "roles/artifactregistry.writer"
  member = "serviceAccount:${var.publisher_service_account_email}"
}

# Service update access
resource "google_cloud_run_v2_service_iam_member" "service_view_access_for_publisher" {
  name = google_cloud_run_v2_service.website.name
  location = google_cloud_run_v2_service.website.location
  role = "roles/run.viewer"
  member = "serviceAccount:${var.publisher_service_account_email}"
}

resource "google_service_account_iam_member" "website_service_user_access_for_publisher" {
  service_account_id = google_service_account.website_service.name
  role = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${var.publisher_service_account_email}"
}

resource "google_project_iam_custom_role" "service_updater" {
  role_id = "CloudRunServiceUpdater"
  title = "Cloud Run Service Updater"
  description = "Can update a Cloud Run service."
  permissions = ["run.services.update"]
}

resource "google_cloud_run_v2_service_iam_member" "service_update_access_for_publisher" {
  name = google_cloud_run_v2_service.website.name
  location = google_cloud_run_v2_service.website.location
  role = google_project_iam_custom_role.service_updater.id
  member = "serviceAccount:${var.publisher_service_account_email}"
}

# Command job update access
resource "google_project_iam_custom_role" "job_updater" {
  role_id = "CloudRunJobUpdater"
  title = "Cloud Run Job Updater"
  description = "Can update a Cloud Run job."
  permissions = ["run.jobs.update", "run.jobs.runWithOverrides"]
}

resource "google_cloud_run_v2_job_iam_member" "job_update_access_for_publisher" {
  name = google_cloud_run_v2_job.website_command.name
  location = google_cloud_run_v2_job.website_command.location
  role = google_project_iam_custom_role.job_updater.id
  member = "serviceAccount:${var.publisher_service_account_email}"
}

# Command job run access
resource "google_cloud_run_v2_job_iam_member" "job_access_for_publisher" {
  for_each = toset(["roles/run.invoker", "roles/run.viewer"])

  name = google_cloud_run_v2_job.website_command.name
  location = google_cloud_run_v2_job.website_command.location
  role = each.key
  member = "serviceAccount:${var.publisher_service_account_email}"
}
