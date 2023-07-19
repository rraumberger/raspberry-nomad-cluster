job "jetbrains-youtrack" {
  datacenters = ["homenet"]
  type        = "service"

  constraint {
    distinct_hosts = true
  }

  constraint {
    attribute = "${node.class}"
    value = "computing"
  }

  constraint {
    attribute = "${attr.cpu.arch}"
    value = "amd64"
  }

  group "youtrack" {
    count = 1

    network {
      mode = "bridge"
      port "http" {
        to = 8080
      }
    }

    volume "youtrack-data" {
      type      = "host"
      read_only = false
      source    = "youtrack-data"
    }

    volume "youtrack-logs" {
      type      = "host"
      read_only = false
      source    = "youtrack-logs"
    }

    volume "youtrack-conf" {
      type      = "host"
      read_only = false
      source    = "youtrack-conf"
    }

    volume "youtrack-backups" {
      type      = "host"
      read_only = false
      source    = "youtrack-backups"
    }

    reschedule {
      delay          = "30s"
      delay_function = "constant"
      unlimited      = true
    }

    task "server-instance" {
      driver = "docker"

      resources {
        memory = 4096
      }

      volume_mount {
        volume      = "youtrack-data"
        destination = "/opt/youtrack/data"
        read_only   = false
      }

      volume_mount {
        volume      = "youtrack-logs"
        destination = "/opt/youtrack/logs"
        read_only   = false
      }

      volume_mount {
        volume      = "youtrack-conf"
        destination = "/opt/youtrack/conf"
        read_only   = false
      }

      volume_mount {
        volume      = "youtrack-backups"
        destination = "/opt/youtrack/backups"
        read_only   = false
      }

      config {
        image = "jetbrains/youtrack:2023.1.16597"
      }
    }

    service {
      name = "youtrack"
      port = "http"
    }
  }
}
