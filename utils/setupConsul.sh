#!/bin/sh

ansible-playbook --ask-become-pass -i "${1}" $(dirname "$0")/../ansible/setup_consul.yml
