#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 --jenkins-url <JENKINS_URL> --agent-name <AGENT_NAME> --agent-secret <AGENT_SECRET>

Example:
  $0 --jenkins-url "https://your-ngrok-url.ngrok.io" --agent-name "docker-agent" --agent-secret "abcd1234..."

This script runs the official Jenkins inbound agent container and mounts the Docker socket so the agent can run Docker commands.

Note: You must create a node in Jenkins (Permanent Agent) with "Launch agent by connecting it to the controller", name it <AGENT_NAME> and set the label to `docker`.
EOF
}

# Simple arg parsing
JENKINS_URL=""
AGENT_NAME=""
AGENT_SECRET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --jenkins-url) JENKINS_URL="$2"; shift 2;;
    --agent-name) AGENT_NAME="$2"; shift 2;;
    --agent-secret) AGENT_SECRET="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

if [[ -z "$JENKINS_URL" || -z "$AGENT_NAME" || -z "$AGENT_SECRET" ]]; then
  echo "Missing required arguments"
  usage
  exit 1
fi

echo "Starting Jenkins inbound agent..."

docker pull jenkins/inbound-agent:latest

# Stop any old container
if docker ps -a --format '{{.Names}}' | grep -q '^jenkins-agent$'; then
  echo 'Stopping existing jenkins-agent container'
  docker stop jenkins-agent || true
  docker rm jenkins-agent || true
fi

# Run agent with Docker socket mounted so it can run docker commands
docker run -d \
  --name jenkins-agent \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /home/ubuntu:/home/jenkins \
  jenkins/inbound-agent:latest \
  -url "$JENKINS_URL" "$AGENT_NAME" "$AGENT_SECRET"

sleep 2
if docker ps --format '{{.Names}}' | grep -q '^jenkins-agent$'; then
  echo "jenkins-agent started successfully"
else
  echo "Failed to start jenkins-agent container; check 'docker logs jenkins-agent' for details"
  exit 2
fi
