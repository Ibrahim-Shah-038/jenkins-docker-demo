pipeline {
  agent any

  parameters {
    string(name: 'BRANCH_NAME', defaultValue: 'main', description: 'Git branch to deploy')
  }

  environment {
    REPO_URL = 'https://github.com/Ibrahim-Shah-038/jenkins-docker-demo.git'
    INSTANCE_IP = '56.228.16.53'    // change if IP changes
    SSH_CREDENTIALS_ID = 'ec2-key' // Jenkins credential id for "SSH Username with private key"
    DEPLOY_PATH = '/home/ubuntu/jenkins-docker-demo'
    GIT_BRANCH = "${params.BRANCH_NAME}"
  }

  stages {
    stage('Diagnostics') {
      steps {
        script {
          // Print high-level cause information and environment for debugging webhook triggers
          def causes = []
          try {
            causes = currentBuild.rawBuild.getCauses().collect { it.toString() }
          } catch (err) {
            causes = ["could not read causes: ${err}"]
          }
          echo "BUILD CAUSES: ${causes.join(', ')}"
          echo "GIT_BRANCH: ${env.GIT_BRANCH}"
          echo "REPO_URL: ${env.REPO_URL}"
          // Print a short system check so we know the agent can run shell steps
          sh 'echo --- uname ---; uname -a || true'
          sh 'echo --- env ---; env | sort || true'
        }
      }
    }

    stage('Checkout') {
      steps {
        echo "Checking out ${env.GIT_BRANCH}"
        checkout([$class: 'GitSCM', branches: [[name: "*/${env.GIT_BRANCH}"]], userRemoteConfigs: [[url: env.REPO_URL]]])
      }
    }

    stage('Build & Tests (optional)') {
      steps {
        echo 'You can run unit tests or linter here. This repo currently uses django + frontend tests if added.'
      }
    }

    stage('Deploy to EC2 (ssh)') {
      steps {
        echo 'Deploying to remote EC2 via SSH and docker-compose...'
        sshagent(credentials: [env.SSH_CREDENTIALS_ID]) {
          sh """
            ssh -o StrictHostKeyChecking=no ubuntu@${env.INSTANCE_IP} 'mkdir -p ${env.DEPLOY_PATH} && cd ${env.DEPLOY_PATH} || true'

            # clone if not present, otherwise fetch and reset
            ssh -o StrictHostKeyChecking=no ubuntu@${env.INSTANCE_IP} '
              if [ ! -d "${env.DEPLOY_PATH}/.git" ]; then
                git clone ${env.REPO_URL} ${env.DEPLOY_PATH};
              fi
              cd ${env.DEPLOY_PATH};
              git fetch --all;
              git reset --hard origin/${env.GIT_BRANCH};

              # Build and run using docker-compose (assumes docker & docker-compose installed)
              docker-compose build --pull;
              docker-compose up -d --remove-orphans;
            '
          """
        }
      }
    }

    stage('Smoke Check') {
      steps {
        echo 'Run a simple smoke check (optional) against the app public IP or endpoints.'
        // Example: sh "curl -f http://${env.INSTANCE_IP}:80/ || exit 1"
      }
    }

  }

  post {
    success {
      echo 'Deployment finished successfully.'
    }
    failure {
      echo 'Deployment failed — check logs.'
    }
  }
}
