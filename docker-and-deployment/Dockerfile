# 使用官方的 OpenJDK 17 作为基础镜像
FROM openjdk:17-jdk-slim

# 设置工作目录
WORKDIR /app

# 复制 Maven 包装器和 pom.xml
COPY mvnw .
COPY mvnw.cmd .
COPY pom.xml .
COPY .mvn .mvn

# 复制源代码
COPY src ./src

# 给 Maven 包装器执行权限
RUN chmod +x ./mvnw

# 构建应用
RUN ./mvnw clean package -DskipTests

# 暴露端口
EXPOSE 8080

# 设置环境变量
ENV SPRING_PROFILES_ACTIVE=docker
ENV JAVA_OPTS="-Xmx512m -Xms256m"

# 运行应用
CMD ["java", "-jar", "target/itwordslearning-0.0.1-SNAPSHOT.jar"] 