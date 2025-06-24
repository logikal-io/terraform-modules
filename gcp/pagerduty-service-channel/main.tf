terraform {
  required_version = "~> 1.0"
  required_providers {
    pagerduty = {
      source = "pagerduty/pagerduty"
      version = "~> 3.25"
    }
    google = {
      source = "hashicorp/google"
      version = "~> 6.19"
    }
  }
}

# PagerDuty service
resource "pagerduty_service" "this" {
  name = var.name
  auto_resolve_timeout = "null"
  acknowledgement_timeout = 10 * 60 # seconds = 10 minutes
  escalation_policy = var.escalation_policy_id

  incident_urgency_rule {
    type = "constant"
    urgency = "severity_based"
  }
}

resource "pagerduty_event_orchestration_service" "this" {
  service = pagerduty_service.this.id
  enable_event_orchestration_for_service = true
  set {
    id = "start"
    dynamic "rule" {
      for_each = ["Warning", "Error", "Critical"]

      content {
        label = "set-to-${lower(rule.value)}"
        condition {
          expression = "event.custom_details.incident.severity matches '${rule.value}'"
        }
        actions {
          severity = lower(rule.value)
        }
      }
    }
  }
  catch_all {
    actions {}
  }
}

resource "pagerduty_service_integration" "this" {
  name = "Google Cloud Monitoring"
  type = "events_api_v2_inbound_integration"
  service = pagerduty_service.this.id
}

resource "pagerduty_slack_connection" "this" {
  count = var.slack_channel_id != null ? 1 : 0

  source_id = pagerduty_service.this.id
  source_type = "service_reference"
  workspace_id = var.slack_workspace_id
  channel_id = var.slack_channel_id
  notification_type = "responder"
  config {
    events = [
      # All events
      "incident.triggered",
      "incident.acknowledged",
      "incident.escalated",
      "incident.resolved",
      "incident.reassigned",
      "incident.annotated",
      "incident.unacknowledged",
      "incident.delegated",
      "incident.priority_updated",
      "incident.responder.added",
      "incident.responder.replied",
      "incident.status_update_published",
      "incident.reopened"
    ]
    priorities = ["*"]
  }
}

# Google Cloud monitoring notification channel
resource "google_monitoring_notification_channel" "this" {
  display_name = var.name
  type = "pagerduty"
  sensitive_labels {
    service_key = pagerduty_service_integration.this.integration_key
  }
  force_delete = false
}
