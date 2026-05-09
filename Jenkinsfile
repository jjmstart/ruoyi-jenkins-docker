// RuoYi 后端镜像：拉取代码 → Docker 构建 → 推送到私有仓库 → 飞书通知
pipeline {
  agent any
  options {
    timestamps()              // 日志带时间戳，便于排查
    disableConcurrentBuilds() // 同一 Job 不并行，避免镜像 tag / 推送冲突
  }
  environment {
    REGISTRY_HOST = '100.118.69.78:5000' // 私有 Docker Registry 地址（无 https 前缀用于 docker login）
    IMAGE_NAME    = 'ruoyi'             // 仓库中的镜像名
  }
  stages {
    // 检出仓库并生成镜像标签：BUILD_NUMBER + 短 SHA，唯一且可追溯提交
    stage('Checkout') {
      steps {
        git branch: 'main',
            url: 'git@github.com:jjmstart/ruoyi-jenkins-docker.git',
            credentialsId: 'github-jjmstart-ssh'
        script {
          env.GIT_SHORT_SHA = sh(
            script: 'git rev-parse --short HEAD',
            returnStdout: true
          ).trim()
          env.IMAGE_TAG = "${BUILD_NUMBER}-${env.GIT_SHORT_SHA}"
        }
      }
    }
    // BuildKit 加速构建；同时打版本 tag 与 latest，便于固定版本与滚动最新
    stage('Docker Build') {
      steps {
        sh '''
          set -eu
          echo "Building image tag: ${IMAGE_TAG}"
          DOCKER_BUILDKIT=1 docker build \
            -t ${REGISTRY_HOST}/${IMAGE_NAME}:${IMAGE_TAG} \
            -t ${REGISTRY_HOST}/${IMAGE_NAME}:latest \
            .
        '''
      }
    }
    // 使用 Jenkins 凭据登录 Registry，推送两个 tag 后登出，避免凭据残留在节点上
    stage('Docker Push') {
      steps {
        withCredentials([
          usernamePassword(
            credentialsId: 'registry-credentials',
            usernameVariable: 'REGISTRY_USER',
            passwordVariable: 'REGISTRY_PASS'
          )
        ]) {
          sh '''
            set -eu
            echo "${REGISTRY_PASS}" | docker login http://${REGISTRY_HOST} \
              -u "${REGISTRY_USER}" --password-stdin
            docker push ${REGISTRY_HOST}/${IMAGE_NAME}:${IMAGE_TAG}
            docker push ${REGISTRY_HOST}/${IMAGE_NAME}:latest
            docker logout http://${REGISTRY_HOST}
          '''
        }
      }
    }
  }
  post {
    success {
      // 构建成功：飞书文本通知，提示镜像 tag，便于人工触发下游部署
      withCredentials([string(credentialsId: 'feishu-webhook-url-jenkins-notify', variable: 'FEISHU_URL')]) {
        sh '''
          set -eu
          cat > feishu-payload.json <<EOF
{
  "msg_type": "text",
  "content": {
    "text": "✅ [ruoyi] 新版本就绪：ruoyi:${IMAGE_TAG}，可手工触发部署。Build #${BUILD_NUMBER}"
  }
}
EOF
          curl -sS -f -X POST "$FEISHU_URL" \
            -H "Content-Type: application/json" \
            --data-binary @feishu-payload.json
        '''
      }
    }
    failure {
      // 构建失败：飞书告警，便于及时处理
      withCredentials([string(credentialsId: 'feishu-webhook-url-jenkins-notify', variable: 'FEISHU_URL')]) {
        sh '''
          set -eu
          cat > feishu-payload.json <<EOF
{
  "msg_type": "text",
  "content": {
    "text": "❌ [ruoyi] 构建失败：Job #${BUILD_NUMBER}，请查看 Jenkins。"
  }
}
EOF
          curl -sS -f -X POST "$FEISHU_URL" \
            -H "Content-Type: application/json" \
            --data-binary @feishu-payload.json
        '''
      }
    }
  }
}
