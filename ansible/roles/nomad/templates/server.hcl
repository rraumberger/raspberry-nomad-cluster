server {
  enabled = true
  bootstrap_expect = {{ expected_cluster_quorum }}
  data_dir = "{{ nomad_data_dir }}"
}

ui {
  enabled = {{ ui_enabled|lower }}
  consul {
    ui_url = "{{ consul_ui_url }}"
  }
  vault {
    ui_url = "{{ vault_ui_url }}"
  }
}