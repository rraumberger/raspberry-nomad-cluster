#!/bin/sh
ansible-playbook -i "${1}" sys-admin/sys_setup.yml
