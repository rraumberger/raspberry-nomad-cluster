job "docker-registry" {
  datacenters = ["homenet"]
  type        = "service"

  constraint {
    distinct_hosts = true
  }

  constraint {
    attribute = "${node.class}"
    value = "storage"
  }

  group "mirror" {
    count = 1

    network {
      mode = "bridge"
      port "http" {
        to = 5000
      }
    }

    ephemeral_disk {
      size = 5000
    }

    volume "docker-mirror" {
      type      = "host"
      read_only = false
      source    = "docker-mirror"
    }

    task "registry" {
      driver = "docker"
      volume_mount {
        volume      = "docker-mirror"
        destination = "/var/lib/registry"
        read_only   = false
      }

      config {
        image = "registry:latest"
      }

      resources {
        network {
          mbits = 100
        }
      }

      env {
        REGISTRY_HTTP_HOST = "http://mirror.lab.raumberger.net"
        REGISTRY_REDIS_ADDR = "redis.service.consul:6379"
        REGISTRY_REDIS_DB = "0"
        REGISTRY_PROXY_REMOTEURL = "https://registry-1.docker.io"
        REGISTRY_STORAGE_CACHE_BLOBDESCRIPTOR = "redis"
      }

      vault {
        policies = ["homelab"]
      }

      template {
        data = <<EOF
REGISTRY_REDIS_PASSWORD="{{with secret "homelab/data/redis"}}{{.Data.data.password}}{{end}}"
EOF
        destination   = "secrets/redis.env"
        env = true
      }
    }

    service {
      name = "docker-mirror"
      port = "http"
    }
  }

  group "registry" {
    count = 1

    network {
      mode = "bridge"
      port "http" {
        to = 5000
      }
    }

    ephemeral_disk {
      size = 5000
    }

    volume "docker-registry" {
      type      = "host"
      read_only = false
      source    = "docker-registry"
    }

    task "registry" {
      driver = "docker"
      volume_mount {
        volume      = "docker-registry"
        destination = "/var/lib/registry"
        read_only   = false
      }

      config {
        image = "registry:latest"
      }

      resources {
        network {
          mbits = 100
        }
      }

      env {
        REGISTRY_HTTP_HOST = "http://registry.lab.raumberger.net"
        REGISTRY_REDIS_ADDR = "redis.service.consul:6379"
        REGISTRY_REDIS_DB = "1"
        REGISTRY_STORAGE_CACHE_BLOBDESCRIPTOR = "redis"
      }

      vault {
        policies = ["homelab"]
      }

      template {
        data = <<EOF
REGISTRY_REDIS_PASSWORD="{{with secret "homelab/data/redis"}}{{.Data.data.password}}{{end}}"
EOF
        destination   = "secrets/redis.env"
        env = true
      }
    }

    service {
      name = "docker-registry"
      port = "http"
    }
  }
}
