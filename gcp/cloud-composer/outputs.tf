output "web_server_url" {
  value = google_composer_environment.this.config.0.airflow_uri
}

output "service_account_email" {
  value = google_service_account.airflow_service.email
}

output "connection_secret_ids" {
  value = {
    for connection in var.connections :
    connection => google_secret_manager_secret.connection[connection].id
  }
}
