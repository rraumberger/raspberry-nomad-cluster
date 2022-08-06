job "mosquitto" {
  datacenters = ["homenet"]
  type = "service"

  constraint {
    attribute = "${node.class}"
    value = "computing"
  }


  group "mosquitto" {
    count = 1

    network {
      mode = "bridge"

      port "mqtt" {
        to = 1883
      }

      port "websockets" {
        to = 9001
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

    task "mosquitto" {
      driver = "docker"

      config {
        image = "eclipse-mosquitto:latest"
        volumes = [
          "local/mosquitto.conf:/mosquitto/config/mosquitto.conf",
        ]
      }

      template {
        data = <<EOF
allow_anonymous true
listener 1883

listener 9001
protocol websockets
EOF

        destination = "local/mosquitto.conf"
      }

      vault {
        policies = ["homelab"]
      }

      service {
        name = "mosquitto"
        port = "mqtt"
      }
    }
  }
}