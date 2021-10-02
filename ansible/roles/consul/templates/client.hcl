server = false
retry_join = [ "{{ hostvars | map('extract', hostvars) | selectattr('is_consul_server') | map(attribute = 'ansible_facts.default_ipv4.address') | join('\",\"') }}" ]


ports {
  grpc = 8502
}
connect {
  enabled = true
}