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
- Use the path `/github-webhook/` (e.g., `https://<your-ngrok-url>/github-webhook/`) and **Content type: application/json**.
- If you configured a secret in the GitHub webhook, make sure the same secret is configured in Jenkins (or test webhooks using the same secret).
- If using a multibranch pipeline, Jenkins will detect branches automatically when scanning.

### Webhook debugging stepss
1) Verify ngrok is running and the public URL matches the webhook URL in GitHub. ngrok URLs change after restart.
2) In GitHub: Settings → Webhooks → Recent Deliveries. Inspect the latest deliveries:
   - If Delivery shows **Failed**: read Response headers and body for HTTP status.
   - If it shows 404 or 500, check the webhook path and Jenkins system logs.
3) Run the included test script from your workstation to simulate GitHub sending a push event:

```bash
chmod +x ./scripts/test_webhook.sh
./scripts/test_webhook.sh https://<your-ngrok-url>/github-webhook/ [<optional-secret>]
```

If the script gets a 200/OK response, Jenkins received the webhook; otherwise check ngrok's web interface (http://127.0.0.1:4040) to see request details and responses.

4) Enable detailed logging in Jenkins for GitHub webhooks:
   - Manage Jenkins → System Log → Add new Log Recorder.
   - Name: `github-webhook`.
   - Add Loggers: `org.jenkinsci.plugins.github` and `org.jenkinsci.plugins.github.webhook` at level `FINE`.
   - Re-send a test webhook and watch System Log for incoming requests and errors.

5) If repo used to trigger builds but no longer does:
   - Re-send a delivery in GitHub (Recent Deliveries → Redeliver) and watch Jenkins System Log and job queue.
   - In Multibranch Pipelines: on the job page click **Scan Repository Now** to force detection; also verify branch indexing triggers are enabled.

6) Verify your agent is online and that the job isn't queued waiting for a label (Manage Nodes and Clouds → ensure `docker-agent` is online and labelled `docker`).

If you'd like, I can add a tiny curl-based health check to your ngrok URL that you can run remotely to confirm webhook reachability; tell me and I'll add it.

## Adding a Docker agent node (recommended)
If your pipeline requires a node labeled `docker` (recommended for running Docker build steps) follow these steps.

1) Create a node in Jenkins (UI):
   - Manage Jenkins → Manage Nodes and Clouds → **New Node**
   - Name: `docker-agent` (or `docker` if you prefer)
   - Type: Permanent Agent
   - Remote root directory: `/home/jenkins`
   - Labels: `docker`
   - Launch method: **Launch agent by connecting it to the controller** (this will give you the agent secret you need)

2) On the node page, copy the **Agent secret** and note the agent name.

Programmatic option (Configuration as Code + auto-service)

- You can automate node creation by enabling Configuration as Code (JCasC) plugin and pointing Jenkins to the included YAML `jenkins/casc/docker-agent.yml`.
  - Install the **Configuration as Code**s plugin in Jenkins.
  - In Jenkins: Manage Jenkins → Configuration as Code → Set the configuration source. You can either paste the contents of `jenkins/casc/docker-agent.yml` or point `CASC_JENKINS_CONFIG` to the raw URL of that file.
  - After Jenkins loads the YAML, the `docker-agent` node will be present and ready to accept JNLP connections.sss

- To retrieve the agent secret programmatically, use the Groovy script `jenkins/scripts/get_docker_agent_secret.groovy`.
  - Paste it into **Manage Jenkins → Script Console** and run; it will create the node (if missing) and print the JNLP secret for the agent.

- On the EC2 host you can install the agent as a systemd service so it starts automatically using the secret. Use the included installer script:

```bash
chmod +x ~/install_jenkins_agent_service.sh
sudo ./install_jenkins_agent_service.sh --jenkins-url "https://<your-ngrok-url>" --agent-name "docker-agent" --agent-secret "<agent-secret>"
```

This creates `/etc/systemd/system/jenkins-agent.service`, enables it, and starts the agent container with the Docker socket mounted so builds can run Docker.

Notes:
- For security, obtain the agent secret from Jenkins only after JCasC has created the node. The Groovy script prints the secret so you can pass it to the installer command.
- Do not commit secrets to git; pass them to the script or use a secure channel.

3) On your EC2 host (where Docker is installed) run the inbound-agent container. You can also use the provided start script if you prefer manual start (previous section):

```bash
# copy script to EC2 and run (example)
chmod +x ~/start_jenkins_agent.sh
./start_jenkins_agent.sh --jenkins-url "https://<your-ngrok-url>" --agent-name "docker-agent" --agent-secret "<the-agent-secret>"
```

The script will run the official `jenkins/inbound-agent` container and mount `/var/run/docker.sock` so the agent can run Docker commands.

4) Verify the agent is `online` in Jenkins and that it has the `docker` label.

Troubleshooting:
- If the agent won't start, check `docker logs jenkins-agent` on the EC2 host for errors.
- Ensure your Jenkins controller URL (ngrok) is reachable from the EC2 host and that the secret is correct.

## Common issues
- If SSH fails, ensure the Jenkins host IP is allowed by any local firewalls and the key matches the one associated with the EC2 instance.
- If Docker commands fail on the instance, ensure `docker` and `docker-compose` are installed and the `ubuntu` user belongs to the `docker` group.
