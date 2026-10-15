
pipeline {
    agent any

    environment {
        PATH+DOCKER = 'C:\\Users\\srish\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin'
        IMAGE = 'hsri123/student-placement-portal'
        DEPLOYMENT = 'placement-deployment'
        CONTAINER = 'placement-container'
    }

    stages {

        // 1. CHECKOUT FROM GITHUB
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/SRISHTI-123-BYTE/ass8_q1.git'
            }
        }

        // 2. VERIFY DOCKER ACCESS
        stage('Check Docker') {
            steps {
                bat '''
                    where.exe docker
                    docker --version
                    docker info
                    if errorlevel 1 exit /b 1
                '''
            }
        }

        // 3. BUILD DOCKER IMAGE
        stage('Build Docker Image') {
            steps {
                bat '''
                    docker build -t %IMAGE%:%BUILD_NUMBER% .
                    if errorlevel 1 exit /b 1
                '''
            }
        }

        // 4. PUSH IMAGE TO DOCKER HUB
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
                        setlocal DisableDelayedExpansion
                        set "TOKENFILE=%WORKSPACE%\\docker-token.txt"

                        <nul set /p "=%DOCKER_PASS%" > "%TOKENFILE%"

                        docker login -u "%DOCKER_USER%" --password-stdin < "%TOKENFILE%"
                        set "LOGIN_STATUS=%ERRORLEVEL%"

                        del "%TOKENFILE%"

                        if not "%LOGIN_STATUS%"=="0" exit /b 1

                        docker push %IMAGE%:%BUILD_NUMBER%
                        if errorlevel 1 (
                            docker logout
                            exit /b 1
                        )

                        docker logout
                    '''
                }
            }
        }

        // 5. DEPLOY TO KUBERNETES AND ROLLBACK ON FAILURE
        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([
                    file(
                        credentialsId: 'kubeconfig',
                        variable: 'KUBECONFIG'
                    )
                ]) {
                    bat '''
                        @echo off

                        kubectl apply -f deployment.yaml
                        if errorlevel 1 exit /b 1

                        kubectl apply -f service.yaml
                        if errorlevel 1 exit /b 1

                        kubectl set image deployment/%DEPLOYMENT% %CONTAINER%=%IMAGE%:%BUILD_NUMBER%
                        if errorlevel 1 exit /b 1

                        kubectl rollout status deployment/%DEPLOYMENT% --timeout=120s

                        if errorlevel 1 (
                            echo Deployment failed. Rolling back to the previous stable revision...

                            kubectl rollout undo deployment/%DEPLOYMENT%

                            kubectl rollout status deployment/%DEPLOYMENT% --timeout=120s

                            exit /b 1
                        )
                    '''
                }
            }
        }

        // 6. VERIFY DEPLOYMENT
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
            echo 'SUCCESS: Student Placement Portal deployed!'
            echo 'Verify the application at http://localhost:30080'
        }

        failure {
            echo 'FAILED: Check Console Output for the first error.'
        }
    }
}
