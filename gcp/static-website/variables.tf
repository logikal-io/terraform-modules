variable "project_id" {
  description = "The project ID to use"
  type = string
}

variable "domain" {
  description = "The static website domain"
  type = string

  validation {
    condition = can(regex("^[a-z0-9.]+$", var.domain))
    error_message = "Only lowercase alphanumeric characters and dots are allowed in domains."
  }
}

variable "uploader_service_account_email" {
  description = "The email address of the website uploader service account"
  type = string
}

variable "bucket_location" {
  description = "The Google Cloud Storage bucket location to use"
  type = string
  default = "EU"
}

variable "bigquery_location" {
  description = "The BigQuery website log data set location to use"
  type = string
  default = "EU"
}

variable "force_cache_all" {
  description = "Whether Google Cloud CDN should cache all successful responses unconditionally"
  type = bool
  default = false
}

variable "redirects" {
  description = "A list of 301 redirects to issue"
  type = list(object({paths = list(string), redirect = string}))
  default = []
}
