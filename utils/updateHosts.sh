#!/bin/sh

ansible-playbook --ask-become-pass -i "${1}" $(dirname "$0")/../sys-admin/update_hosts.yml
