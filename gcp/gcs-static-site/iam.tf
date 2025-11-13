# Bucket access
resource "google_storage_bucket_iam_member" "bucket_view_access_for_publisher" {
  bucket = google_storage_bucket.this.name
  role = "roles/storage.bucketViewer"
  member = "serviceAccount:${var.publisher_service_account_email}"
}

resource "google_storage_bucket_iam_member" "storage_object_access_for_publisher" {
  bucket = google_storage_bucket.this.name
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.publisher_service_account_email}"
}

# CDN invalidation access
resource "google_project_iam_custom_role" "cdn_invalidator" {
  role_id = "CDNInvalidator"
  title = "CDN Invalidator"
  permissions = ["compute.urlMaps.get", "compute.urlMaps.invalidateCache"]
}

resource "google_project_iam_member" "cdn_invalidation_access_for_publisher" {
  project = var.project_id
  role = google_project_iam_custom_role.cdn_invalidator.id
  member = "serviceAccount:${var.publisher_service_account_email}"
}

# BigQuery access
resource "google_bigquery_dataset_iam_binding" "log_writer" {
  dataset_id = google_bigquery_dataset.this.dataset_id
  role = "roles/bigquery.dataEditor"
  members = [google_logging_project_sink.this.writer_identity]
}
