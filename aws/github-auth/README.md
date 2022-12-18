# Amazon Web Services GitHub Authentication Terraform Module

Note that the [GitHub OpenID connect
provider](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
must be already set up before this module can be used.

This module creates a set of roles that can be used from GitHub Actions running in specific
repositories.

Once the infrastructure has been provisioned you can simply use the [official Amazon Web Services
credentials](https://github.com/aws-actions/configure-aws-credentials) GitHub Action with the
provided module outputs to authenticate to Amazon Web Services.
