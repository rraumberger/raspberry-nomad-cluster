#!/bin/sh

ansible-playbook --ask-become-pass -i "${1}" ansible/setup_consul.yml
