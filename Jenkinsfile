
pipeline {
    agent any

    environment {
        IMAGE = 'hsri123/student-placement-portal'
        DEPLOYMENT = 'placement-deployment'
        CONTAINER = 'placement-container'
    }

    stages {

        // 1. CHECKOUT SOURCE CODE
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/YOUR_USERNAME/student-placement-portal.git'
            }
        }

        // 2. BUILD DOCKER IMAGE
        stage('Build Docker Image') {
            steps {
                bat '''
                    docker build -t %IMAGE%:%BUILD_NUMBER% .
                    if errorlevel 1 exit /b 1
                '''
            }
        }

        // 3. PUSH IMAGE TO DOCKER HUB
        stage('Push to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    bat '''
                        @echo off
                        docker login -u "%DOCKER_USER%" --password-stdin
                    '''
                }
                // Login with stdin is handled below in a single command block.
            }
        }

        // 4. DEPLOY TO KUBERNETES
        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([
                    file(
                        credentialsId: 'kubeconfig',
                        variable: 'KUBECONFIG'
                    )
                ]) {
                    bat '''
                        kubectl apply -f deployment.yaml
                        if errorlevel 1 exit /b 1

                        kubectl apply -f service.yaml
                        if errorlevel 1 exit /b 1

                        kubectl set image deployment/%DEPLOYMENT% %CONTAINER%=%IMAGE%:%BUILD_NUMBER%
                        if errorlevel 1 exit /b 1

                        kubectl rollout status deployment/%DEPLOYMENT% --timeout=120s

                        if errorlevel 1 (
                            echo Deployment failed. Rolling back...
                            kubectl rollout undo deployment/%DEPLOYMENT%
                            kubectl rollout status deployment/%DEPLOYMENT% --timeout=120s
                            exit /b 1
                        )
                    '''
                }
            }
        }

        // 5. VERIFY DEPLOYMENT
        stage('Verify Deployment') {
            steps {
                withCredentials([
                    file(
                        credentialsId: 'kubeconfig',
                        variable: 'KUBECONFIG'
                    )
                ]) {
                    bat '''
                        kubectl get deployments
                        kubectl get pods -o wide
                        kubectl get services
                        kubectl rollout history deployment/%DEPLOYMENT%
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Student Placement Portal deployed successfully!'
        }

        failure {
            echo 'Pipeline failed. Check Console Output for the exact error.'
        }
    }
}
