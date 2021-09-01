#!/bin/sh

ansible-playbook -i "${1}" nomad/delete_cluster.yml
