server {
  enabled = true
  bootstrap_expect = {{ hostvars | map('extract', hostvars) | selectattr('is_nomad_server') | length }}
}
