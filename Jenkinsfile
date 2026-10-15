
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
                        echo ===== Docker =====
                        where.exe docker
                        docker --version
                        if errorlevel 1 exit /b 1
                        docker info
                        if errorlevel 1 exit /b 1

                        echo ===== Kubernetes CLI =====
                        where.exe kubectl.exe
                        if errorlevel 1 exit /b 1
                        kubectl.exe version --client
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

                            echo ===== Confirm kubectl executable =====
                            where.exe kubectl.exe
                            if errorlevel 1 exit /b 1

                            echo ===== Confirm cluster connection =====
                            kubectl.exe config current-context
                            if errorlevel 1 exit /b 1

                            kubectl.exe get nodes
                            if errorlevel 1 exit /b 1

                            echo ===== Apply deployment =====
                            kubectl.exe apply -f deployment.yaml
                            if errorlevel 1 exit /b 1

                            echo ===== Apply service =====
                            kubectl.exe apply -f service.yaml
                            if errorlevel 1 exit /b 1

                            echo ===== Update image =====
                            kubectl.exe set image deployment/%DEPLOYMENT% %CONTAINER%=%IMAGE%:%BUILD_NUMBER%
                            if errorlevel 1 exit /b 1

                            echo ===== Wait for rollout =====
                            kubectl.exe rollout status deployment/%DEPLOYMENT% --timeout=180s

                            if errorlevel 1 (
                                echo Rollout failed. Attempting rollback...
                                kubectl.exe rollout undo deployment/%DEPLOYMENT%
                                kubectl.exe rollout status deployment/%DEPLOYMENT% --timeout=120s
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

                            echo ===== Deployments =====
                            kubectl.exe get deployments
                            if errorlevel 1 exit /b 1

                            echo ===== Pods =====
                            kubectl.exe get pods -o wide
                            if errorlevel 1 exit /b 1

                            echo ===== Services =====
                            kubectl.exe get services
                            if errorlevel 1 exit /b 1

                            echo ===== Rollout History =====
                            kubectl.exe rollout history deployment/%DEPLOYMENT%
                            if errorlevel 1 exit /b 1

                            echo Verification completed.
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'SUCCESS: Student Placement Portal deployed successfully.'
            echo 'Application URL: http://localhost:30080'
        }

        failure {
            echo 'FAILED: Read the first error in Console Output.'
        }

        always {
            echo 'Pipeline execution finished.'
        }
    }
}
