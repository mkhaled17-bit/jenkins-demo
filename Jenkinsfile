pipeline {
    agent any
    
// 1. Add a dropdown menu to choose "apply" or "destroy"
    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Choose whether to Create or Destroy infrastructure')
    }

    stages {
        // ... (Checkout stage goes here) ...

        stage('Provision Infrastructure') {
            steps {
                // The withCredentials step securely fetches the keys and 
                // exposes them as environment variables (AWS_ACCESS_KEY_ID, etc.)
                withCredentials([usernamePassword(credentialsId: 'awd-creds', // <-- MUST MATCH THE ID YOU CREATED
                                                  usernameVariable: 'AWS_ACCESS_KEY_ID', 
                                                  passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    
                    sh 'terraform init'
                    sh 'terraform plan'
                    sh 'terraform apply -auto-approve'
                }
            }
        }
    }
}