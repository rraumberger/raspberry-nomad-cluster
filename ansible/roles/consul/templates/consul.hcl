datacenter = "homenet"
data_dir = "{{ consul_data_dir }}"
bind_addr = "{% raw %}{{ GetAllInterfaces | include \"network\" \"{% endraw %}{{ private_network_range }}{% raw %}\" | sort \"size,address\" | attr \"address\" }}{% endraw %}"
client_addr = "0.0.0.0"
disable_update_check = true
enable_syslog = true
log_file = "/tmp/"
log_rotate_max_files = -1
#log_level = "debug"

ports {
  grpc = 8502
}