# Jenkins setup & credentials guide ✅

This file explains the minimum Jenkins configuration and credentials required for the `Jenkinsfile` included in this repo.

## Required Jenkins Plugins
- Pipeline
- Git (git client plugin)
- SSH Agent
- Credentials Binding
- Amazon Web Services Credentials (optional, if using Terraform or ECR)
- Docker Pipeline (optional)

## Credentials to create in Jenkins
- **SSH (type: "SSH Username with private key")**
  - ID: `ec2-ssh-key`
  - Username: `ubuntu`
  - Private Key: paste the private key (e.g., `ibrahim-devops.pem`) or reference a credential file

- **AWS credentials (if you'll use Terraform or ECR later)**
  - ID: `aws-creds`
  - Use Jenkins AWS Credentials plugin or Username/Password with Access Key ID and Secret

> Security note: do NOT commit private keys or AWS secrets to git. Use Jenkins' credentials store.

## Webhook (GitHub)
- Configure a webhook on your GitHub repo `https://github.com/Ibrahim-Shah-038/jenkins-docker-demo` to POST to your Jenkins (via your ngrok URL) on push events.
- If using a multibranch pipeline, Jenkins will detect branches automatically when scanning.

## Common issues
- If SSH fails, ensure the Jenkins host IP is allowed by any local firewalls and the key matches the one associated with the EC2 instance.
- If Docker commands fail on the instance, ensure `docker` and `docker-compose` are installed and the `ubuntu` user belongs to the `docker` group.
