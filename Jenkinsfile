// Jenkinsfile for Ruby on Rails + Go (示例)

pipeline {
    // 使用我们在 Jenkins UI 中配置的 Kaniko Pod 模板
    agent {
        kubernetes {
            label 'kaniko-builder'
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
                // This simple checkout will now work perfectly because the agent
                // is automatically configured with the correct SSH keys.
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

        stage('Clean Up') {
            steps {
                cleanWs() // Clean up the workspace
            }
        }
    }

    post {
        always {
            // 无论构建成功或失败，都会执行
            cleanWs() // 清理 Jenkins 工作区
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
