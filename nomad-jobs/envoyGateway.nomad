job "envoy-gateway" {

  datacenters = ["homenet"]

  constraint {
    distinct_hosts = true
  }

  constraint {
    attribute = "${node.class}"
    value = "controller"
  }

  group "ingress-group" {
    count = 2

    network {
      mode = "bridge"
      port "https" {
        static = 443
        to     = 8443
      }
      port "http" {
        static = 80
        to     = 8080
      }
    }

    service {
      name = "envoy-ingress-service"
      port = "8080"

      connect {
        gateway {
          proxy {}
          ingress {
            listener {
              port     = 8080
              protocol = "http"
              service {
                name = "docker-registry"
                hosts = ["registry.lab.raumberger.net"]
              }
              service {
                name = "pihole"
                hosts = ["pihole.lab.raumberger.net"]
              }
            }
          }
        }
      }
    }
  }
}