#!/bin/sh

ansible-playbook --ask-become-pass -i "${1}" $(dirname "$0")/../sys-admin/help_shutdown_all.yml
