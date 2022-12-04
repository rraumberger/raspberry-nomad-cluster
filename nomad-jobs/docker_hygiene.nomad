job "docker-hygiene" {
  datacenters = ["homenet"]
  type        = "sysbatch"

  periodic {
    cron             = "@daily"
    prohibit_overlap = true
  }

  group "docker-commands" {
    count = 1

    restart {
      attempts = 0
      mode     = "fail"
    }

    task "delete-exited-containers" {
      driver = "raw_exec"
      resources {
        memory = 10
      }
      config {
        command = "sh"
        args = ["-c", "docker ps -a | grep Exited | cut -d ' ' -f 1 | xargs -r docker rm"]
      }
    }

    task "delete-dangling-images" {
      driver = "raw_exec"
      resources {
        memory = 10
      }
      config {
        command = "sh"
        args = ["-c", "docker images -q --filter dangling=true | xargs -r docker rmi"]
      }
    }

    task "delete-unused-local-docker-volumes" {
      driver = "raw_exec"
      resources {
        memory = 10
      }
      config {
        command = "sh"
        args = ["-c", "docker volume prune --force"]
      }
    }
  }

}