server {
  enabled = true
  bootstrap_expect = {{ groups['nomad_server'] | length }}
}
