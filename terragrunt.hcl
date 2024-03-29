# Note: we had to inline linting from terragrunt-commons/commons.hcl here because nested includes
# are not supported in Terragrunt yet (see https://github.com/gruntwork-io/terragrunt/issues/1566)
terraform {
  before_hook "validate" {
    commands = ["validate"]
    execute = ["true"]
  }

  after_hook "tflint_init" {
    commands = ["validate"]
    execute = ["tflint", "--init"]
  }

  after_hook "tflint" {
    commands = ["validate"]
    execute = ["tflint", "--color"]
  }
}

generate "tflint_configuration" {
  path = ".tflint.hcl"
  if_exists = "overwrite"
  contents = <<-EOT
    config {
      module = true
    }
    plugin "terraform" {
      enabled = true
      version = "0.5.0"
      source = "github.com/terraform-linters/tflint-ruleset-terraform"
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
  EOT
}
