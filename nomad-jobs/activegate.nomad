job "dynatrace-activegate" {
  datacenters = ["homenet"]
  type        = "service"

  constraint {
    distinct_hosts = true
  }

  constraint {
    attribute = "${node.class}"
    value = "controller"
  }

  group "activegate" {
    count = 1

    network {
      mode = "bridge"
      port "https" {
        static = 9999
        to = 9999
      }
    }

    task "activegate" {
      driver = "docker"

      config {
        image = "registry.lab.raumberger.net/dynatrace-activegate:${AG_VERSION}"
      }

      resources {
        cpu    = 500
        memory = 3000
      }

      env {
        DYNATRACE_NETWORK_ZONE = "graz.homelab"
        DYNATRACE_AG_GROUP = "homelab"
        DYNATRACE_AG_ENTRYPOINT = "${attr.unique.network.ip-address}"
        DYNATRACE_AG_JVM_ARGS = "-Xms1024M -Xmx2663M"
      }

      template {
        data = <<EOH
AG_VERSION="{{key "activegate"}}"
EOH
        destination = "local/version.env"
        env         = true
        change_mode = "restart"
      }
    }
  }
}
