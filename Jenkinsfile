pipeline {
    // 1. Define the parameters the user must choose when starting the build
    parameters {
        choice(name: 'ACTION', choices: ['apply', 'plan', 'destroy'], description: 'Select the Terraform action to run.')
    }

    // 2. Use a Docker image that has Terraform installed to guarantee the tool is available.
    agent {
        docker {
            image 'hashicorp/terraform:latest'
            // Use this to ensure the workspace is correctly mounted
            label 'jenkins-agent' 
        }
    }

    // Environment variables (optional, but good for centralizing configuration)
    environment {
        // Defines the name of the plan artifact file
        PLAN_FILE = "tfplan" 
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                // Terraform automatically reads AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY for authentication
                withCredentials([usernamePassword(credentialsId: 'awd-creds', 
                                                  usernameVariable: 'AWS_ACCESS_KEY_ID', 
                                                  passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh 'terraform init'
                }
            }
        }

        // 3. This stage runs ONLY if you select 'plan' or 'apply'. 
        // It always creates the plan file.
        stage('Terraform Plan') {
            when {
                anyOf {
                    expression { params.ACTION == 'apply' }
                    expression { params.ACTION == 'plan' }
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'awd-creds', 
                                                  usernameVariable: 'AWS_ACCESS_KEY_ID', 
                                                  passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    // Create and save the plan to a file. 
                    // This is best practice for apply to ensure what you see is what you get.
                    sh "terraform plan -out ${env.PLAN_FILE}"
                }
            }
        }
        
        // 4. This stage runs ONLY if you select 'apply' and uses the saved plan.
        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'awd-creds', 
                                                  usernameVariable: 'AWS_ACCESS_KEY_ID', 
                                                  passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    // Apply the saved plan file
                    sh "terraform apply -auto-approve ${env.PLAN_FILE}"
                }
            }
        }

        // 5. This stage runs ONLY if you select 'destroy'
        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'awd-creds', 
                                                  usernameVariable: 'AWS_ACCESS_KEY_ID', 
                                                  passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh 'terraform destroy -auto-approve'
                }
            }
        }
    }
}