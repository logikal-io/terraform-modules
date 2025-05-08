output "domain" {
  value = var.domain
  description = "The domain of the Cloud Run service"
}

output "name" {
  value = var.name
  description = "The name of the service"
}

output "url_map_name" {
  value = google_compute_url_map.service.name
  description = "The name of the compute URL map"
}

output "service_account" {
  value = google_service_account.service.email
  description = "The service account email"
}

output "ip_address" {
  value = google_compute_global_address.service.address
  description = "The IP address of the service"
}
