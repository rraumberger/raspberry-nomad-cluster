storage "consul" {}

listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = "true"
}

listener "tcp" {
  address     = "{{ hostvars[inventory_hostname]['ansible_default_ipv4']['address'] }}:8200"
  tls_disable = "true"
}

api_addr = "http://{{ hostvars[inventory_hostname]['ansible_default_ipv4']['address'] }}:8200"
cluster_addr = "https://{{ hostvars[inventory_hostname]['ansible_default_ipv4']['address'] }}:8201"
ui = true
