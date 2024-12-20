pipeline {
    agent any
    environment {
        AWS_DEFAULT_REGION = "eu-central-1"
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/Rogatiq/AWS.git'
            }
        }
        stage('Init') {
            steps {
                sh 'terraform init'
            }
        }
        stage('Plan') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh """
                        terraform plan \\
                            -var "aws_access_key=${env.AWS_ACCESS_KEY_ID}" \\
                            -var "aws_secret_key=${env.AWS_SECRET_ACCESS_KEY}" \\
                    """
                }
            }
        }
        stage('Apply') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh """
                        terraform apply -auto-approve \\
                            -var "aws_access_key=${env.AWS_ACCESS_KEY_ID}" \\
                            -var "aws_secret_key=${env.AWS_SECRET_ACCESS_KEY}" \\
                    """
                }
            }
        }
    }
}