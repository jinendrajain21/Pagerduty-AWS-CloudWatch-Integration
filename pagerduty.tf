provider "aws" {
  region = "us-east-1"
}
terraform {
  required_providers {
    pagerduty = {
      source  = "PagerDuty/pagerduty"
      version = "1.11.0"
    }
  }
}
provider "pagerduty" {
  token = var.pager-token
}

####Create Pagerduty Service #######
resource "pagerduty_service" "pager-service" {
  name                    = "My web app"
  auto_resolve_timeout    = 14400
  acknowledgement_timeout = 600
  escalation_policy       = pagerduty_escalation_policy.Priority-High-esc-policy.id
  alert_creation          = "create_incidents"
  incident_urgency_rule {
    type    = "constant"
    urgency = "high"
  }
}

data "pagerduty_vendor" "newrelic" {
  name = "New Relic"
}

resource "pagerduty_service_integration" "newrelic" {
  name    = data.pagerduty_vendor.newrelic.name
  service = pagerduty_service.pager-service.id
  vendor  = data.pagerduty_vendor.newrelic.id

}

data "pagerduty_vendor" "cloudwatch" {
  name = "Cloudwatch"
}
resource "pagerduty_service_integration" "cloudwatch" {
  name    = data.pagerduty_vendor.cloudwatch.name
  service = pagerduty_service.pager-service.id
  vendor  = data.pagerduty_vendor.cloudwatch.id
}
#############USERS########
resource "pagerduty_user" "Jinendra" {
  name      = "Jinendra"
  email     = "aircjj@gmail.com"
  color     = "green"
  role      = "observer"
  job_title = "Soldier"
  teams     = ["${pagerduty_team.devops.id}"]
}

resource "pagerduty_user" "rupesh" {
  name      = "Rupesh"
  email     = "rupesh@gmail.com"
  color     = "red"
  role      = "observer"
  job_title = "Leader"
  teams     = ["${pagerduty_team.devops.id}", "${pagerduty_team.architect.id}"]
}


resource "pagerduty_user" "jack" {
  name      = "jack"
  email     = "jack123@gmail.com"
  color     = "blue"
  role      = "admin"
  job_title = "Head"
  teams     = ["${pagerduty_team.architect.id}"]
}
#########################TEAMS###################


resource "pagerduty_team" "devops" {
  name = "Devops"
}

resource "pagerduty_team" "architect" {
  name = "Architect"
}

###############Membership###########
resource "pagerduty_team_membership" "devops" {
  user_id = pagerduty_user.Jinendra.id
  team_id = pagerduty_team.devops.id
  role    = "observer"
}

resource "pagerduty_team_membership" "architect" {
  user_id = pagerduty_user.jack.id
  team_id = pagerduty_team.architect.id
  role    = "manager"
}
##############Pagerduty Schedule############
resource "pagerduty_schedule" "PAGER1-schedule" {
  name      = "On-call - Pager1"
  time_zone = "America/New_York"
  layer {
    name                         = "Layer 1"
    rotation_turn_length_seconds = 604800
    start                        = "2021-10-01T12:00:00-04:00"
    rotation_virtual_start       = "2021-10-01T12:00:00-04:00"
    users                        = ["${pagerduty_user.Jinendra.id}", "${pagerduty_user.rupesh.id}"]
  }
}

resource "pagerduty_schedule" "PAGER2-schedule" {
  name      = "On-call - Pager2"
  time_zone = "America/New_York"
  layer {
    name                         = "Layer 1"
    rotation_turn_length_seconds = 604800
    start                        = "2021-10-01T12:00:00-04:00"
    rotation_virtual_start       = "2021-10-01T12:00:00-04:00"
    users                        = ["${pagerduty_user.jack.id}"]
  }
}

###########EscaltionPolicy###################
resource "pagerduty_escalation_policy" "Priority-High-esc-policy" {
  name      = "Autobots Policy"
  num_loops = 5

  rule {
    escalation_delay_in_minutes = 15
    target {
      type = "schedule_reference"
      id   = pagerduty_schedule.PAGER1-schedule.id
    }
  }
  rule {
    escalation_delay_in_minutes = 15
    target {
      type = "user_reference"
      id   = pagerduty_user.Jinendra.id
    }
  }
}

resource "pagerduty_escalation_policy" "Priority-Low-esc-policy" {
  name      = "Decepticons Policy"
  num_loops = 5

  rule {
    escalation_delay_in_minutes = 15
    target {
      type = "schedule_reference"
      id   = pagerduty_schedule.PAGER2-schedule.id
    }
  }
  rule {
    escalation_delay_in_minutes = 15
    target {
      type = "user_reference"
      id   = pagerduty_user.jack.id
    }
  }
}