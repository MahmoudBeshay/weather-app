#this is a Jenkins pipeline script to deploy infrastructure by terraform and ansible

pipeline {
    
  agent { label 'terraform' }
    environment {
        AWS_ACCESS_KEY_ID = credentials('accessKeyid')
        AWS_SECRET_ACCESS_KEY = credentials('accessKeysec')
    }

    stages {
        stage('provisioning servers') {
            steps {
                dir('terraform') {
          sh 'terraform init'
          echo 'Provisioning servers...'
                

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