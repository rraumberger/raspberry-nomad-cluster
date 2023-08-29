fetchVersionFromRepo() {
    echo -n "$1: "
    curl --silent "https://api.github.com/repos/$1/releases/latest" | jq -r '.name'
}

fetchVersionFromRepo "hashicorp/consul"
fetchVersionFromRepo "hashicorp/vault"
fetchVersionFromRepo "hashicorp/nomad"

