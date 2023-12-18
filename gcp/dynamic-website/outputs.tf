output "ip" {
  value = google_compute_global_address.website.address
  description = "The IP address of the dynamic website"
}

output "domain" {
  value = var.domain
  description = "The domain of the dynamic website"
}
