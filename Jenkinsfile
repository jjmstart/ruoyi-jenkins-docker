pipeline {
  agent any
  options {
    timestamps()
    disableConcurrentBuilds()
  }
  environment {
    REGISTRY_HOST = '100.118.69.78:5000'
    IMAGE_NAME    = 'ruoyi'
    GIT_SHORT_SHA = ''
    IMAGE_TAG     = ''
  }
  stages {
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
    stage('Docker Build') {
      when {
        anyOf {
          branch 'main'
          expression { env.GIT_BRANCH == 'origin/main' || env.BRANCH_NAME == 'main' }
        }
      }
      steps {
        sh '''
          set -eu
          DOCKER_BUILDKIT=1 docker build \
            -t ${REGISTRY_HOST}/${IMAGE_NAME}:${IMAGE_TAG} \
            -t ${REGISTRY_HOST}/${IMAGE_NAME}:latest \
            .
        '''
      }
    }
    stage('Docker Push') {
      when {
        anyOf {
          branch 'main'
          expression { env.GIT_BRANCH == 'origin/main' || env.BRANCH_NAME == 'main' }
        }
      }
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
      withCredentials([string(credentialsId: 'feishu-webhook-url', variable: 'FEISHU_URL')]) {
        sh '''
          set -eu
          curl -sf -X POST "$FEISHU_URL" \
            -H "Content-Type: application/json" \
            -d "{
              \"msg_type\": \"text\",
              \"content\": {
                \"text\": \"✅ [ruoyi] 新版本就绪：ruoyi:${IMAGE_TAG}，可手工触发部署。Build #${BUILD_NUMBER}\"
              }
            }"
        '''
      }
    }
    failure {
      withCredentials([string(credentialsId: 'feishu-webhook-url', variable: 'FEISHU_URL')]) {
        sh '''
          set -eu
          curl -sf -X POST "$FEISHU_URL" \
            -H "Content-Type: application/json" \
            -d "{
              \"msg_type\": \"text\",
              \"content\": {
                \"text\": \"❌ [ruoyi] 构建失败：Job #${BUILD_NUMBER}，请查看 Jenkins。\"
              }
            }"
        '''
      }
    }
  }
}
