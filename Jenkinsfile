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
        docker build -t backend ./backend
        docker build -t frontend ./frontend

        docker tag backend $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:backend
        docker tag frontend $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:frontend

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
  }
}
