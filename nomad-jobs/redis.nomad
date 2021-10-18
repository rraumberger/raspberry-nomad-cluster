job "redis" {
  datacenters = ["homenet"]
  type = "service"

  constraint {
    distinct_hosts = true
  }

  constraint {
    attribute = "${node.class}"
    value = "storage"
  }

  group "cache" {
    count = 1

    network {
      mode = "bridge"
      port "redis" {
        static = 6379
        to = 6379
      }
    }

    ephemeral_disk {
      size = 300
    }

    volume "redis-data" {
      type      = "host"
      read_only = false
      source    = "redis-data"
    }

    task "redis" {
      driver = "docker"

      volume_mount {
        volume      = "redis-data"
        destination = "/data"
        read_only   = false
      }

      config {
        image = "redis:latest"
        volumes = [
          "local/redis.conf:/usr/local/etc/redis/redis.conf",
        ]
        command = "redis-server"
        args = ["/usr/local/etc/redis/redis.conf"]
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
        destination = "local/redis.conf"

        data = <<EOH
requirepass {{with secret "homelab/data/redis"}}{{.Data.data.password}}{{end}}
EOH
      }

      service {
        name = "redis"
        port = "redis"
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