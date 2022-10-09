output "bucket_name" {
  value = google_storage_bucket.website.name
  description = "The name of Google Cloud storage bucket where the static website files are stored"
}

output "ip" {
  value = google_compute_global_address.website.address
  description = "The global IP address of the static website"
}
