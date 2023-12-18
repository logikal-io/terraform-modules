output "bucket_name" {
  value = google_storage_bucket.website.name
  description = "The name of Google Cloud storage bucket where the static website files are stored"
}

output "ip" {
  value = google_compute_global_address.website.address
  description = "The global IP address of the static website"
}

output "domain" {
  value = var.domain
  description = "The domain of the static website"
}

output "website_service_url_map" {
  value = google_compute_url_map.website_service.name
  description = "The URL map (load balancer) name used for serving the website files"
}

output "https_redirect_url_map" {
  value = google_compute_url_map.https_redirect.name
  description = "The URL map (load balancer) name used for redirecting HTTP traffic to HTTPS"
}
