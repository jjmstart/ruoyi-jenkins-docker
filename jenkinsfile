pipeline {
    agent any
    
    environment {
        // 定义我们要构建的镜像名称
        IMAGE_NAME = "ruoyi-jenkins-docker"
    }
    
    stages {
        stage('拉取代码 (Checkout)') {
            steps {
                echo '正在从 GitHub 拉取最新代码...'
                // 使用 SSH 协议拉取，避免国内服务器 HTTPS 访问 GitHub 不稳定的问题
                git branch: 'main', 
                    url: 'git@github.com:jjmstart/ruoyi-jenkins-docker.git',
                    credentialsId: 'github-jjmstart-ssh'
            }
        }
        
        stage('多阶段构建 (Build Image)') {
            steps {
                echo '开始执行 Docker 多阶段构建 (编译 Maven + 打包 JRE 镜像)...'
                // 打包镜像，并打上 latest 标签和当前构建号标签 (方便以后回滚)
                sh 'docker build -t ${IMAGE_NAME}:latest -t ${IMAGE_NAME}:${BUILD_NUMBER} .'
            }
        }
        
        stage('滚动部署 (Deploy)') {
            steps {
                echo '开始部署到双节点高可用集群...'
                sh 'cp /opt/docker/backend/ruoyi/.env .'
                // 核心魔法：强制重新创建容器，让双子塔加载刚刚构建出的最新镜像！
                sh 'docker compose up -d --force-recreate'
            }
        }
    }
}