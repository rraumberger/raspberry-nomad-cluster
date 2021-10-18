#!/bin/sh

ansible-playbook --ask-become-pass -i "${1}" sys-admin/update_hosts.yml
