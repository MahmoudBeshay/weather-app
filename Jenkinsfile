pipeline {
  agent any

  parameters {
    string(name: 'BASTION_IP', defaultValue: '52.87.160.47', description: 'Public IP of bastion host')
    string(name: 'PRIVATE_EC2_IP', defaultValue: '10.0.2.64', description: 'Private IP of target EC2')
    string(name: 'ALB_DNS', defaultValue: 'k8s-alb-839414935.us-east-1.elb.amazonaws.com', description: 'ALB DNS for ingress')
  }

  environment {
    GIT_REPO = 'https://github.com/MahmoudBeshay/weather-app.git'
    GIT_BRANCH = 'main'
    IMAGE_NAME = 'mahmoudbeshay/weatherapp'
    SSH_HOST = 'private-ec2'
  }

  stages {

    stage('Clone Repo (main branch)') {
      steps {
        git branch: "${GIT_BRANCH}", url: "${GIT_REPO}"
      }
    }

    stage('Build Docker Image') {
      steps {
        sh "docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} ."
      }
    }

    stage('Push to Docker Hub') {
      steps {
        withCredentials([
          usernamePassword(
            credentialsId: 'dockerCred',
            usernameVariable: 'DOCKER_USERNAME',
            passwordVariable: 'DOCKER_PASSWORD'
          )
        ]) {
          sh """
            echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
            docker push ${IMAGE_NAME}:${BUILD_NUMBER}
          """
        }
      }
    }

    stage('Deploy to Kubernetes via EC2') {
      steps {
        sshagent(['ansibleSshKey']) {
          sh """
            mkdir -p ~/.ssh

            cat <<EOF > ~/.ssh/config
Host bastion
  HostName ${params.BASTION_IP}
  User ubuntu

Host private-ec2
  HostName ${params.PRIVATE_EC2_IP}
  User ubuntu
  ProxyJump bastion
EOF

            chmod 600 ~/.ssh/config
            ssh-keyscan -H ${params.BASTION_IP} >> ~/.ssh/known_hosts
            ssh -o StrictHostKeyChecking=no bastion "ssh-keyscan -H ${params.PRIVATE_EC2_IP}" >> ~/.ssh/known_hosts

            ssh private-ec2 << 'ENDSSH'
set -ex

# Clone or pull the latest repo
if [ ! -d ~/weather-app ]; then
  git clone -b ${GIT_BRANCH} ${GIT_REPO}
else
    cd ~/weather-app
  git checkout main
  git reset --hard HEAD          # Discard local changes
  git pull origin main
fi

cd ~/weather-app

# Update image tag and ALB host in the deployment manifest
sed -i "s|image: .*|image: ${IMAGE_NAME}:${BUILD_NUMBER}|" deployment.yaml
sed -i "s|host: .*|host: ${ALB_DNS}|" deployment.yaml

# Apply Kubernetes manifests
kubectl apply -f .

echo "Deployed ${IMAGE_NAME}:${BUILD_NUMBER} to Kubernetes"
ENDSSH
          """
        }
      }
    }

    stage('Smoke Test') {
      steps {
        script {
          sh """
            echo "Running smoke test against ALB..."
            curl -f http://${params.ALB_DNS} || (echo "Smoke test failed" && exit 1)
            echo "Smoke test passed"
          """
        }
      }
    }

  }

  post {
    failure {
      echo "Pipeline failed. Check logs for details."
    }
    success {
      echo "Deployment pipeline completed successfully."
    }
  }
}

