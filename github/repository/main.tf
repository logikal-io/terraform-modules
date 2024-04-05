terraform {
  required_version = "~> 1.0"
  required_providers {
    github = {
      source = "integrations/github"
      version = "~> 6.2"
    }
  }
}

resource "github_repository" "this" {
  name = var.name
  description = var.description
  homepage_url = var.homepage
  visibility = var.visibility
  has_issues = true
  has_projects = false
  has_wiki = false
  allow_squash_merge = false
  allow_rebase_merge = false
  allow_auto_merge = false
  merge_commit_title = "MERGE_MESSAGE"
  merge_commit_message = "PR_TITLE"
  delete_branch_on_merge = true
  auto_init = true
  archived = var.archived
  archive_on_destroy = true
  topics = var.topics
  vulnerability_alerts = !var.archived
}

resource "github_branch_default" "main" {
  repository = github_repository.this.name
  branch = "main"
}

# We are using github_branch_protection_v3 because restrictions aren't applied properly otherwise
# (see https://github.com/integrations/terraform-provider-github/issues/670)
resource "github_branch_protection_v3" "main" {
  repository = github_repository.this.name
  branch = github_branch_default.main.branch

  require_signed_commits = true
  require_conversation_resolution = true

  restrictions {}

  required_pull_request_reviews {
    dismiss_stale_reviews = true
    required_approving_review_count = 1
  }

  dynamic "required_status_checks" {
    for_each = length(var.status_checks) > 0 ? toset([var.status_checks]) : []

    content {
      # Note: "contexts" is deprecated but "checks" isn't working properly either
      # (see https://github.com/integrations/terraform-provider-github/issues/1657)
      contexts = required_status_checks.value
      strict = true
    }
  }
}

resource "github_branch_protection" "all" {
  repository_id = github_repository.this.node_id
  pattern = "*"

  require_signed_commits = true
  allows_deletions = true
}
