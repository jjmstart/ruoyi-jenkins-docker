# ==========================================
# 第一阶段：兵工厂 (编译打包)
# ==========================================
FROM maven:3.8.6-eclipse-temurin-17 AS builder
WORKDIR /build

# 将当前目录下的 source 文件夹拷贝到容器的 /build 目录下
COPY ./source /build

# 执行 Maven 打包命令，并强制跳过测试
RUN mvn clean package -Dmaven.test.skip=true

# ==========================================
# 第二阶段：瘦身舱 (运行环境)
# ==========================================
# 使用 alpine 版本的轻量级 JRE 8 作为基础镜像
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# 从第一阶段 (builder) 拷贝战利品 (jar包) 到当前环境
COPY --from=builder /build/ruoyi-admin/target/ruoyi-admin.jar ./app.jar

# 声明容器需要暴露的端口
EXPOSE 8080

# 终极启动命令：注意 ENTRYPOINT 后面的空格！
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]