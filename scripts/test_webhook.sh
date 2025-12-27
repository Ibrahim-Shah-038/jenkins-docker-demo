#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ./test_webhook.sh https://<your-ngrok-url>/github-webhook/ [SECRET]

URL=${1:-}
SECRET=${2:-}

if [[ -z "$URL" ]]; then
  echo "Usage: $0 <webhook_url> [secret]"
  exit 1
fi

PAYLOAD='{"ref":"refs/heads/main","repository":{"full_name":"Ibrahim-Shah-038/jenkins-docker-demo"}}'

if [[ -n "$SECRET" ]]; then
  # compute X-Hub-Signature-256 header
  SIG=$(printf "%s" "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" -binary | xxd -p -c 256)
  HMAC_HEADER="sha256=$SIG"
  echo "Sending test webhook with HMAC signature"
  curl -v -H "Content-Type: application/json" -H "X-Hub-Signature-256: $HMAC_HEADER" --data "$PAYLOAD" "$URL"
else
  echo "Sending test webhook without secret"
  curl -v -H "Content-Type: application/json" --data "$PAYLOAD" "$URL"
fi

echo
echo "If the response is 200/OK, Jenkins received the webhook. If not, check ngrok and Jenkins logs."