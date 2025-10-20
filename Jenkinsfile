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
        HARBOR_DOMAIN = "harbor.ky2020.shop"
        PROJECT = "ruby"

        // 应用程序名称，用于构建 Docker 镜像标签
        APP_NAME = "rails8_demo" // <-- 替换为您的 Rails 应用名称

        CONFIG_REPO_URL_SSH = "https://github.com/yyandrew/argo.git"
        CONFIG_REPO_BRANCH = 'main'
        CONFIG_REPO_CREDENTIALS_ID = 'github-pat-with-username' // Jenkins 中创建的 SSH 凭证 ID

        // Git 提交时使用的用户信息
        GIT_COMMIT_AUTHOR_EMAIL = 'jenkins-ci@jenkins.local'
        GIT_COMMIT_AUTHOR_NAME = 'Jenkins CI'
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                script {
                    // 👇👇👇 这是解决问题的核心 👇👇👇
                    // 在执行 git 操作之前，先创建 .ssh 目录并自动扫描和添加 bitbucket.org 的主机密钥
                    sh 'mkdir -p ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts'
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
                    withCredentials([usernamePassword(credentialsId: 'harbor-creds-jenkins', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASSWORD')]) {
                        script {
                            echo 'Creating Docker config.json for Kaniko...'

                            // 手动创建 Kaniko 需要的 config.json 文件
                            // 1. 将 "用户名:访问令牌" 进行 Base64 编码
                            // 2. 将编码后的字符串写入一个 JSON 文件中
                            sh '''
                            DOCKER_AUTH=`echo -n "${DOCKER_USER}:${DOCKER_PASSWORD}" | base64`
                            cat <<EOF > /kaniko/.docker/config.json
                            {
                              "auths": {
                                "https://${HARBOR_DOMAIN}": {
                                  "auth": "${DOCKER_AUTH}"
                                }
                              }
                            }
                            EOF
                            '''

                            echo 'Docker config created successfully. Starting Kaniko build...'
                            def dest1 = "${HARBOR_DOMAIN}/${PROJECT}/${APP_NAME}:1.${BUILD_NUMBER}.0"
                            def dest2 = "${HARBOR_DOMAIN}/${PROJECT}/${APP_NAME}:latest"


                            // Kaniko 的执行命令保持不变，它会自动读取我们刚刚创建的配置文件
                            sh """
                            /kaniko/executor --context `pwd` --dockerfile `pwd`/Dockerfile --destination ${dest1} --destination ${dest2}
                            """
                        }
                    }
                }
            }
        }
        stage('Update Deployment Configuration in Git') {
            steps {
                script {
                    // 定义新的镜像标签
                    def newImageTag = "${env.APP_NAME}:1.${env.BUILD_NUMBER}.0"
                    def YQ_VERSION="v4.44.1" // 你可以指定一个具体的 yq 版本
                    def YQ_BINARY="yq_linux_amd64" // 根据你的 Agent 系统架构选择，amd64 是最常见的
                    echo "New image tag to be set: ${newImageTag}"

                    // 在一个独立的目录中 checkout 配置仓库，避免和主工作区冲突
                    dir('config-repo') {
                        // 1. 拉取配置仓库代码，使用我们配置的 SSH 凭证
                        echo "Checking out configuration repository: ${env.CONFIG_REPO_URL_SSH}"
                        checkout([
                            $class: 'GitSCM',
                            branches: [[name: env.CONFIG_REPO_BRANCH]],
                            userRemoteConfigs: [[
                                credentialsId: env.CONFIG_REPO_CREDENTIALS_ID,
                                url: env.CONFIG_REPO_URL_SSH
                            ]]
                        ])

                        // 2. 修改 values.yaml 文件
                        echo "Updating image tag in values.yaml..."
                        // 确保 yq 已安装在你的 Jenkins Agent 上
                        // sh 'which yq || (wget ... && chmod +x /usr/local/bin/yq)'
                        sh """
                        # 检查 yq 是否已存在，不存在则下载
                        if ! command -v yq &> /dev/null
                        then
                            echo "yq could not be found, installing it..."
                            wget "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY}" -O ./yq
                            chmod +x ./yq

                            # 定义一个别名或将当前目录加入 PATH，以便后续直接调用 yq
                            # 这里我们直接使用 './yq' 调用，更简单明确
                        else
                            echo "yq is already installed."
                        fi
                        # --- 结束：动态安装 yq ---
                        cd rails8_demo
                        yq -i '.image.tag = "${newImageTag}"' values.yaml
                        echo "Updated content of values.yaml:"
                        cat values.yaml
                        """

                        // 3. 提交并推送回 Git
                        echo "Committing and pushing changes to Git..."
                        sh """
                        # 配置 Git 用户信息，这样提交记录才知道作者是谁
                        git config user.email "${env.GIT_COMMIT_AUTHOR_EMAIL}"
                        git config user.name "${env.GIT_COMMIT_AUTHOR_NAME}"

                        # 将修改添加到暂存区
                        git add rails8_demo/values.yaml

                        # 检查是否有变更，只有在有变更时才提交，避免空提交
                        if ! git diff --staged --quiet; then
                            git commit -m "ci(deploy): Update image tag to ${newImageTag} for build #${env.BUILD_NUMBER}"
                            git push origin ${env.CONFIG_REPO_BRANCH}
                            echo "Changes pushed to Git successfully."
                        else
                            echo "No changes detected in values.yaml. Skipping commit."
                        fi
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
        always {
            // 清理工作区
            deleteDir()
        }
    }
}
