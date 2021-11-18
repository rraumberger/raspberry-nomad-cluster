# Raspberry PI Nomad Homelab

Ansible config to setup my Raspberry PI cluster.

- Service Orchestration: Hashicorp Nomad
- Service Discovery: Hashicorp Consul
- Secret Store: Hashicorp Vault
- Shared Storage: GlusterFS

## Prerequisites

- Ansible
- Dynatrace Ansible Collection (available via Dynatrace tenant)
- Gluster Ansible Collection: ansible-galaxy collection install gluster.gluster

### Initial Raspberry Bootstrap Setup

- keyboard: uk
- username: rpi
- TZ: Europe/Vienna
- locale: en-gb

## Manual Setup

### Storage Nodes

This is now automated via `sysadmin/sys_setup.yml` Ansible Playbook.
~~To fix issues with the Sabra SATA-to-USB3.0 adapters, add `usb-storage.quirks=152d:1561:u` to `/boot/cmdline.txt`~~
https://www.reddit.com/r/raspberry_pi/comments/c705p7/comment/eseqqg2/
This prevents the SSDs from randomly turning off.

### Vault

Setup Vault with the config provided in `vault-config`.

For automated Route53 changes setup your AWS IAM in a way Vault can access the Route53 HostedZone.
e.g. https://www.vaultproject.io/docs/secrets/aws

### Postgres

Create database (and store vault credentials) for
- Miniflux

e.g.
```
CREATE USER miniflux with LOGIN;
CREATE DATABASE miniflux;
GRANT ALL PRIVILEGES ON DATABASE miniflux TO miniflux;
\password miniflux
```

### Let's Encrypt

One-time account creation is necessary (because I was too lazy for automation)

```
sudo docker run --rm -it \
--name certbot \
-v "<hostpath>:/etc/letsencrypt" \
-v "<hostpath>:/var/lib/letsencrypt" \
certbot/dns-route53 register -m "<email>" --agree-tos
```

Create symbolic link in let's encrypt folder so HAProxy can properly resolve the key file
https://github.com/haproxy/haproxy/issues/221#issuecomment-869538325

`ln -s ./privkey.pem fullchain.pem.key`

Add exec permissions to `archive` and `live` folder of Let's Encrypt so HAProxy can access it properly.

`chmod +x archive`
`chmod +x live`

Download dhparams once and make it available to HAProxy

https://ssl-config.mozilla.org/ffdhe2048.txt

## How to run

TODO

## TODO

- [ ] Migrate to Podman
- [ ] Signal HAProxy after Let's Encrypt cert rotation. (HAProxy does not automatically reload changed certs from disk)
- [ ] Consul mTLS with Vault => https://learn.hashicorp.com/tutorials/consul/vault-pki-consul-secure-tls?in=onboarding/hcp-vault-week-6
- [ ] Nomad mTLS with Vault => https://learn.hashicorp.com/tutorials/nomad/vault-pki-nomad?in=onboarding/hcp-vault-week-6
- [ ] Nomad Gossip Encryption => https://learn.hashicorp.com/tutorials/consul/vault-kv-consul-secure-gossip?in=onboarding/hcp-vault-week-6
- [ ] Enable Consul and Nomad ACL
- [ ] Install Concourse CI
- [ ] Install Dynatrace EEC for SNMP extension