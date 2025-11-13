locals {
  log_id = "${local.website_id}-logs"
}

resource "google_project_service" "logging" {
  service = "logging.googleapis.com"
}

resource "google_project_service" "bigquery" {
  service = "bigquery.googleapis.com"
}

resource "google_bigquery_dataset" "this" {
  dataset_id = replace(local.log_id, "-", "_")
  location = var.bigquery_location
  delete_contents_on_destroy = false
  max_time_travel_hours = 48

  depends_on = [google_project_service.bigquery]
}

resource "google_logging_project_sink" "this" {
  name = local.log_id
  destination = "bigquery.googleapis.com/${google_bigquery_dataset.this.id}"
  filter = join(" AND ", [
    "resource.type = http_load_balancer",
    join(" = ", [
      "resource.labels.forwarding_rule_name",
      google_compute_global_forwarding_rule.service_https.name,
    ]),
  ])

  unique_writer_identity = true

  bigquery_options {
    use_partitioned_tables = true
  }

  depends_on = [google_project_service.logging]
}
