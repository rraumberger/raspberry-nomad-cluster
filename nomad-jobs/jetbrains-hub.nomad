job "jetbrains-hub" {
  datacenters = ["homenet"]
  type        = "service"

  constraint {
    attribute = "${node.class}"
    value = "computing"
  }

  constraint {
    attribute = "${attr.cpu.arch}"
    value = "amd64"
  }

  group "hub" {
    count = 1

    network {
      mode = "bridge"
      port "http" {
        to = 8080
      }
    }

    volume "hub-data" {
      type      = "host"
      read_only = false
      source    = "hub-data"
    }

    volume "hub-logs" {
      type      = "host"
      read_only = false
      source    = "hub-logs"
    }

    volume "hub-conf" {
      type      = "host"
      read_only = false
      source    = "hub-conf"
    }

    volume "hub-backups" {
      type      = "host"
      read_only = false
      source    = "hub-backups"
    }

    reschedule {
      delay          = "30s"
      delay_function = "constant"
      unlimited      = true
    }

    task "server-instance" {
      driver = "docker"

      resources {
        memory = 2048
      }

      volume_mount {
        volume      = "hub-data"
        destination = "/opt/hub/data"
        read_only   = false
      }

      volume_mount {
        volume      = "hub-logs"
        destination = "/opt/hub/logs"
        read_only   = false
      }

      volume_mount {
        volume      = "hub-conf"
        destination = "/opt/hub/conf"
        read_only   = false
      }

      volume_mount {
        volume      = "hub-backups"
        destination = "/opt/hub/backups"
        read_only   = false
      }

      config {
        image = "jetbrains/hub:2023.1.16479"
      }
    }

    service {
      name = "hub"
      port = "http"
    }
  }
}
