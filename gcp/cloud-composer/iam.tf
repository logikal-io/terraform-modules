resource "google_service_account" "airflow_service" {
  account_id = "${var.name}-airflow-service"
}

resource "google_project_iam_member" "composer_worker_access_for_airflow" {
  project = var.project_id
  role = "roles/composer.worker"
  member = "serviceAccount:${google_service_account.airflow_service.email}"
}

resource "google_storage_bucket_iam_member" "airflow_bucket_access_for_airflow" {
  bucket = module.gcs_airflow_bucket.name
  role = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.airflow_service.email}"
}

resource "google_storage_bucket_iam_member" "airflow_bucket_access_for_airflow_publisher" {
  bucket = module.gcs_airflow_bucket.name
  role = "roles/storage.objectUser"
  member = "serviceAccount:${var.publisher_service_account}"
}

resource "google_secret_manager_secret_iam_member" "connection_secret_access_for_airflow" {
  for_each = toset(var.connections)

  project = var.project_id
  secret_id = google_secret_manager_secret.connection[each.key].id
  role = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${google_service_account.airflow_service.email}"
}

resource "google_secret_manager_secret_iam_member" "secret_access_for_airflow" {
  for_each = toset(var.secret_ids)

  project = var.project_id
  secret_id = each.key
  role = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${google_service_account.airflow_service.email}"
}
