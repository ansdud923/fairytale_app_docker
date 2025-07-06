#!/bin/bash

# 에러 발생 시 스크립트 중단
set -e

echo "🚀 Fairytale Backend 시작 중..."

# 프로젝트 루트 디렉토리로 이동
cd /opt/fairytale

# .env 파일 존재 확인
if [ ! -f ".env" ]; then
    echo "❌ .env 파일을 찾을 수 없습니다!"
    exit 1
fi

echo "✅ .env 파일 로드 중..."
# .env 파일에서 환경변수 로드
set -a
source .env
set +a

# JAR 파일 존재 확인
JAR_FILE="spring_boot/build/libs/fairytale-0.0.1-SNAPSHOT.jar"
if [ ! -f "$JAR_FILE" ]; then
    echo "❌ JAR 파일을 찾을 수 없습니다: $JAR_FILE"
    echo "💡 gradle bootJar 명령으로 JAR 파일을 먼저 빌드해주세요."
    exit 1
fi

echo "✅ JAR 파일 확인됨: $JAR_FILE"

# 로그 디렉토리 생성
mkdir -p logs

# 환경변수 확인 (민감정보 제외)
echo "🔧 주요 설정 확인:"
echo "  - 서버 포트: ${SERVER_PORT}"
echo "  - 데이터베이스 호스트: ${DB_HOST}"

# JVM 옵션 설정
JVM_OPTS="-Xms512m -Xmx2g -XX:+UseG1GC"

echo "🔥 Spring Boot 애플리케이션 시작!"

# Spring Boot 애플리케이션 실행
exec java $JVM_OPTS \
    -Dspring.profiles.active=${SPRING_PROFILES_ACTIVE:-dev} \
    -Dfile.encoding=UTF-8 \
    -jar "$JAR_FILE"
