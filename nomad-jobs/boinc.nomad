job "boinc" {
  datacenters = ["homenet"]
  type        = "service"
  priority = 40
  
  update {
    health_check = "task_states"
  }

  constraint {
    distinct_hosts = true
  }
  
  constraint {
    attribute = "${node.class}"
    value = "computing"
  }
  
  group "client" {
    count = 3

    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    reschedule {
      delay = "2m"
      delay_function = "constant"
      unlimited = true
    }

    network {
      port "rpc" {}
    }
   
    ephemeral_disk {
      size = 6000
    }

    task "client" {
      driver = "docker"

      config {
        image = "boinc/client:arm64v8"
        hostname = "${attr.unique.hostname}"
        ports = ["rpc"]
        command = "sh"
        args = ["-c", "mkdir -p /var/lib/boinc/slots && /usr/bin/start-boinc.sh"]
      }

      env {
          BOINC_CMD_LINE_OPTIONS="--abort_jobs_on_exit --no_gpus --fetch_minimal_work --allow_remote_gui_rpc --gui_rpc_port ${NOMAD_PORT_rpc}"
      }

      template {
  data = <<EOH
BOINC_GUI_RPC_PASSWORD="{{key "BOINC_GUI_RPC_PASSWORD"}}"
EOH
        destination = "/secrets/BOINC_GUI_RPC_PASSWORD.env"
        env         = true
      }

      resources {
         cpu    = 5500
         memory = 3052
      }
    }

    task "boinc-account-manager-init" {
      driver = "docker"

      lifecycle {
        hook = "poststart"
        sidecar = false
      }

      config {
        image   = "boinc/client:arm64v8"
        command = "sh"
        args    = ["-c", "sleep 15 && boinccmd --host ${NOMAD_ADDR_rpc} --passwd \"${BOINC_GUI_RPC_PASSWORD}\" --project_attach ${BOINC_CMD_1} && boinccmd --host ${NOMAD_ADDR_rpc} --passwd \"${BOINC_GUI_RPC_PASSWORD}\" --project_attach ${BOINC_CMD_2}"]
      }

      template {
  data = <<EOH
BOINC_CMD_1="{{key "boinc/climatePrediction.net"}}"
BOINC_CMD_2="{{key "boinc/einsteinathome"}}"
BOINC_GUI_RPC_PASSWORD="{{key "BOINC_GUI_RPC_PASSWORD"}}"
EOH
        destination = "/secrets/secrets.env"
        env         = true
      }
    }
  }
}
