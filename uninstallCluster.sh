#!/bin/sh

ansible-playbook -i "${1}" ansible/delete_cluster.yml
