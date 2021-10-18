#!/bin/sh
ansible-playbook --ask-become-pass -i "${1}" sys-admin/dynatrace_setup.yml
