pipeline {
    agent any
    
    stages {
        // ... (Checkout stage goes here) ...

        stage('Provision Infrastructure') {
            steps {
                // The withCredentials step securely fetches the keys and 
                // exposes them as environment variables (AWS_ACCESS_KEY_ID, etc.)
                withCredentials([usernamePassword(credentialsId: 'aws-creds', // <-- MUST MATCH THE ID YOU CREATED
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