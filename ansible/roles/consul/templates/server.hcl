server = true
bootstrap_expect = {{ (groups['nomad_server'] | length) }}

ui_config {
  enabled = true
}
