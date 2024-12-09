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

resource "github_branch_protection" "main" {
  repository_id = github_repository.this.name
  pattern = github_branch_default.main.branch

  enforce_admins = var.enforce_checks_for_admins
  require_signed_commits = true
  require_conversation_resolution = true

  required_pull_request_reviews {
    dismiss_stale_reviews = true
    required_approving_review_count = 1
    require_last_push_approval = true
    require_code_owner_reviews = true
  }

  restrict_pushes {
    blocks_creations = true
  }

  dynamic "required_status_checks" {
    for_each = length(var.status_checks) > 0 ? toset([var.status_checks]) : []

    content {
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
