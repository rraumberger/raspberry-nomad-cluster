server = false
retry_join = [ "{{ hostvars | map('extract', hostvars) | selectattr('is_consul_server') | map(attribute = 'ansible_facts.default_ipv4.address') | join('\",\"') }}" ]

connect {
  enabled = true
}