variable "name" {
  description = "The name of the bucket"
  type = string
}

variable "suffix" {
  description = "The name suffix to use (typically the organization_id)"
  type = string
}

variable "public" {
  description = "Whether the bucket is public"
  type = bool
  default = false
}
