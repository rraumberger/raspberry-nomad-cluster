server = true
bootstrap_expect = {{ hostvars | map('extract', hostvars) | selectattr('is_consul_server') | length }}

ui_config {
  enabled = true
}
