#!/bin/sh

ansible-playbook -i "${1}" nomad/nomad_setup.yml
