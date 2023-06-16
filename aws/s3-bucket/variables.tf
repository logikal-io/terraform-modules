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

variable "expire_days" {
  description = "The number of days after which objects should be deleted in the bucket"
  type = number
  default = null
}

variable "versioning" {
  description = "Whether the bucket is versioning-enabled"
  type = bool
  default = false
}

variable "mfa_delete" {
  description = "Whether MFA delete is enabled in the bucket versioning configuration"
  type = bool
  default = false
}
