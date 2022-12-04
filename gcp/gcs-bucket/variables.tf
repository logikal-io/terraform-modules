variable "name" {
  description = "The name of the bucket"
  type = string
}

variable "suffix" {
  description = "The name suffix to use (typically the project_id)"
  type = string
}

variable "location" {
  description = "The bucket location to use"
  type = string
  default = "EU"
}

variable "storage_class" {
  description = "The storage class to use"
  type = string
  default = "STANDARD"
}

variable "public" {
  description = "Whether the bucket is public"
  type = bool
  default = false
}
