#!/usr/bin/env bash
set -euo pipefail

# Remote deploy script to place on EC2 (or to be executed via SSH by Jenkins)
REPO_URL="https://github.com/Ibrahim-Shah-038/jenkins-docker-demo.git"
DEPLOY_PATH="/home/ubuntu/jenkins-docker-demo"
BRANCH_NAME="${1:-main}"

mkdir -p "$DEPLOY_PATH"
if [ ! -d "$DEPLOY_PATH/.git" ]; then
  git clone "$REPO_URL" "$DEPLOY_PATH"
fi

cd "$DEPLOY_PATH"
git fetch --all
git reset --hard "origin/$BRANCH_NAME"

# Build and run docker-compose
# Assumes docker and docker-compose are installed and the user has permissions (ubuntu user usually OK)
docker-compose build --pull
docker-compose up -d --remove-orphans

echo "Deployment complete: branch $BRANCH_NAME"
