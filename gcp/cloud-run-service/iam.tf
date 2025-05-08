# Service accounts
resource "google_service_account" "service" {
  account_id = "${var.name}-service"
}

# Public service access
resource "google_cloud_run_v2_service_iam_member" "service_public_access" {
  name = google_cloud_run_v2_service.service.name
  location = google_cloud_run_v2_service.service.location
  role = "roles/run.invoker"
  member = "allUsers"
}

# Service update access
resource "google_cloud_run_v2_service_iam_member" "service_view_access_for_app_publisher" {
  name = google_cloud_run_v2_service.service.name
  location = google_cloud_run_v2_service.service.location
  role = "roles/run.viewer"
  member = var.publisher_service_account
}

resource "google_service_account_iam_member" "app_service_user_access_for_app_publisher" {
  service_account_id = google_service_account.service.name
  role = "roles/iam.serviceAccountUser"
  member = var.publisher_service_account
}

resource "google_project_iam_custom_role" "service_updater" {
  role_id = "CloudRunServiceUpdater"
  title = "Cloud Run Service Updater"
  description = "Can update a Cloud Run service."
  permissions = ["run.services.update"]
}

resource "google_cloud_run_v2_service_iam_member" "service_update_access_for_app_publisher" {
  name = google_cloud_run_v2_service.service.name
  location = google_cloud_run_v2_service.service.location
  role = google_project_iam_custom_role.service_updater.id
  member = var.publisher_service_account
}

# Logging access
resource "google_project_iam_member" "logging_access_for_service_user" {
  project = var.project_id
  role = "roles/logging.logWriter"
  member = "serviceAccount:${google_service_account.service.email}"
}
