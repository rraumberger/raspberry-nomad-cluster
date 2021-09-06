client {
  enabled = true
  node_class = "raspberry"
  server_join {
    retry_join = [ "{{ groups['nomad_server']| join('\",\"') }}" ]
    retry_max = 10
    retry_interval = "15s"
  }
  reserved {    
    reserved_ports = "22"
  }
  options = {
    "driver.allowlist" = "podman,docker"
  }

  host_volume "sys-data" {
    path = "/sys"
    read_only = true
  }
}
