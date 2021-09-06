job "boinc" {
  datacenters = ["homenet"]
  type        = "service"

  group "client" {
    count = 4

    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
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
        ports = ["rpc"]
        command = "sh"
        args = ["-c", "mkdir -p /var/lib/boinc/slots && /usr/bin/start-boinc.sh"]
      }

      env {
          BOINC_CMD_LINE_OPTIONS="--abort_jobs_on_exit --no_gpus --allow_remote_gui_rpc --gui_rpc_port ${NOMAD_PORT_rpc}"
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
        #args    = ["-c", "(sleep 15 && boinccmd --host ${NOMAD_ADDR_rpc} --passwd \"${BOINC_GUI_RPC_PASSWORD}\" --join_acct_mgr ${BOINC_CMD_OPTIONS} && boinccmd --host ${NOMAD_ADDR_rpc} --passwd \"${BOINC_GUI_RPC_PASSWORD}\" --acct_mgr info) | grep http || exit 1 && echo 'init success'"]
        args    = ["-c", "boinccmd --host ${NOMAD_ADDR_rpc} --passwd \"${BOINC_GUI_RPC_PASSWORD}\" ${BOINC_CMD_OPTIONS}"]
      }
      template {
  data = <<EOH
BOINC_CMD_OPTIONS="{{key "boinccmdParams"}}"
EOH
        destination = "/secrets/boincCmdLineOptions.env"
        env         = true
      }

      template {
  data = <<EOH
BOINC_GUI_RPC_PASSWORD="{{key "BOINC_GUI_RPC_PASSWORD"}}"
EOH
        destination = "/secrets/BOINC_GUI_RPC_PASSWORD.env"
        env         = true
      }
    }
  }
}
