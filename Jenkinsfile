pipeline {
  agent any 

  environment {
    AWS_ACCESS_KEY_ID     = credentials('accessKeyid')
    AWS_SECRET_ACCESS_KEY = credentials('accessKeysec')
    AWS_SESSION_TOKEN = credentials('sessionToken')
  }

  stages {
    stage('Validate AWS Credentials') {
     steps {
    sh '''
      echo "Testing AWS credentials..."
      aws sts get-caller-identity
    '''
  }
}

    stage('Provisioning Servers') {
      steps {
        dir('terraform/') {
          sh 'terraform init'
          echo 'Provisioning servers...'
          sh 'terraform apply -auto-approve'
        }
      }
    }

    stage('Test') {
      steps {
        echo 'Testing...'
      }
    }

    stage('Deploy') {
      steps {
        echo 'Deploying...'
      }
    }
  }
}
