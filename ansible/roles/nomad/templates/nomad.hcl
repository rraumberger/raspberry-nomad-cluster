datacenter = "homenet"
data_dir = "{{ nomad_data_dir }}"

telemetry {
  collection_interval = "1s"
  disable_hostname = true
  prometheus_metrics = true
  publish_allocation_metrics = true
  publish_node_metrics = true
}
