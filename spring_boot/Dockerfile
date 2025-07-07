FROM openjdk:17-jdk-slim

WORKDIR /app

# AWS CLI 설치 (Secrets Manager 접근용)
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip \
    && rm -rf /var/lib/apt/lists/*

# Gradle 파일들 복사
COPY gradlew .
COPY gradle gradle
COPY build.gradle .
COPY settings.gradle .

# .env 파일 복사 (배포용 설정)
COPY .env .

# 소스 코드 복사
COPY src src

# 실행 권한 부여
RUN chmod +x gradlew

# 애플리케이션 빌드
RUN ./gradlew build -x test

# JAR 파일 복사 (올바른 방법)
RUN find build/libs -name "*.jar" -not -name "*plain*" -exec cp {} app.jar \;

# 포트 노출
EXPOSE 8080

# 환경 변수 설정
ENV AWS_DEFAULT_REGION=ap-northeast-2

# 헬스체크
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# 실행
ENTRYPOINT ["java", "-jar", "app.jar"]