job "iperf" {
  datacenters = ["homenet"]
  type        = "service"

  group "iperf3" {
    count = 1

    network {
      mode = "bridge"
      port "tcp" {
        static = 5201
        to = 5201
      }
    }

    task "iperf3" {
      driver = "docker"

      config {
        image = "registry.lab.raumberger.net/iperf3"
        args = ["-s"]
      }

      resources {
        cpu    = 3000
        memory = 1024
      }
    }
  }
}
