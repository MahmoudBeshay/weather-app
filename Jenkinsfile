pipeline {
  agent any

  stages {
    stage('Terraform Provisioning') {
      steps {
        withCredentials([
          usernamePassword(credentialsId: 'awsCred', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY'),
          string(credentialsId: 'awsKey', variable: 'PUBLIC_KEY')
        ]) {
          withEnv([
            "AWS_ACCESS_KEY_ID=${env.AWS_ACCESS_KEY_ID}",
            "AWS_SECRET_ACCESS_KEY=${env.AWS_SECRET_ACCESS_KEY}",
            "AWS_DEFAULT_REGION=us-east-1"
          ]) {
            dir('terraform') {
              sh '''
                terraform init
                echo 'Provisioning servers...'
                terraform apply -auto-approve -var="public_key=$PUBLIC_KEY"
                terraform destroy -auto-approve -var="public_key=$PUBLIC_KEY"
            
              '''
            }
          }
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
