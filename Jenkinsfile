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

    // stages {
        stage('Checkout Source Code') {
            steps {
                script {
                    // Add this line to automatically add bitbucket.org's key
                    sh 'mkdir -p ~/.ssh && ssh-keyscan bitbucket.org >> ~/.ssh/known_hosts'
                    sh 'chmod 600 "${BITBUCKET_SSH_KEY_FILE}"'
                    // 拉取 Git 仓库代码
                    // 假设您配置了 SSH 凭证 ID 为 bitbucket-ssh-key
                    // 如果是用户名/密码，使用 credentialsId: 'bitbucket-credentials'
                    // 或如果仓库是公开的，则无需凭证
                    git branch: 'main', credentialsId: 'bitbucket-ssh-key', url: 'git@bitbucket.org:yeang/rails8_demo.git' // <-- 替换为您的 Bitbucket 仓库 URL
                }
            }
        }

        stage('Build and Test Rails App') {
            steps {
                // 使用 jnlp 容器运行 Rails 相关命令
                container('jnlp') {
                    script {
                        // 运行 Rails 依赖安装
                        sh 'bundle install --without development test'
                        // 运行 Rails 测试 (如果您的项目有)
                        // sh 'bundle exec rails test'
                    }
                }
            }
        }

        // stage('Build and Push Rails Docker Image') {
            // steps {
                // // 切换到 kaniko 容器来执行 Docker 构建和推送
                // container('kaniko') {
                    // script {
                        // // 构建 Rails 应用镜像
                        // // --context: Dockerfile 所在的目录 (通常是项目根目录)
                        // // --destination: 推送的目标 Docker Hub 仓库
                        // sh """
                        // /kaniko/executor --context `pwd` --dockerfile `pwd`/Dockerfile --destination ${DOCKER_HUB_USER}/${APP_NAME}:${env.BUILD_NUMBER} --destination ${DOCKER_HUB_USER}/${APP_NAME}:latest
                        // """
                    // }
                // }
            // }
        // }

        // stage('Clean Up') {
            // steps {
                // script {
                    // echo "Build and push completed. Cleaning up workspace."
                    // // 可以在这里添加一些清理工作，例如删除旧的构建产物
                // }
            // }
        // }
    // }

    post {
        // always {
            // // 无论构建成功或失败，都会执行
            // cleanWs() // 清理 Jenkins 工作区
        // }
        always {
            // This block will run whether the build succeeds or fails.
            // We'll keep the pod alive for 900 seconds (15 minutes) for debugging.
            script {
                echo "Build finished. Pod will remain active for 15 minutes for debugging..."
                sleep 900
            }
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
