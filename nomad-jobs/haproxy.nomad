job "haproxy" {
  datacenters = ["homenet"]
  type        = "service"

  constraint {
    distinct_hosts = true
  }

  constraint {
    attribute = "${node.class}"
    value = "controller"
  }

  group "haproxy" {
    count = 2

    volume "certificates" {
      type      = "host"
      read_only = false
      source    = "certificates"
    }

    reschedule {
      delay          = "60s"
      delay_function = "constant"
      unlimited      = true
    }

    network {
      mode = "bridge"
      port "http" {
        static = 80
        to = 8080
      }

      port "https" {
        static = 443
        to = 8443
      }

      port "http-public" {
        static = 8081
        to = 8081
      }

      port "https-public" {
        static = 8444
        to = 8444
      }

      port "haproxy_ui" {
        static = 1936
        to = 1936
      }

      port "mqtt" {
        static = 1883
        to = 1883
      }

      port "mqtt-websocket" {
        static = 9001
        to = 9001
      }
    }

    service {
      name = "haproxy-http"
      port = "http"

      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "10s"
        timeout  = "2s"
      }
    }

    service {
      name = "haproxy-https"
      port = "https"

      check {
        name     = "alive"
        type     = "tcp"
        port     = "https"
        interval = "10s"
        timeout  = "2s"
      }
    }

    service {
      name = "haproxy-ui"
      port = "haproxy_ui"
    }

    task "haproxy" {
      driver = "docker"

      config {
        image        = "haproxy:latest"
        volumes = [
          "local/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg",
        ]
      }

      volume_mount {
        volume      = "certificates"
        destination = "/etc/certificates"
        read_only   = true
      }

      template {
        data = <<EOF
# generated 2023-07-19, Mozilla Guideline v5.7, HAProxy 2.8.1, OpenSSL 1.1.1n, modern configuration
# https://ssl-config.mozilla.org/#server=haproxy&version=2.8.1&config=modern&openssl=1.1.1n&guideline=5.7
global
    # modern configuration
    ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
    ssl-default-bind-options prefer-client-ciphers no-sslv3 no-tlsv10 no-tlsv11 no-tlsv12 no-tls-tickets

    ssl-default-server-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
    ssl-default-server-options no-sslv3 no-tlsv10 no-tlsv11 no-tlsv12 no-tls-tickets

    # curl https://ssl-config.mozilla.org/ffdhe2048.txt > /path/to/dhparam
    ssl-dh-param-file /etc/certificates/ffdhe2048.txt

    log 127.0.0.1 local0 debug

defaults
    log global
    mode http
    option httplog

    option dontlognull

    timeout connect 5000
    timeout check 5000
    timeout client 30000
    timeout server 30000

    option forwardfor
    option http-server-close
    balance leastconn

frontend stats
    mode    http
    bind    *:1936  ssl crt /etc/certificates/lab.raumberger.net_ecc/fullchain.cer alpn h2,http/1.1
    redirect scheme https code 301 if !{ ssl_fc }

    # HSTS (63072000 seconds)
    http-response set-header Strict-Transport-Security max-age=63072000

    stats uri /
    stats show-legends

frontend homelab
    mode    http
    bind    *:8443 ssl crt /etc/certificates/lab.raumberger.net_ecc/fullchain.cer alpn h2,http/1.1
    bind    *:8080

    acl network_allowed src 192.168.0.0/16
    acl network_allowed src 10.0.0.0/8
    acl network_allowed src 172.16.0.0/16

    http-request deny if !network_allowed

    redirect scheme https code 301 if !{ ssl_fc }

    # HSTS (63072000 seconds)
    http-response set-header Strict-Transport-Security max-age=63072000

    http-request set-header X-Forwarded-Proto https
#    http-request set-header X-Forwarded-Host %[req.hdr(Host)]
    option forwardfor

    use_backend %[req.hdr(Host),lower]

frontend public
    mode    http
    bind    *:8444 ssl crt /etc/certificates/raumberger.net_ecc/fullchain.cer alpn h2,http/1.1
    bind    *:8081

    redirect scheme https code 301 if !{ ssl_fc }

    capture         request header Host len 40
    acl hyperion hdr(host) -i hyperion.raumberger.dev

    # HSTS (63072000 seconds)
    http-response set-header Strict-Transport-Security max-age=63072000


    http-request set-header X-Forwarded-Proto https
#    http-request set-header X-Forwarded-Host %[req.hdr(Host)]
    option forwardfor

    use_backend hyperion if hyperion

    default_backend raumberger.dev

# Based on https://github.com/lelylan/haproxy-mqtt/blob/master/haproxy.cfg
listen mqtt
  bind *:1883
  bind *:9001
  bind *:8883 ssl crt /etc/certificates/lab.raumberger.net_ecc/fullchain.cer
  mode tcp
  #Use this to avoid the connection loss when client subscribed for a topic and its idle for sometime
  option clitcpka # For TCP keep-alive
  timeout client 3h #By default TCP keep-alive interval is 2hours in OS kernal, 'cat /proc/sys/net/ipv4/tcp_keepalive_time'
  timeout server 3h #By default TCP keep-alive interval is 2hours in OS kernal
  option tcplog
  balance leastconn
  server-template srv 5 _mosquitto._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check

backend registry.lab.raumberger.net
    server-template srv 5 _docker-registry._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check

backend mirror.lab.raumberger.net
    server-template srv 5 _docker-mirror._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check

#backend pihole.lab.raumberger.net
#    server-template srv 5 _pihole._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check

backend miniflux.lab.raumberger.net
    server-template srv 5 _miniflux._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check

backend nomad.lab.raumberger.net
    server-template srv 5 _nomad._http.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check

backend vault.lab.raumberger.net
    server-template srv 5 _vault._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check

backend consul.lab.raumberger.net
    server-template consul 5 consul.service.consul:8500 resolvers consul resolve-prefer ipv4 check

backend raumberger.dev
    server-template srv 5 _raumbergerDev._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check

backend notes.lab.raumberger.net
    server-template srv 5 _joplin._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check

backend spot.lab.raumberger.net
    server-template srv 5 _spot._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check

backend youtrack.lab.raumberger.net
    server-template srv 5 _youtrack._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check

backend teamcity.lab.raumberger.net
    server-template srv 5 _teamcity._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check

backend hub.lab.raumberger.net
    server-template srv 5 _hub._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check

backend hyperion
    server-template srv 5 _hyperion-frontend._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check


resolvers consul
    nameserver controller {{ env "attr.unique.network.ip-address" }}:53
    accepted_payload_size 8192
    hold valid 5s
EOF

        destination = "local/haproxy.cfg"
      }

      resources {
        cpu    = 300
        memory = 256
      }
    }
  }
}
