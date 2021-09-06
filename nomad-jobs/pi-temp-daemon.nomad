job "pi-temp-monitor" {
  datacenters = ["homenet"]
  type        = "system"

  group "temp-monitor" {
    count = 1

    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    ephemeral_disk {
      size = 200
    }

    volume "sys-data" {
      type      = "host"
      read_only = true
      source    = "sys-data"
    }

    task "temp-monitor" {
      driver = "docker"
      
      volume_mount {
        volume      = "sys-data"
        destination = "/sys"
        read_only   = true
      }

      config {
        image = "thundermagic/rpi_cpu_stats:latest"

        port_map {
          export_port = 9669
        }
      }

      resources {
        network {
          port  "export_port"{}
        }
      }

      service {
        name = "temp-exporter"
        port = "export_port"

        check {
          name     = "export_port port alive"
          type     = "http"
          path     = "/metrics"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
