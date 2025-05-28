output "domain" {
  value = var.domain
}

output "name" {
  value = var.name
}

output "url_map_name" {
  value = google_compute_url_map.this.name
}

output "service_account_id" {
  value = google_service_account.this.id
}

output "service_account_email" {
  value = google_service_account.this.email
}

output "ip_address" {
  value = google_compute_global_address.this.address
}

output "image" {
  value = google_cloud_run_v2_service.this.template[0].containers[0].image
}
