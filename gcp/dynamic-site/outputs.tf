output "database" {
  value = module.cloud_sql
}

output "service" {
  value = module.cloud_run_service
}
