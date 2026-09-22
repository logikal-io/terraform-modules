terraform {
  required_version = "~> 1.0"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 7.45"
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

  # DAG storage
  storage_config {
    bucket = module.gcs_airflow_bucket.name
  }

  config {
    # Configuration
    software_config {
      image_version = var.image_version
      pypi_packages = var.pypi_packages
      env_variables = var.env_variables

      airflow_config_overrides = merge({
        api-default_wrap = true
        api-enable_swagger_ui = false
        api-instance_name = var.instance_name
        api-theme = jsonencode(var.ui_theme)
        core-default_task_execution_timeout = 60 * 60 # seconds -> 1 hour
        core-load_examples = false
        core-max_active_runs_per_dag = var.max_active_runs_per_dag
        core-parallelism = var.max_task_instances_per_scheduler
        dag_processor-dag_file_processor_timeout = 30 # seconds
        dag_processor-refresh_interval = 60 # seconds
        secrets-backend = (
          "airflow.providers.google.cloud.secrets.secret_manager.CloudSecretManagerBackend"
        )
        secrets-backend_kwargs = jsonencode({
          connections_prefix = local.connections_prefix
        })
        secrets-backends_order = "metastore,environment_variable,custom"
      }, var.config_overrides)
    }

    maintenance_window {
      start_time = var.maintenance_window_start_time
      end_time = var.maintenance_window_end_time
      recurrence = var.maintenance_window_recurrence
    }

    # Networking
    enable_private_environment = false

    node_config {
      service_account = google_service_account.airflow_service.email
      network = var.network
      subnetwork = var.subnetwork
    }

    web_server_network_access_control {
      dynamic "allowed_ip_range" {
        for_each = var.webserver_allowed_source_ip_ranges

        content {
          value = allowed_ip_range.value
        }
      }
    }

    # Resources
    environment_size = var.environment_size
    resilience_mode = var.resilience_mode

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
      dag_processor {
        cpu = var.dag_processor_cpu
        memory_gb =  var.dag_processor_memory_gb
        storage_gb = var.dag_processor_storage_gb
        count = var.dag_processor_count
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
  }

  depends_on = [
    # Services
    google_project_service.composer,
    # Accesses
    google_storage_bucket_iam_member.airflow_bucket_access_for_airflow,
    google_project_iam_member.composer_worker_access_for_airflow,
  ]
}
