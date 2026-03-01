variable "name" {
  type = string
}

variable "name_suffix" {
  description = "The name suffix to use (typically the organization_id)"
  type = string
}

variable "public" {
  type = bool
  default = false
}

variable "expire_days" {
  type = number
  default = null
}

variable "versioning" {
  type = bool
  default = false
}

variable "tags" {
  type = map(string)
  default = null
}
