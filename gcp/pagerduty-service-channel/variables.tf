variable "name" {
  type = string
}

variable "escalation_policy_id" {
  type = string
}

variable "slack_workspace_id" {
  type = string
  default = null
}

variable "slack_channel_id" {
  type = string
  default = null
}
