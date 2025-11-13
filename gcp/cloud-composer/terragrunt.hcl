include "commons" {
  path = pathexpand("~/.terragrunt/commons.hcl")
}

terraform {
  before_hook "update_module_source" {
    commands = ["init", "validate"]
    execute = flatten([
      "find", ".", "-path", "*/.terragrunt-cache/*", "-prune", "-o", "-name", "*.tf", "-execdir",
      "sed", "-E", "-i", "s|(source = \")\\.\\./([^.]*)\"|\\1../../../../\\2\"|g", "{}", ";",
    ])
  }
}
