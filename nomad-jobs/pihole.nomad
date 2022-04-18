job "pihole" {
  # https://github.com/pi-hole/docker-pi-hole
  datacenters = ["homenet"]
  type        = "service"

  constraint {
    distinct_hosts = true
  }

  constraint {
    attribute = "${node.class}"
    value = "controller"
  }

  constraint {
      attribute = "${attr.unique.network.ip-address}"
      value = "192.168.42.247" # Since it's DNS, we have to force the same IP
  }

  group "main" {
    count = 1

    network {
      mode = "bridge"
      port "dns" {
        static = 5353
        to = 53
      }

      port "http" {
        to = 80
      }
    }

    reschedule {
      delay          = "30s"
      delay_function = "constant"
      unlimited      = true
    }

    volume "pihole-data" {
      type      = "host"
      read_only = false
      source    = "pihole-data"
    }

    volume "pihole-dnsmasq" {
      type      = "host"
      read_only = false
      source    = "pihole-dnsmasq"
    }

    task "pihole" {
      driver = "docker"
      volume_mount {
        volume      = "pihole-dnsmasq"
        destination = "/etc/dnsmasq.d"
        read_only   = false
      }

      volume_mount {
        volume      = "pihole-data"
        destination = "/etc/pihole"
        read_only   = false
      }

      config {
        image = "pihole/pihole:latest"
        ports = ["dns", "http"]
        force_pull = true
      }

      env {
        TZ = "Europe/Vienna"
      }
    }

    service {
      name = "pihole"
      port = "http"
    }
  }
}
