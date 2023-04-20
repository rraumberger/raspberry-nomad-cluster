job "github-runner" {
  datacenters = ["homenet"]
  type        = "service"

  constraint {
    attribute = "${node.class}"
    value = "computing"
  }

  group "org" {
    count = 1

    reschedule {
      delay          = "30s"
      delay_function = "constant"
      unlimited      = true
    }

    ephemeral_disk {
      size = 5000
    }

    task "runner" {
      driver = "docker"

      config {
        image = "myoung34/github-runner"
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock",
          "/usr/bin/nomad:/usr/bin/nomad"
        ]
      }

      env {
        RUNNER_SCOPE = "org"
        RUNNER_NAME_PREFIX = "rpi-org-runner"
        ORG_NAME = "raumbear"
        LABELS = "homelab,linux,arm64,rpi"
        EPHEMERAL = "false"
      }

      vault {
        policies = ["homelab"]
      }

      template {
        data = <<EOF
ACCESS_TOKEN="{{with secret "homelab/data/github"}}{{.Data.data.ORGANIZATION_ACCESS_TOKEN}}{{end}}"
EOF
        destination   = "secrets/org.env"
        env = true
      }
    }
  }

  group "spot" {
    count = 1

    reschedule {
      delay          = "30s"
      delay_function = "constant"
      unlimited      = true
    }

    ephemeral_disk {
      size = 5000
    }

    task "runner" {
      driver = "docker"

      config {
        image = "myoung34/github-runner"
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock",
          "/usr/bin/nomad:/usr/bin/nomad"
        ]
      }

      env {
        RUNNER_SCOPE = "repo"
        RUNNER_NAME_PREFIX = "rpi-repo-runner"
        REPO_URL="https://github.com/rraumberger/seat-reserver"
        LABELS = "homelab,linux,arm64,rpi"
        EPHEMERAL = "false"
      }

      vault {
        policies = ["homelab"]
      }

      template {
        data = <<EOF
ACCESS_TOKEN="{{with secret "homelab/data/github"}}{{.Data.data.PERSONAL_ACCESS_TOKEN}}{{end}}"
EOF
        destination   = "secrets/spot.env"
        env = true
      }
    }
  }
}
