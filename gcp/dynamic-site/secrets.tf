resource "google_project_service" "secret_manager" {
  service = "secretmanager.googleapis.com"
}

resource "random_password" "secret_key" {
  length = 50
}

locals {
  secrets = merge(
    {"${var.name}-secret-key": random_password.secret_key.result},
    {
      # The jsonencode output has to be post-processed
      # (see https://github.com/hashicorp/terraform/issues/26110)
      for user in concat(["service_${var.name}"], keys(local.database_users)) :
      "${replace(replace(user, "/^service_/", ""), "_", "-")}-database-access" =>
      replace(replace(replace(jsonencode({
        hostname = "/cloudsql/${module.cloud_sql.connection_name}"
        port = 5432
        database = module.cloud_sql.database_name
        username = user
        password = module.cloud_sql.user_passwords[user]
      }), "\\u003c", "<"), "\\u003e", ">"), "\\u0026", "&")
    },
  )
}

resource "google_secret_manager_secret" "secret" {
  for_each = toset(keys(local.secrets))

  secret_id = var.name_suffix != null ? "${each.key}-${var.name_suffix}" : each.key
  replication {
    auto {}
  }

  depends_on = [google_project_service.secret_manager]
}

resource "google_secret_manager_secret_version" "secret" {
  for_each = toset(keys(local.secrets))

  secret = google_secret_manager_secret.secret[each.key].id
  secret_data = local.secrets[each.key]
}
