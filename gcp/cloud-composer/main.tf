terraform {
  required_version = "~> 1.0"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 6.19"
    }
  }
}

locals {
  connections_prefix = "airflow-${var.name}"
}

resource "google_project_service" "composer" {
  service = "composer.googleapis.com"
}

module "gcs_airflow_bucket" {
  source = "../gcs-bucket"

  name = strcontains(var.project_id, var.name) ? "airflow" : "airflow-${var.name}"
  name_suffix = var.project_id
  location = var.region
}

resource "google_composer_environment" "this" {
  name = var.name
  region = var.region

  storage_config {
    bucket = module.gcs_airflow_bucket.name
  }

  config {
    software_config {
      image_version = var.image_version
      pypi_packages = var.pypi_packages

      airflow_config_overrides = merge({
        core-default_task_execution_timeout = 60 * 60 # seconds -> 1 hour
        core-default_task_retries = 0
        core-dag_file_processor_timeout = 30
        core-max_active_runs_per_dag = var.max_active_runs_per_dag
        core-parallelism = var.max_task_instances_per_scheduler
        secrets-backend = (
          "airflow.providers.google.cloud.secrets.secret_manager.CloudSecretManagerBackend"
        )
        secrets-backend_kwargs = jsonencode({
          connections_prefix = local.connections_prefix
        })
        secrets-backends_order = "metastore,environment_variable,custom"
        scheduler-dag_dir_list_interval = 10 # seconds
        scheduler-catchup_by_default = false
        scheduler-create_cron_data_intervals = false
        scheduler-parsing_cleanup_interval = 10 # seconds
        webserver-default_dag_run_display_number = 50
        webserver-default_wrap = true
        webserver-enable_swagger_ui = false
        webserver-instance_name_has_markup = true
        webserver-instance_name = var.webserver_instance_name
        webserver-navbar_color = var.webserver_navbar_color
        webserver-navbar_hover_color = var.webserver_navbar_hover_color
        webserver-navbar_logo_text_color = var.webserver_navbar_logo_text_color
        webserver-navbar_text_color = var.webserver_navbar_text_color
        webserver-navbar_text_hover_color = var.webserver_navbar_text_hover_color
      }, var.config_overrides)

      env_variables = var.env_variables
    }

    web_server_network_access_control {
      dynamic "allowed_ip_range" {
        for_each = var.webserver_allowed_source_ip_ranges

        content {
          value = allowed_ip_range.value
        }
      }
    }

    enable_private_environment = true

    workloads_config {
      scheduler {
        cpu = var.scheduler_cpu
        memory_gb = var.scheduler_memory_gb
        storage_gb = var.scheduler_storage_gb
        count = var.scheduler_count
      }
      triggerer {
        cpu = var.triggerer_cpu
        memory_gb = var.triggerer_memory_gb
        count = var.triggerer_count
      }
      web_server {
        cpu = var.webserver_cpu
        memory_gb = var.webserver_memory_gb
        storage_gb = var.webserver_storage_gb
      }
      worker {
        cpu = var.worker_cpu
        memory_gb = var.worker_memory_gb
        storage_gb = var.worker_storage_gb
        min_count = var.workers_min
        max_count = var.workers_max
      }
    }

    environment_size = var.environment_size

    maintenance_window {
      start_time = var.maintenance_window_start_time
      end_time = var.maintenance_window_end_time
      recurrence = var.maintenance_window_recurrence
    }

    node_config {
      service_account = google_service_account.airflow_service.email
    }
  }

  depends_on = [
    # Services
    google_project_service.composer,
    # Accesses
    google_storage_bucket_iam_member.airflow_bucket_access_for_airflow,
    google_project_iam_member.composer_worker_access_for_airflow,
  ]
}
