datacenter = "homenet"
data_dir = "{{ nomad_data_dir }}"
disable_update_check = true
enable_syslog = true
log_file = "/tmp/"
log_rotate_max_files = 3
log_rotate_duration = "24h"
#log_level = "debug"

telemetry {
  collection_interval = "1s"
  disable_hostname = false
  prometheus_metrics = true
  publish_allocation_metrics = true
  publish_node_metrics = true
}

vault {
  enabled = true
  address = "{{ nomad_vault_address }}"
{% if is_nomad_server %}
  task_token_ttl = "1h"
  create_from_role = "nomad-cluster"
  token = "{{ nomad_vault_token }}"
{% endif %}
}