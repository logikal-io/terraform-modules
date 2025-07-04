terraform {
  required_version = "~> 1.0"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 6.19"
    }
  }
}

resource "google_storage_bucket" "this" {
  name = "${var.name}-${var.name_suffix}"
  location = var.location
  storage_class = var.storage_class
}

resource "google_storage_bucket_iam_member" "public" {
  count = var.public ? 1 : 0

  bucket = google_storage_bucket.this.name
  role = "roles/storage.objectViewer"
  member = "allUsers"
}
