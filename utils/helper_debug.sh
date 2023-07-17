#!/bin/sh

ansible-playbook --ask-become-pass -i $(dirname "$0")/../hosts $(dirname "$0")/../ansible/help_debug.yml
