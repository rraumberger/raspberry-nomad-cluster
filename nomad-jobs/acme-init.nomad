job "acme-init" {
  type        = "batch"
  datacenters = ["homenet"]

  constraint {
    distinct_hosts = true
  }

  group "acme-init" {
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

    task "domains" {
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
        command = "sh"
        args = ["-c", "acme.sh --issue --server letsencrypt --cert-home /etc/certificates --config-home /etc/acme/config --home /etc/acme -d ${NET_DOMAIN} -d *.${NET_DOMAIN} -d ${DEV_DOMAIN} -d *.${DEV_DOMAIN} --dns dns_aws --dns dns_aws --dns dns_cf --dns dns_cf && acme.sh --issue --server letsencrypt --cert-home /etc/certificates --config-home /etc/acme/config --home /etc/acme --dns dns_aws -d ${LAB_DOMAIN} -d *.${LAB_DOMAIN} && cd /etc/certificates/${NET_DOMAIN}_ecc && cat ${NET_DOMAIN}.key >> fullchain.cer  && cd /etc/certificates/${LAB_DOMAIN}_ecc && cat ${LAB_DOMAIN}.key >> fullchain.cer" ]
      }

      vault {
        policies = ["aws-route53", "homelab"]
      }

      template {
        data = <<EOH
LAB_DOMAIN="{{key "lab-domain"}}"
NET_DOMAIN="{{key "net-domain"}}"
DEV_DOMAIN="{{key "dev-domain"}}"
EOH
        destination = "local/domains.env"
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
