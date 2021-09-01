#!/bin/sh

ansible-playbook -i "${1}" nomad/setup_nomad.yml
