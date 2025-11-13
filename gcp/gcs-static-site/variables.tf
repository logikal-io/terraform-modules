variable "project_id" {
  type = string
}

variable "domain_project_id" {
  type = string
  default = null # defaults to project_id
}

variable "domain_managed_zone_name" {
  type = string
  default = null # defaults to replace(var.domain, ".", "-")
}

variable "domain" {
  type = string

  validation {
    condition = can(regex("^[a-z0-9-.]+$", var.domain))
    error_message = (
      "Only lowercase alphanumeric characters, dashes and dots are allowed in domains."
    )
  }
}

variable "www_redirect" {
  type = bool
  default = false
}

variable "publisher_service_account_email" {
  type = string
}

variable "bucket_location" {
  type = string
  default = "EU"
}

variable "bigquery_location" {
  type = string
  default = "EU"
}

variable "force_cache_all" {
  description = "Whether Google Cloud CDN should cache all successful responses unconditionally"
  type = bool
  default = false
}

variable "redirects" {
  description = "A list of HTTP 301 redirects to issue"
  type = list(object({paths = list(string), redirect = string}))
  default = []
}
