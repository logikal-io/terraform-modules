terraform {
  required_version = "~> 1.0"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 6.19"
    }
  }
}

data "google_billing_account" "this" {
  display_name = coalesce(var.billing_account_name, var.organization)
}

locals {
  name_id = lower(replace(var.name, "/[ .]/", "-"))
  organization_id = replace(var.organization, ".", "-")
}

resource "google_project" "this" {
  name = var.name
  project_id = join("-", compact([local.name_id, var.namespace, local.organization_id]))
  folder_id = var.folder_id
  billing_account = data.google_billing_account.this.id
}
