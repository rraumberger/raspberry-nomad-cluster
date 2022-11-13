server {
  enabled = true
  bootstrap_expect = {{ expected_cluster_quorum }}
  data_dir = "{{ nomad_data_dir }}"
}
