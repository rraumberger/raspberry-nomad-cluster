job "github-runner" {
  datacenters = ["homenet"]
  type        = "service"

  constraint {
    distinct_hosts = true
  }

  constraint {
    attribute = "${node.class}"
    value = "computing"
  }



  group "github-runner" {
    reschedule {
      delay          = "30s"
      delay_function = "constant"
      unlimited      = true
    }

    ephemeral_disk {
      size    = 500
    }

    task "github-runner" {
      driver = "exec"

      env {
        GITHUB_URL=""
        GITHUB_TOKEN=""

      }

      config {
        command = "/bin/sh"
        args    = ["-c", "cd alloc/data && ./config.sh --unattended --url URLHERE --token TOKENHERE --replace --name homelab-runner && ./run.sh && sleep 5;"]
      }

      artifact {
        source = ""
        destination = "alloc/data"
      }

      resources {
        cpu    = 2000
        memory = 1492
      }
    }
  }
}