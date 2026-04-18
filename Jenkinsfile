// ============================================================
// Jenkinsfile —— Jenkins 声明式流水线 (Declarative Pipeline)
//
// 声明式流水线是 Groovy DSL 的一个子集，语法固定、结构清晰，
// 不需要深入了解 Groovy 语言本身即可编写。
// 整体结构：pipeline { } 是最外层的容器，所有配置都在其内部。
// ============================================================

pipeline {

    // ----------------------------------------------------------
    // agent：指定这条流水线在哪台 Jenkins 节点（Agent）上运行。
    // `any` 表示"任意可用节点均可"，Jenkins 会自动分配一台空闲节点。
    // 其他可选值：`none`（不分配全局节点）、`label 'xxx'`（指定标签）、
    // `docker { image 'xxx' }`（在容器内运行）等。
    // ----------------------------------------------------------
    agent any

    // ----------------------------------------------------------
    // environment：定义整条流水线范围内都能访问的环境变量。
    // 格式：变量名 = "值"。在后续 steps 中用 ${变量名} 引用。
    // Jenkins 自身也会注入一批内置变量，例如：
    //   BUILD_NUMBER —— 当前构建的自增序号（1、2、3…）
    //   WORKSPACE    —— 当前工作目录的绝对路径
    // ----------------------------------------------------------
    environment {
        // 定义镜像名称变量，后续 docker build / compose 统一引用，
        // 修改镜像名时只需改这一处。
        IMAGE_NAME = "ruoyi-jenkins-docker"
    }

    // ----------------------------------------------------------
    // stages：所有"阶段"的容器。一条流水线由一个或多个 stage 组成，
    // 每个 stage 代表 CI/CD 中的一个逻辑步骤（如：拉代码、构建、部署）。
    // stage 按顺序串行执行，任意一个失败则整条流水线标记为失败并停止。
    // ----------------------------------------------------------
    stages {

        // ------------------------------------------------------
        // stage('名称')：一个具体阶段，名称会显示在 Jenkins UI 的
        // 流水线视图里，便于快速定位哪一步出了问题。
        // ------------------------------------------------------
        stage('拉取代码 (Checkout)') {

            // steps：该阶段内要执行的具体操作列表，按顺序执行。
            steps {

                // echo：向控制台日志输出一行字符串，常用于打印进度信息。
                echo '正在从 GitHub 拉取最新代码...'

                // git：Jenkins 内置的 Git 插件步骤，用于拉取远程仓库代码。
                //   branch       —— 要拉取的分支名
                //   url          —— 仓库地址，这里使用 SSH 协议（git@…），
                //                   比 HTTPS 在国内服务器上更稳定
                //   credentialsId—— Jenkins 凭据 ID，对应在
                //                   「Jenkins → 凭据管理」中预先录入的
                //                   SSH 私钥，Jenkins 会自动注入到 git 命令中，
                //                   无需在代码里明文写密钥
                git branch: 'main',
                    url: 'git@github.com:jjmstart/ruoyi-jenkins-docker.git',
                    credentialsId: 'github-jjmstart-ssh'
            }
        }

        stage('多阶段构建 (Build Image)') {
            steps {
                echo '开始执行 Docker 多阶段构建 (编译 Maven + 打包 JRE 镜像)...'

                // sh：在 Agent 的 shell（默认 /bin/sh）中执行任意命令。
                // 这里执行 docker build，同时打两个标签：
                //   ${IMAGE_NAME}:latest      —— 始终指向最新版本，方便 compose 直接引用
                //   ${IMAGE_NAME}:${BUILD_NUMBER} —— 带构建号的历史版本标签，
                //                                    出现问题时可用 docker tag 快速回滚到指定版本
                // 末尾的 `.` 表示构建上下文为当前工作目录（即代码根目录），
                // Dockerfile 也默认从该目录下查找。
                sh 'docker build -t ${IMAGE_NAME}:latest -t ${IMAGE_NAME}:${BUILD_NUMBER} .'
            }
        }

        stage('滚动部署 (Deploy)') {
            steps {
                echo '开始部署到双节点高可用集群...'

                // 将预先存放在服务器固定路径下的 .env 文件复制到当前工作目录。
                // .env 中通常存储不应提交到 Git 的敏感配置（数据库密码、端口等），
                // docker compose 会自动读取同目录下的 .env 来填充 compose.yml 中的变量。
                sh 'cp /opt/docker/backend/ruoyi/.env .'

                // docker compose up -d --force-recreate：
                //   up          —— 启动 compose.yml 中定义的所有服务
                //   -d          —— detached 模式，后台运行，不阻塞流水线
                //   --force-recreate —— 即使容器配置没有变化也强制重新创建，
                //                       确保容器一定使用上一步刚构建出的最新镜像，
                //                       避免 Docker 因镜像层缓存而跳过更新
                sh 'docker compose up -d --force-recreate'
            }
        }
    }
    // ----------------------------------------------------------
    // （可扩展）post：所有 stages 执行完毕后的后置动作块，
    // 可按结果分别处理，例如：
    //   always  { … }  —— 无论成功失败都执行（如清理工作区）
    //   success { … }  —— 仅成功时执行（如发送成功通知）
    //   failure { … }  —— 仅失败时执行（如发送告警钉钉/邮件）
    // ----------------------------------------------------------
}