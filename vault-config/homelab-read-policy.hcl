path "homelab/data/*"
{
  capabilities = ["read"]
}

path "concourse/*" {
  policy = "read"
}