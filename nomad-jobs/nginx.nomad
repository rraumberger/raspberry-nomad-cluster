job "raumberger.dev" {
  datacenters = ["homenet"]
  type        = "service"

  constraint {
    distinct_hosts = true
  }

  constraint {
    attribute = "${node.class}"
    value = "storage"
  }

  group "web" {
    count = 2

    network {
      mode = "bridge"
      port "http" {
        to = 80
      }
    }

    reschedule {
      delay          = "30s"
      delay_function = "constant"
      unlimited      = true
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx"
      }
    }

    service {
      name = "raumbergerDev"
      port = "http"
    }
  }
}
