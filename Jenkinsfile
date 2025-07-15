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
                echo 'Provisioning servers...'
                terraform apply -auto-approve -var="public_key=$PUBLIC_KEY"
           
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
        withCredentials([string(credentialsId: 'ansibleKey', variable: 'PRIVATE_KEY')]) {
        script {
        writeFile file: env.PRIVATE_KEY_FILE, text: PRIVATE_KEY
        }
        sh '''
        chmod 600 $PRIVATE_KEY_FILE
        echo "Key preview:"
        head -n 3 $PRIVATE_KEY_FILE
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
