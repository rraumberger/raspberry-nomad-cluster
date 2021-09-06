server = false
retry_join = [ "{{ groups['nomad_server']| join('\",\"') }}" ]


ports {
  grpc = 8502
}
connect {
  enabled = true
}