#!/bin/bash
apt update -y
apt install -y docker.io awscli docker-compose
systemctl start docker
systemctl enable docker

ROLE="${role}"

if [ "$ROLE" = "app" ]; then
  docker run -d -p 8000:8000 ${app_image}
  docker run -d -p 80:80 ${frontend_image}
fi

if [ "$ROLE" = "monitor" ]; then
  mkdir /monitoring
  cat <<EOF > /monitoring/docker-compose.yml
version: '3'
services:
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
EOF
  cd /monitoring
  docker-compose up -d
fi
