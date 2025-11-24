resource "google_secret_manager_secret_iam_member" "database_secret_access_for_user" {
  for_each = local.database_users

  project = var.project_id
  secret_id = google_secret_manager_secret.secret[
    "${replace(each.key, "_", "-")}-database-access"
  ].secret_id
  role = "roles/secretmanager.secretAccessor"
  member = "user:${each.value}"
}
