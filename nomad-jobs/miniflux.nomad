job "miniflux" {
  datacenters = ["homenet"]
  type        = "service"

  constraint {
    distinct_hosts = true
  }

  constraint {
    attribute = "${node.class}"
    value = "storage"
  }

  group "miniflux" {
    count = 1

    network {
      mode = "bridge"
      port "http" {
        to = 8080
      }
    }

    reschedule {
      delay          = "30s"
      delay_function = "constant"
      unlimited      = true
    }

    task "miniflux" {
      driver = "docker"

      config {
        image = "miniflux/miniflux:2.0.33"
      }

      env {
        RUN_MIGRATIONS=1
        CREATE_ADMIN=1
      }

      vault {
        policies = ["homelab"]
      }

      template {
        destination = "secret/postgres.env"
        env = true
        data = <<EOH
{{with secret "homelab/data/postgres"}}
DATABASE_URL="postgres://{{.Data.data.minifluxUsername}}:{{.Data.data.minifluxPassword}}@postgres.service.consul/{{.Data.data.minifluxDatabase}}?sslmode=disable"
{{end}}
EOH
      }

      template {
        destination = "secret/miniflux.env"
        env = true
        data = <<EOH
{{with secret "homelab/data/miniflux"}}
ADMIN_USERNAME="{{.Data.data.adminUsername}}"
ADMIN_PASSWORD="{{.Data.data.adminPassword}}"
{{end}}
EOH
      }
    }

    service {
      name = "miniflux"
      port = "http"
    }
  }
}
