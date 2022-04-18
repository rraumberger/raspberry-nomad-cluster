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

  constraint {
      attribute = "${attr.unique.network.ip-address}"
      value = "192.168.42.249"
  }

  reschedule {
    delay          = "1m"
    delay_function = "constant"
    unlimited      = true
  }

  update {
    max_parallel     = 1
    health_check     = "task_states"
  }

  group "activegate" {
    count = 1

    restart {
      attempts = 5
      interval = "2m"
    }

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

      vault {
        policies = ["homelab"]
      }

      template {
        data = <<EOH
{{with secret "concourse/data/main/dynatrace_activegate_version"}}
AG_VERSION="{{.Data.data.value}}"
{{end}}
EOH
        destination = "local/version.env"
        env         = true
        change_mode = "restart"
      }
    }
  }
}
