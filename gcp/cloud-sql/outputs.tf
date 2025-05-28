output "name" {
  value = google_sql_database_instance.this.name
}

output "connection_name" {
  value = google_sql_database_instance.this.connection_name
}

output "database" {
  value = google_sql_database.this.name
}

output "user_passwords" {
  value = {for user in var.users : user => random_password.user[user].result}
}
