#!/bin/sh

ansible-playbook -i "${1}" sys-admin/shutdown_all.yml
