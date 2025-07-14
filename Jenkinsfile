pipeline {
    agent any

    stages {
        stage('Build image') {
            steps {
                echo 'Building image'
                sh 'docker build -t mahmoudbeshay/weatherapp:1.0 .'
                
                withCredentials([usernamePassword(credentialsId: 'dockerCred', usernameVariable: 'user', passwordVariable: 'password')]) {
                    sh '''
                        echo "$password" | docker login -u "$user" --password-stdin
                        docker push mahmoudbeshay/weatherapp:1.0
                    '''
                }
            }
        }

        stage('Hello') {
            steps {
                echo 'Hello World'
            }
        }
    }
}
