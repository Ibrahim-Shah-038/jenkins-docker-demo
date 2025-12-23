pipeline {
  agent any

  environment {
    AWS_REGION = "eu-north-1"
    ECR_REPO = "jenkins-demo"
    AWS_ACCOUNT_ID = "402782411051"
  }

  stages {

    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Login to ECR') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
          sh '''
            aws ecr get-login-password --region $AWS_REGION \
            | docker login --username AWS --password-stdin \
            $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
          '''
        }
      }
    }

    stage('Build & Push Images') {
      steps {
        sh '''
        # Build using actual repository paths
        docker build -t backend ./ecommerce/ecommerce_backend
        docker build -t frontend ./frontend

        docker tag backend $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:backend
        docker tag frontend $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:frontend
        # ensure repository exists
        aws ecr describe-repositories --repository-names $ECR_REPO --region $AWS_REGION || \
          aws ecr create-repository --repository-name $ECR_REPO --region $AWS_REGION

        docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:backend
        docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:frontend
        '''
      }
    }

    stage('Terraform Deploy') {
      steps {
        dir('terraform') {
          sh '''
          terraform init
          terraform apply -auto-approve \
            -var="app_image=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:backend" \
            -var="frontend_image=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:frontend"
          '''
        }
      }
    }

    stage('Remote Deploy') {
      steps {
        script {
          // read the app public ip from terraform outputs
          dir('terraform') {
            APP_IP = sh(script: "terraform output -raw app_ip", returnStdout: true).trim()
          }
        }

        // Use SSH credential `ssh-deploy` to update running containers on the app server
        sshagent (credentials: ['ssh-deploy']) {
          sh '''
            set -e
            echo "Deploying to ${APP_IP}"
            ssh -o StrictHostKeyChecking=no ubuntu@${APP_IP} \
              "aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com || true"

            ssh -o StrictHostKeyChecking=no ubuntu@${APP_IP} \
              "docker pull $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:backend || true && docker stop app || true && docker rm app || true && docker run -d --name app --restart unless-stopped -p 8000:8000 $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:backend"

            ssh -o StrictHostKeyChecking=no ubuntu@${APP_IP} \
              "docker pull $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:frontend || true && docker stop frontend || true && docker rm frontend || true && docker run -d --name frontend --restart unless-stopped -p 80:80 $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:frontend"
          '''
        }
      }
    }
  }
}
