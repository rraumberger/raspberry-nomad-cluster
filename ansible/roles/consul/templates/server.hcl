server = true
bootstrap_expect = {{ expected_cluster_quorum }}

ui_config {
  enabled = {{ ui_enabled|lower }}
}
