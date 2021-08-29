server = false
retry_join = [ "{{ groups['nomad_server']| join('\",\"') }}" ]