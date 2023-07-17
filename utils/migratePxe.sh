#!/bin/sh
ansible-playbook --ask-become-pass -i $(dirname "$0")/../hosts $(dirname "$0")/../sys-admin/migrate_pxe.yml
