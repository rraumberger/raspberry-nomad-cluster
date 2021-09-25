#!/bin/sh
ansible-playbook -i "${1}" sys-admin/dynatrace_setup.yml
