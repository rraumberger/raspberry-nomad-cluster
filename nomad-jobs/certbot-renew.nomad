job "certbot-renew" {
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

  group "certbot-renew" {
    count = 1

    restart {
      attempts = 0
    }

    volume "certificates" {
      type      = "host"
      read_only = false
      source    = "certificates"
    }

    volume "lets-encrypt" {
      type      = "host"
      read_only = false
      source    = "lets-encrypt"
    }

    task "certbot-renew" {
      driver = "docker"
      volume_mount {
        volume      = "certificates"
        destination = "/etc/letsencrypt"
        read_only   = false
      }

      volume_mount {
        volume      = "lets-encrypt"
        destination = "/var/lib/letsencrypt"
        read_only   = false
      }

      config {
        image = "certbot/dns-route53:arm64v8-v1.21.0"
        args = ["renew", "--dns-route53", "--post-hook", "find /etc/letsencrypt/archive -regex \".*\\.pem$\" | while read file; do chmod 644 \"$file\"; done"]
      }

      vault {
        policies = ["aws-route53"]
      }

      template {
        data = <<EOF
{{ with secret "aws/creds/route53" }}
AWS_ACCESS_KEY_ID="{{ .Data.access_key }}"
AWS_SECRET_ACCESS_KEY="{{ .Data.secret_key }}"
AWS_SESSION_TOKEN="{{ .Data.security_token }}"
{{end}}
EOF
        destination   = "secrets/aws.env"
        env = true
      }
    }
  }
}