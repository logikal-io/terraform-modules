output "name" {
  value = var.name
}

output "service_account_id" {
  value = one(google_service_account.this[*].id)
}

output "service_account_email" {
  value = local.service_account_email
}

output "image" {
  value = google_cloud_run_v2_job.this.template[0].template[0].containers[0].image
}
