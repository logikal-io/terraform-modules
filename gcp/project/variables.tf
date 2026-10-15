variable "organization" {
  type = string
}

variable "billing_account_name" {
  description = "The billing account to use (defaults to the organization ID)"
  type = string
  default = null
}

variable "name" {
  type = string
}

variable "namespace" {
  type = string
  default = null
}

variable "folder_id" {
  description = "The ID of the folder where the project is located"
  type = string
  default = null
}
