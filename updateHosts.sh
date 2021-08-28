#!/bin/sh

ansible-playbook -i "${1}" sys-admin/update_hosts.yml
