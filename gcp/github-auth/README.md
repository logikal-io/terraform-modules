# Google Cloud Platform GitHub Authentication Terraform Module

This module sets up GitHub Actions as a workload pool identity provider and creates a set of
service accounts that can be used from GitHub Actions running in specific repositories.

Once the infrastructure has been provisioned you can simply use the [official Google Cloud
auth](https://github.com/google-github-actions/auth) GitHub Action with the provided module outputs
to authenticate to Google Cloud.
