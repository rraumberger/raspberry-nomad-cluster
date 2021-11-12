job "certbot-init" {
  type        = "batch"
  datacenters = ["homenet"]

  constraint {
    attribute = "${node.class}"
    value = "controller"
  }

  group "certbot-init" {
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

    task "certbot-init" {
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
        args = ["certonly", "--dns-route53", "-d ${LAB_DOMAIN}", "-d *.${LAB_DOMAIN}", "--post-hook", "find /etc/letsencrypt/archive -regex \".*\\.pem$\" | while read file; do chmod 644 \"$file\"; done"]
      }

      vault {
        policies = ["aws-route53"]
      }

      template {
        data = <<EOH
LAB_DOMAIN="{{key "lab-domain"}}"
EOH
        destination = "local/version.env"
        env         = true
        change_mode = "restart"
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