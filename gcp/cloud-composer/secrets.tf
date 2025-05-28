resource "google_project_service" "secret_manager" {
  service = "secretmanager.googleapis.com"
}

resource "google_secret_manager_secret" "connection" {
  for_each = toset(var.connections)

  secret_id = "${local.connections_prefix}-${each.key}"
  replication {
    auto {}
  }

  depends_on = [google_project_service.secret_manager]
}
