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
                // 切换到 kaniko 容器
                container('kaniko') {
                    // 使用 withCredentials 从 Jenkins 内部获取凭证，并绑定到环境变量
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds-jenkins', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_TOKEN')]) {
                        script {
                            echo 'Creating Docker config.json for Kaniko...'

                            // 手动创建 Kaniko 需要的 config.json 文件
                            // 1. 将 "用户名:访问令牌" 进行 Base64 编码
                            // 2. 将编码后的字符串写入一个 JSON 文件中
                            sh '''
                            DOCKER_AUTH=`echo -n "${DOCKER_USER}:${DOCKER_TOKEN}" | base64`
                            cat <<EOF > /kaniko/.docker/config.json
                            {
                              "auths": {
                                "https://index.docker.io/v1/": {
                                  "auth": "${DOCKER_AUTH}"
                                }
                              }
                            }
                            EOF
                            '''

                            echo 'Docker config created successfully. Starting Kaniko build...'

                            // Kaniko 的执行命令保持不变，它会自动读取我们刚刚创建的配置文件
                            sh """
                            /kaniko/executor --context `pwd` --dockerfile `pwd`/Dockerfile --destination ${env.DOCKER_HUB_USER}/${env.APP_NAME}:1.${env.BUILD_NUMBER}.0 --destination ${env.DOCKER_HUB_USER}/${env.APP_NAME}:latest
                            """
                        }
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
