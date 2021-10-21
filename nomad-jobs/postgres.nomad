job "postgres" {
  datacenters = ["homenet"]
  type = "service"

  constraint {
    distinct_hosts = true
  }

  constraint {
    attribute = "${node.class}"
    value = "storage"
  }

  group "postgres" {
    count = 1

    network {
      mode = "bridge"
      port "postgres" {
        static = 5432
        to = 5432
      }
    }

    reschedule {
      delay          = "30s"
      delay_function = "constant"
      unlimited      = true
    }

    ephemeral_disk {
      size = 300
    }

    volume "postgres-data" {
      type      = "host"
      read_only = false
      source    = "postgres-data"
    }

    task "postgres" {
      driver = "docker"

      volume_mount {
        volume      = "postgres-data"
        destination = "/var/lib/postgresql/data"
        read_only   = false
      }

      config {
        image = "postgres:latest"
      }

      env {
        POSTGRES_INITDB_ARGS="--data-checksums"
      }

      resources {
        cpu    = 500
        memory = 256
      }

      vault {
        policies = ["homelab"]
      }

      template {
        change_mode = "noop"
        destination = "secret/postgres.env"
        env = true
        data = <<EOH
{{with secret "homelab/data/postgres"}}
POSTGRES_USER="{{.Data.data.masterUsername}}"
POSTGRES_PASSWORD="{{.Data.data.masterPassword}}"
{{end}}
EOH
      }

      service {
        name = "postgres"
        port = "postgres"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}