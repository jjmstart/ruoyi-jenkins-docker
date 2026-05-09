# ==========================================
# 第一阶段：构建阶段 (编译打包)
# 使用 Maven 官方镜像，包含 JDK 和 Maven 工具
# AS builder 给该阶段命名，方便第二阶段引用
# ==========================================
FROM maven:3.8.6-eclipse-temurin-17 AS builder

# 设置构建工作目录
WORKDIR /build

# 复制项目源代码到构建目录
# 假设源代码位于与 Dockerfile 同级的 source 目录
COPY ./source /build

# 执行 Maven 打包
# --mount=type=cache,target=/root/.m2: 缓存 Maven 本地仓库，加速后续构建
# clean: 清理之前的构建产物
# package: 编译并打包项目
# -Dmaven.test.skip=true: 跳过测试，加快构建速度
RUN --mount=type=cache,target=/root/.m2 \
    mvn clean package -Dmaven.test.skip=true

# ==========================================
# 第二阶段：运行阶段 (生产环境)
# 使用轻量级 JRE 镜像 (Alpine 版本)，体积更小
# 多阶段构建：最终镜像只包含运行时环境，不包含编译工具
# ==========================================
FROM eclipse-temurin:17-jre-alpine

# 设置应用运行的工作目录
WORKDIR /app

# 从第一阶段 (builder) 复制打包好的 jar 文件
# 只复制最终产物，不复制源代码和构建工具，大幅减小镜像体积
COPY --from=builder /build/ruoyi-admin/target/ruoyi-admin.jar ./app.jar

# 声明容器暴露的端口 (8080 是 RuoYi 默认端口)
EXPOSE 8080

# 容器启动命令
# 使用 sh -c 允许通过环境变量 JAVA_OPTS 传入 JVM 参数
# 例如: docker run -e JAVA_OPTS="-Xmx512m" <image>
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
