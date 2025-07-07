import boto3
import json
import os
from botocore.exceptions import ClientError
from dotenv import load_dotenv

# .env 파일 로드
load_dotenv()

def get_secret():
    """AWS Secrets Manager에서 비밀 정보 가져오기"""
    secret_name = os.getenv("AWS_SECRET_NAME", "fairytale-secrets")
    region_name = os.getenv("AWS_REGION", "ap-northeast-2")

    # AWS 환경에서는 Secrets Manager 사용
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
        secret = json.loads(get_secret_value_response['SecretString'])
        return secret
    except ClientError as e:
        print(f"Secret Manager 오류: {e}")
        # 개발 환경 폴백 (로컬 테스트용)
        if os.getenv("ENVIRONMENT") == "development":
            return {
                "DB_HOST": os.getenv("DB_HOST", "localhost"),
                "DB_PORT": os.getenv("DB_PORT", "5432"),
                "DB_NAME": os.getenv("DB_NAME", "fairytale_dev"),
                "DB_USERNAME": os.getenv("DB_USERNAME", "postgres"),
                "DB_PASSWORD": os.getenv("DB_PASSWORD", "dev_password"),
                "OPENAI_API_KEY": os.getenv("OPENAI_API_KEY", ""),
                "S3_BUCKET_NAME": "fairytale-bucket-nahyun",
            }
        raise e

# 전역 변수로 설정
SECRETS = get_secret()

# 편의 함수들
def get_openai_key():
    return SECRETS.get("OPENAI_API_KEY", "")

def get_google_api_key():
    return SECRETS.get("GOOGLE_API_KEY", "")

def get_jamendo_keys():
    return {
        "client_id": SECRETS.get("JAMENDO_CLIENT_ID", ""),
        "api_key": SECRETS.get("JAMENDO_API_KEY", "")
    }

def get_stability_key():
    return SECRETS.get("STABILITY_API_KEY", "")

def get_database_config():
    return {
        "host": SECRETS.get("DB_HOST"),
        "port": int(SECRETS.get("DB_PORT", 5432)),
        "database": SECRETS.get("DB_NAME"),
        "username": SECRETS.get("DB_USERNAME"),
        "password": SECRETS.get("DB_PASSWORD")
    }

def get_s3_config():
    return {
        "bucket_name": SECRETS.get("S3_BUCKET_NAME"),
        "region": SECRETS.get("AWS_REGION", "ap-northeast-2")
    }

def get_jwt_config():
    return {
        "secret": SECRETS.get("JWT_SECRET"),
        "expiration": int(SECRETS.get("JWT_EXPIRATION", 3600000)),
        "refresh_expiration": int(SECRETS.get("JWT_REFRESH_EXPIRATION", 1209600000))
    }