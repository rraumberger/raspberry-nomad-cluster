job "acme-renew" {
  type        = "batch"
  datacenters = ["homenet"]

  constraint {
    attribute = "${node.class}"
    value = "controller"
  }

  periodic {
    cron = "0 0 * * *"
    prohibit_overlap = true
  }

  group "acme-renew" {
    count = 1

    restart {
      attempts = 0
    }

    volume "certificates" {
      type      = "host"
      read_only = false
      source    = "certificates"
    }

    volume "acme" {
      type      = "host"
      read_only = false
      source    = "acme"
    }

    task "renew" {
      driver = "docker"
      volume_mount {
        volume      = "certificates"
        destination = "/etc/certificates"
        read_only   = false
      }

      volume_mount {
        volume      = "acme"
        destination = "/etc/acme"
        read_only   = false
      }

      config {
        image = "neilpang/acme.sh"
        args = ["acme.sh", "--server", "letsencrypt", "--cert-home", "/etc/certificates", "--config-home", "/etc/acme/config", "--home", "/etc/acme", "--renew-all"]
      }

      vault {
        policies = ["aws-route53", "homelab"]
      }

      template {
        data = <<EOF
{{ with secret "aws/creds/route53" }}
AWS_ACCESS_KEY_ID="{{ .Data.access_key }}"
AWS_SECRET_ACCESS_KEY="{{ .Data.secret_key }}"
AWS_SESSION_TOKEN="{{ .Data.security_token }}"
{{end}}
{{ with secret "homelab/data/cloudflare" }}
CF_Token="{{ .Data.data.acme }}"
CF_Account_ID="{{ .Data.data.account_id }}"
{{end}}
EOF
        destination   = "secrets/acme.env"
        env = true
      }
    }
  }
}