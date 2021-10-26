datacenter = "homenet"
data_dir = "{{ consul_data_dir }}"
advertise_addr = "{{ '{{ GetInterfaceIP \\"eth0\\" }}' }}"
bind_addr = "{{ '{{ GetInterfaceIP \\"eth0\\" }}' }}"
client_addr = "0.0.0.0"
disable_update_check = true
enable_syslog = true
log_file = "/var/log/consul/"
log_rotate_max_files = 3
#log_level = "debug"

ports {
  grpc = 8502
}