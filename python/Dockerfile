FROM python:3.10

WORKDIR /app

# 시스템 패키지 설치 (AWS CLI 포함)
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libsm6 \
    libxext6 \
    libglib2.0-0 \
    libgl1-mesa-glx \
    curl \
    unzip \
    git \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip \
    && rm -rf /var/lib/apt/lists/*

# Python 업그레이드
RUN pip install --upgrade pip

# AWS SDK와 기본 패키지 설치
RUN pip install --no-cache-dir boto3 python-dotenv

# MoviePy 의존성 설치 (성공한 방법 사용)
RUN pip install --no-cache-dir numpy==1.24.3
RUN pip install --no-cache-dir Pillow==10.0.1
RUN pip install --no-cache-dir imageio==2.31.1
RUN pip install --no-cache-dir imageio-ffmpeg==0.4.8
RUN pip install --no-cache-dir decorator==5.1.1
RUN pip install --no-cache-dir tqdm==4.65.0
RUN pip install --no-cache-dir proglog==0.1.10
RUN pip install --no-cache-dir moviepy==1.0.3

# requirements.txt 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# .env 파일 복사 (배포용 설정)
COPY .env .

# 애플리케이션 코드 복사
COPY . .

# utils 디렉토리가 있는지 확인하고 생성
RUN mkdir -p utils

# 포트 노출
EXPOSE 8000

# 환경 변수 설정
ENV AWS_DEFAULT_REGION=ap-northeast-2
ENV PYTHONPATH=/app

# 헬스체크 (간단한 버전)
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8000/ || exit 1

# 실행
CMD ["uvicorn", "ai_server:app", "--host", "0.0.0.0", "--port", "8000"]