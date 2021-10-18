#!/bin/sh

ansible-playbook --ask-become-pass -i "${1}" ansible/delete_cluster.yml
