// Jenkinsfile for Ruby on Rails + Go (示例)

pipeline {
    // 使用我们在 Jenkins UI 中配置的 Kaniko Pod 模板
    agent {
        kubernetes {
            inheritFrom 'kaniko-builder'
        }
    }

    environment {
        // Docker Hub 用户名，从 Kubernetes Secret 挂载的环境变量中获取
        // 或者直接在这里硬编码您的 Docker Hub 用户名
        DOCKER_HUB_USER = "lg201" // <-- 替换为您的 Docker Hub 用户名

        // 应用程序名称，用于构建 Docker 镜像标签
        APP_NAME = "rails8_demo" // <-- 替换为您的 Rails 应用名称
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                script {
                    // 👇👇👇 这是解决问题的核心 👇👇👇
                    // 在执行 git 操作之前，先创建 .ssh 目录并自动扫描和添加 bitbucket.org 的主机密钥
                    sh 'mkdir -p ~/.ssh && ssh-keyscan bitbucket.org >> ~/.ssh/known_hosts'
                }
                // 现在，标准的 checkout scm 就可以成功运行了
                checkout scm
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                container('kaniko') {
                    script {
                        sh """
                        /kaniko/executor --context `pwd` --dockerfile `pwd`/Dockerfile --destination ${DOCKER_HUB_USER}/${APP_NAME}:${env.BUILD_NUMBER} --destination ${DOCKER_HUB_USER}/${APP_NAME}:latest
                        """
                    }
                }
            }
        }

    }

    post {
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
