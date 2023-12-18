terraform {
  required_version = "~> 1.0"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 5.9"
    }
  }
}

resource "google_storage_bucket" "this" {
  name = "${var.name}-${var.suffix}"
  location = var.location
  storage_class = var.storage_class

  uniform_bucket_level_access = var.public
}

resource "google_storage_bucket_iam_member" "public" {
  count = var.public ? 1 : 0

  bucket = google_storage_bucket.this.name
  role = "roles/storage.objectViewer"
  member = "allUsers"
}
