#!/usr/bin/env bash
set -euo pipefail

# Usage:
# sudo ./install_jenkins_agent_service.sh --jenkins-url "https://<your-ngrok-url>" --agent-name "docker-agent" --agent-secret "<agent-secret>"

JENKINS_URL=""
AGENT_NAME="docker-agent"
AGENT_SECRET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --jenkins-url) JENKINS_URL="$2"; shift 2;;
    --agent-name) AGENT_NAME="$2"; shift 2;;
    --agent-secret) AGENT_SECRET="$2"; shift 2;;
    -h|--help) echo "Usage: $0 --jenkins-url <url> --agent-name <name> --agent-secret <secret>"; exit 0;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

if [[ -z "$JENKINS_URL" || -z "$AGENT_NAME" || -z "$AGENT_SECRET" ]]; then
  echo "Missing required arguments"
  exit 1
fi

UNIT_FILE="/etc/systemd/system/jenkins-agent.service"

cat <<EOF | sudo tee $UNIT_FILE
[Unit]
Description=Jenkins inbound agent
After=docker.service
Requires=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker run --rm --name jenkins-agent \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /home/ubuntu:/home/jenkins \
  jenkins/inbound-agent:latest -url "${JENKINS_URL}" "${AGENT_NAME}" "${AGENT_SECRET}"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now jenkins-agent

sleep 2
sudo systemctl status jenkins-agent --no-pager

echo "jenkins-agent service installed and started (see logs with 'sudo journalctl -u jenkins-agent -f')"
