pipeline {
  agent any 



  stages {


    stage('Provisioning Servers') {
      steps {
        dir('terraform/') {
          sh 'terraform init'
          echo 'Provisioning servers...'
          withCredentials([string(credentialsId: 'my-public-key', variable: 'PUBLIC_KEY')]) {
    sh "terraform apply -auto-approve -var='public_key=${PUBLIC_KEY}'"
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
