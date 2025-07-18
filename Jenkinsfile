pipeline {
  agent any
 
  environment {
    PRIVATE_KEY_FILE = 'ansible/k8s.pem'
  }
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
                 echo 'Fetching current public IP...'
                 MY_IP=$(curl -s https://checkip.amazonaws.com)/32
                 echo "Using allowed_ssh_cidr=${MY_IP}"
                 terraform apply -auto-approve \
                  -var="public_key=$PUBLIC_KEY" \
                  -var="allowed_ssh_cidr=${MY_IP}"
           
              '''
            }
          }
        }
      }
    }

    stage('dynamic inventory') {
      steps {
        //sleep(time: 30) // Wait for Terraform to finish provisioning
        echo 'Generating dynamic inventory...'
        sh './inventorygen.sh' 
        sh 'cat ansible/ansible-playbook/inventory.ini'
      }
    }

    stage('Configure Using Ansible') {
  steps {
    withCredentials([sshUserPrivateKey(credentialsId: 'ansibleSshKey', keyFileVariable: 'SSH_KEY_FILE')]) {
      sh '''
        echo "[INFO] SSH key is at: $SSH_KEY_FILE"
        mkdir -p ansible
        cp $SSH_KEY_FILE ansible/k8s.pem
        chmod 600 ansible/k8s.pem
        head -n 2 ansible/k8s.pem
      '''
    }
  }
}


   stage('Run Ansible Playbooks') {
      steps {
        dir('ansible/ansible-playbook') {
          sh '''
            ansible-playbook -i inventory.ini k8s.yaml
            ansible-playbook -i inventory.ini master.yaml
            ansible-playbook -i inventory.ini worker.yaml
          '''
        }
      } 
      } 
 

}
}
