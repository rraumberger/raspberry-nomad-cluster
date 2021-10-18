server {
  enabled = true
  bootstrap_expect = {{ hostvars | map('extract', hostvars) | selectattr('is_nomad_server') | length }}
  data_dir = "{{ nomad_data_dir }}"
}

vault {
  enabled = true
  address = "{{ nomad_vault_address }}"
  task_token_ttl = "1h"
  create_from_role = "nomad-cluster"
  token = "{{ nomad_vault_token }}"
}