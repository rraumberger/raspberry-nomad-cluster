datacenter = "homenet"
data_dir = "{{ nomad_data_dir }}"
disable_update_check = true
enable_syslog = true
log_file = "/var/log/nomad/"
log_rotate_max_files = 3
#log_level = "debug"

telemetry {
  collection_interval = "1s"
  disable_hostname = true
  prometheus_metrics = true
  publish_allocation_metrics = true
  publish_node_metrics = true
}
