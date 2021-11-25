job "concourse" {
  datacenters = ["homenet"]
  type        = "service"

  group "web" {
    count = 1

    network {
      mode = "bridge"
      port "http" {
        to = 8080
      }

      port "tsa" {
        static = 2222
        to = 2222
      }
    }

    task "web" {
      driver = "docker"

      config {
        image = "rdclda/concourse:7.6.0@sha256:4587a8161e4dfc1c8e58f25d66df74ae3ac09baede28a240d037a14195e24305"
        args = ["web"]
        volumes = [
          "secret/session.key:/etc/keys/session_key",
          "secret/tsaHost.key:/etc/keys/tsa_host_key",
          "secret/workerAuth.key:/etc/keys/authorized_worker_keys"
        ]
      }

      env {
        CONCOURSE_SESSION_SIGNING_KEY="/etc/keys/session_key"
        CONCOURSE_TSA_HOST_KEY="/etc/keys/tsa_host_key"
        CONCOURSE_TSA_AUTHORIZED_KEYS="/etc/keys/authorized_worker_keys"
        CONCOURSE_EXTERNAL_URL="https://concourse.lab.raumberger.net"
        CONCOURSE_VAULT_URL="https://vault.lab.raumberger.net"
        CONCOURSE_VAULT_CLIENT_TOKEN="${VAULT_TOKEN}"
        CONCOURSE_VAULT_PATH_PREFIX="/concourse"
      }

      vault {
        policies = ["homelab"]
      }

      template {
        destination = "secret/postgres.env"
        env = true
        data = <<EOH
{{with secret "homelab/data/postgres"}}
CONCOURSE_POSTGRES_HOST=postgres.service.consul
CONCOURSE_POSTGRES_PORT=5432
CONCOURSE_POSTGRES_DATABASE={{.Data.data.concourseDatabase}}
CONCOURSE_POSTGRES_USER={{.Data.data.concourseUsername}}
CONCOURSE_POSTGRES_PASSWORD={{.Data.data.concoursePassword}}
{{end}}
EOH
      }

      template {
        destination = "secret/concourse.env"
        env = true
        data = <<EOH
{{with secret "homelab/data/concourse"}}
CONCOURSE_ADD_LOCAL_USER={{.Data.data.localUser}}:{{.Data.data.localUserPassword}}
CONCOURSE_MAIN_TEAM_LOCAL_USER={{.Data.data.localUser}}
{{end}}
EOH
      }

      template {
        destination = "secret/session.key"
        env = false
        data = <<EOH
{{with secret "homelab/data/concourse"}}
{{.Data.data.sessionSigningKey}}
{{end}}
EOH
      }
      template {
        destination = "secret/tsaHost.key"
        env = false
        data = <<EOH
{{with secret "homelab/data/concourse"}}
{{.Data.data.tsaHostKey}}
{{end}}
EOH
      }

      template {
        destination = "secret/workerAuth.key"
        env = false
        data = <<EOH
{{with secret "homelab/data/concourse"}}
{{.Data.data.workerKey_pub}}
{{end}}
EOH
      }
    }

    service {
      name = "concourse"
      port = "http"
    }

    service {
      name = "concourse-tsa"
      port = "tsa"
    }
  }

  group "worker" {
    count = 1

    network {
      mode = "bridge"
      port "http" {
        to = 8888
      }
    }

    task "worker" {
      driver = "docker"

      config {
        image = "rdclda/concourse:7.6.0@sha256:4587a8161e4dfc1c8e58f25d66df74ae3ac09baede28a240d037a14195e24305"
        args = ["worker"]
        privileged = true
        volumes = [
          "secret/tsaHost.key.pub:/etc/keys/tsa_host_key.pub",
          "secret/workerAuth.key:/etc/keys/worker_key"
        ]
      }

      env {
        CONCOURSE_RUNTIME="containerd"
        CONCOURSE_WORK_DIR="/worker-state"
        CONCOURSE_WORKER_WORK_DIR="/worker-state"
        CONCOURSE_TSA_HOST="concourse-tsa.service.consul:2222"
        CONCOURSE_TSA_PUBLIC_KEY="/etc/keys/tsa_host_key.pub"
        CONCOURSE_TSA_WORKER_PRIVATE_KEY="/etc/keys/worker_key"
      }

      vault {
        policies = ["homelab"]
      }

      template {
        destination = "secret/tsaHost.key.pub"
        env = false
        data = <<EOH
{{with secret "homelab/data/concourse"}}
{{.Data.data.tsaHostKey_pub}}
{{end}}
EOH
      }

      template {
        destination = "secret/workerAuth.key"
        env = false
        data = <<EOH
{{with secret "homelab/data/concourse"}}
{{.Data.data.workerKey}}
{{end}}
EOH
      }

      resources {
        cpu    = 1000
        memory = 1024
      }
    }

    ephemeral_disk {
      size = 5000
    }

    service {
      name = "concourse-worker"
      port = "http"
    }
  }
}
