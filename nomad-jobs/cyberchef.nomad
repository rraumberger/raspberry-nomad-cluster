job "cyberchef" {
  datacenters = ["homenet"]
  type        = "service"

  constraint {
    attribute = "${node.class}"
    value = "storage"
  }

  group "cyberchef" {
    count = 1

    network {
      mode = "bridge"
      port "http" {
        to = 8080
      }
    }

    task "cyberchef" {
      driver = "docker"

      config {
        image = "registry.lab.raumberger.net/cyberchef:v9.32.3"
      }
    }

    service {
      name = "cyberchef"
      port = "http"
    }
  }
}
