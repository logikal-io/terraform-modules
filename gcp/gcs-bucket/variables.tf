variable "name" {
  type = string
}

variable "name_suffix" {
  description = "The name suffix to use (typically the project_id)"
  type = string
}

variable "location" {
  type = string
  default = "EU"
}

variable "storage_class" {
  type = string
  default = "STANDARD"
}

variable "public" {
  type = bool
  default = false
}
