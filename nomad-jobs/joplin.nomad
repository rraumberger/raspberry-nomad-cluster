job "joplin" {
  datacenters = ["homenet"]
  type        = "service"

  constraint {
    distinct_hosts = true
  }

  constraint {
    attribute = "${node.class}"
    value = "storage"
  }

  group "joplin" {
    count = 1

    network {
      mode = "bridge"
      port "http" {
        to = 22300
      }
    }

    reschedule {
      delay          = "30s"
      delay_function = "constant"
      unlimited      = true
    }

    task "joplin" {
      driver = "docker"

      config {
        image = "florider89/joplin-server:2.10.11" # there's currently no official arm64 support for joplin TODO: move to dedicated GH repo
      }

      env {
        APP_BASE_URL="https://notes.lab.raumberger.net:443"
        APP_PORT=22300
        DB_CLIENT="pg"
      }

      vault {
        policies = ["homelab"]
      }

      template {
        destination = "secret/postgres.env"
        env = true
        data = <<EOH
{{with secret "homelab/data/postgres"}}
POSTGRES_PASSWORD={{.Data.data.joplinPassword}}
POSTGRES_DATABASE={{.Data.data.joplinDatabase}}
POSTGRES_USER={{.Data.data.joplinUsername}}
POSTGRES_HOST=postgres.service.consul
{{end}}
EOH
      }
    }

    service {
      name = "joplin"
      port = "http"
    }
  }
}
