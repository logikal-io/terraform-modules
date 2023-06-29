# Generated by Terragrunt. Sig: nIlQXj57tbuaRZEa
config {
  module = true
}
plugin "terraform" {
  enabled = true
  preset = "all"
}
plugin "google" {
  enabled = true
  version = "0.24.0"
  source = "github.com/terraform-linters/tflint-ruleset-google"
}
plugin "aws" {
  enabled = true
  version = "0.23.1"
  source = "github.com/terraform-linters/tflint-ruleset-aws"
}
