output "project_id" {
  value = var.project_id
}

output "name" {
  value = local.database_instance_name
}

output "connection_name" {
  value = nonsensitive(local.database_instance.connection_name)
}

output "database_name" {
  value = google_sql_database.this.name
}

output "user_passwords" {
  value = {for user in var.users : user => random_password.user[user].result}
}
