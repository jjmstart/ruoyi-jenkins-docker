# ==========================================
# 第一阶段：兵工厂 (编译打包)
# ==========================================
FROM maven:3.8.6-eclipse-temurin-17 AS builder
WORKDIR /build

COPY ./source /build

RUN --mount=type=cache,target=/root/.m2 \
    mvn clean package -Dmaven.test.skip=true

# ==========================================
# 第二阶段：瘦身舱 (运行环境)
# ==========================================
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

COPY --from=builder /build/ruoyi-admin/target/ruoyi-admin.jar ./app.jar

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
