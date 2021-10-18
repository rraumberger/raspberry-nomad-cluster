#!/bin/sh
ansible-playbook --ask-become-pass -i "${1}" sys-admin/sys_setup.yml
