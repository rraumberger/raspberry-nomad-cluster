client {
  enabled = true
  node_class = "{{ nomad_node_class }}"
  server_join {
    retry_join = [ "{{ hostvars | map('extract', hostvars) | selectattr('is_nomad_server') | map(attribute = 'ansible_facts.default_ipv4.address') | join('\",\"') }}" ]
    retry_max = 10
    retry_interval = "15s"
  }
  reserved {
    reserved_ports = "22"
  }
  options = {
    "driver.allowlist" = "docker"
  }

  host_volume "sys-data" {
    path = "/sys"
    read_only = true
  }

  host_volume "nomad-shared-data" {
    path = "{{ nomad_shared_dir }}"
    read_only = false
  }
}
