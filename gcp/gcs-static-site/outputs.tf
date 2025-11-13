output "domain" {
  value = var.domain
}

output "bucket_name" {
  value = google_storage_bucket.this.name
}

output "url_map_name" {
  value = google_compute_url_map.this.name
}

output "http_to_https_url_map_name" {
  value = google_compute_url_map.http_to_https.name
}

output "ip_address" {
  value = google_compute_global_address.this.address
}
