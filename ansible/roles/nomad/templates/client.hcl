client {
  enabled = true
  node_class = "{{ nomad_node_class }}"
  server_join {
    retry_join = [ "{{ hostvars | map('extract', hostvars) | selectattr('is_nomad_server') | map(attribute = 'ansible_facts.default_ipv4.address') | join('\",\"') }}" ]
    retry_max = 0
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

{% for volume in nomad_host_volumes %}
  host_volume "{{ volume.volumeKey }}" {
    path = "{{ volume.path }}"
    read_only = false
  }
{% endfor %}
}

plugin "docker" {
  config {
    allow_privileged = true

    volumes {
      enabled      = true
    }
  }
}
