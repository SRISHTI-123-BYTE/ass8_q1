
pipeline {
    agent any

    environment {
        IMAGE = 'hsri123/student-placement-portal'
        DEPLOYMENT = 'placement-deployment'
        CONTAINER = 'placement-container'
        DOCKER_BIN = 'C:\\Users\\srish\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/SRISHTI-123-BYTE/ass8_q1.git'
            }
        }

        stage('Check Docker and Kubernetes') {
            steps {
                withEnv(["PATH=${DOCKER_BIN};${env.PATH}"]) {
                    bat '''
                        @echo off
                        echo Checking Docker...
                        where.exe docker
                        docker --version
                        if errorlevel 1 exit /b 1

                        docker info
                        if errorlevel 1 exit /b 1

                        echo Checking kubectl...
                        where.exe kubectl
                        if errorlevel 1 exit /b 1

                        kubectl version --client
                        if errorlevel 1 exit /b 1
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                withEnv(["PATH=${DOCKER_BIN};${env.PATH}"]) {
                    bat '''
                        @echo off
                        docker build -t %IMAGE%:%BUILD_NUMBER% .
                        if errorlevel 1 exit /b 1

                        docker tag %IMAGE%:%BUILD_NUMBER% %IMAGE%:latest
                        if errorlevel 1 exit /b 1
                    '''
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withEnv(["PATH=${DOCKER_BIN};${env.PATH}"]) {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'dockerhub-creds',
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_PASS'
                        )
                    ]) {
                        bat '''
                            @echo off
                            setlocal DisableDelayedExpansion

                            set "TOKENFILE=%WORKSPACE%\\docker-token.txt"
                            <nul set /p "=%DOCKER_PASS%" > "%TOKENFILE%"

                            docker login --username "%DOCKER_USER%" --password-stdin < "%TOKENFILE%"
                            set "LOGIN_STATUS=%ERRORLEVEL%"
                            del "%TOKENFILE%" 2>nul

                            if not "%LOGIN_STATUS%"=="0" exit /b 1

                            docker push %IMAGE%:%BUILD_NUMBER%
                            if errorlevel 1 (
                                docker logout
                                exit /b 1
                            )

                            docker push %IMAGE%:latest
                            if errorlevel 1 (
                                docker logout
                                exit /b 1
                            )

                            docker logout
                        '''
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withEnv(["PATH=${DOCKER_BIN};${env.PATH}"]) {
                    withCredentials([
                        file(
                            credentialsId: 'kubeconfig',
                            variable: 'KUBECONFIG'
                        )
                    ]) {
                        bat '''
                            @echo off
                            echo Checking kubectl path...
                            where.exe kubectl
                            if errorlevel 1 exit /b 1

                            echo Checking Kubernetes connection...
                            kubectl config current-context
                            if errorlevel 1 exit /b 1

                            kubectl get nodes
                            if errorlevel 1 exit /b 1

                            echo Applying Deployment...
                            kubectl apply -f deployment.yaml
                            if errorlevel 1 exit /b 1

                            echo Applying Service...
                            kubectl apply -f service.yaml
                            if errorlevel 1 exit /b 1

                            echo Updating image...
                            kubectl set image deployment/%DEPLOYMENT% %CONTAINER%=%IMAGE%:%BUILD_NUMBER%
                            if errorlevel 1 exit /b 1

                            echo Waiting for rollout...
                            kubectl rollout status deployment/%DEPLOYMENT% --timeout=180s

                            if errorlevel 1 (
                                echo Rollout failed. Attempting rollback...
                                kubectl rollout undo deployment/%DEPLOYMENT%
                                kubectl rollout status deployment/%DEPLOYMENT% --timeout=120s
                                exit /b 1
                            )
                        '''
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                withEnv(["PATH=${DOCKER_BIN};${env.PATH}"]) {
                    withCredentials([
                        file(
                            credentialsId: 'kubeconfig',
                            variable: 'KUBECONFIG'
                        )
                    ]) {
                        bat '''
                            @echo off
                            echo ===== Kubernetes Deployments =====
                            kubectl get deployments
                            if errorlevel 1 exit /b 1

                            echo ===== Pods =====
                            kubectl get pods -o wide
                            if errorlevel 1 exit /b 1

                            echo ===== Services =====
                            kubectl get services
                            if errorlevel 1 exit /b 1

                            echo ===== Rollout History =====
                            kubectl rollout history deployment/%DEPLOYMENT%
                            if errorlevel 1 exit /b 1

                            echo Deployment verification completed.
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'SUCCESS: Student Placement Portal deployed!'
            echo 'Application URL: http://localhost:30080'
        }

        failure {
            echo 'FAILED: Check Console Output for the first error.'
        }

        always {
            echo 'Jenkins pipeline execution finished.'
        }
    }
}
