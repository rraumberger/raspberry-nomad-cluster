#!/bin/sh

ansible-playbook -i "${1}" ansible/setup_nomad.yml