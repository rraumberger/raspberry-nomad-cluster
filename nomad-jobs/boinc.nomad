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
    count = 6

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

    volume "boinc" {
      type      = "host"
      read_only = false
      source    = "boinc"
    }

    network {
      port "rpc" {}
    }

    ephemeral_disk {
      size = 12000
    }

    vault {
      policies = ["homelab"]
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

      volume_mount {
        volume      = "boinc"
        destination = "/var/lib/boinc"
        read_only   = false
      }

      env {
          BOINC_CMD_LINE_OPTIONS="--abort_jobs_on_exit --no_gpus --allow_remote_gui_rpc --gui_rpc_port ${NOMAD_PORT_rpc}"
      }

      template {
  data = <<EOH
BOINC_GUI_RPC_PASSWORD="{{with secret "homelab/data/boinc"}}{{.Data.data.rpcPassword}}{{end}}"
EOH
        destination = "/secrets/BOINC_GUI_RPC_PASSWORD.env"
        env         = true
      }

      resources {
         cpu    = 5500
         memory = 5722
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
        command = "bash"
        args    = ["-c", "sleep 15 && (while read i; do if [ ! -z \"$i\" ]; then boinccmd --host ${NOMAD_ADDR_rpc} --passwd \"${BOINC_GUI_RPC_PASSWORD}\" --project_attach $i || echo 'Already registered.'; fi; done < <(env | grep BOINC_CMD_ | cut -d '=' -f 2))"]
      }

      template {
  data = <<EOH
{{with secret "homelab/data/boinc"}}
BOINC_CMD_1="{{.Data.data.universeAtHomeUrl}} {{.Data.data.universeAtHome}}"
BOINC_CMD_2="{{.Data.data.einsteinAtHomeUrl}} {{.Data.data.einsteinAtHome}}"
BOINC_CMD_3="{{.Data.data.lhcAtHomeUrl}} {{.Data.data.lhcAtHome}}"
BOINC_CMD_4="{{.Data.data.milkywayAtHomeUrl}} {{.Data.data.milkywayAtHome}}"
BOINC_CMD_5="{{.Data.data.climatePredictionUrl}} {{.Data.data.climatePrediction}}"
BOINC_CMD_6="{{.Data.data.worldCommunityGridUrl}} {{.Data.data.worldCommunityGrid}}"
BOINC_CMD_7="{{.Data.data.rosettaAtHomeUrl}} {{.Data.data.rosettaAtHome}}"
BOINC_GUI_RPC_PASSWORD="{{.Data.data.rpcPassword}}"
{{end}}
EOH
        destination = "/secrets/secrets.env"
        env         = true
      }
    }
  }
}
