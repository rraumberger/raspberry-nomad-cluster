#1/bin/bash

# Remove stopped docker processes
docker ps -a | grep Exited | cut -d ' ' -f 1 | xargs -r docker rm;

# Remove dangling images
docker image prune --all --filter "until=24h" --force;

# Remove unused local docker files
docker volume prune --force;