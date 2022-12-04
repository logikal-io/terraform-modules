output "name" {
  value = google_storage_bucket.this.name
  description = "The name of the Google Cloud storage bucket"
}

output "url" {
  value = google_storage_bucket.this.url
  description = "The base URL of the bucket"
}
