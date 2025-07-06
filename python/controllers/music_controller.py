import os
import requests
from dotenv import load_dotenv
import streamlit as st

load_dotenv()  # .env 파일에서 환경변수 로드

# jamendo API 키 가져오기
jamendo_id = os.getenv('JAMENDO_CLIENT_ID')
jamendo_api_key = os.getenv('JAMENDO_API_KEY')

# 1. 변수에 값 할당하기
# jamendo_id = st.secrets["JAMENDO_ID"]["JAMENDO_CLIENT_ID"]
# jamendo_api_key = st.secrets["JAMENDO_API"]["JAMENDO_API_KEY"]

# 2. 값이 없으면 에러 처리
if not jamendo_api_key:
    raise ValueError("환경변수 'JAMENDO_API_KEY'가 설정되지 않았습니다.")

# 테마 목록과 키워드 매칭
THEME_KEYWORDS = {
    "잔잔한 피아노": "piano",
    "기타 멜로디": "guitar",
    "자연의 소리": "nature",
    "달빛": "moon",
    "하늘": "sky",
    "클래식": "classical",
}

    
def search_tracks_by_tag(tag="lullaby", limit=5):
    url = "https://api.jamendo.com/v3.0/tracks/"
    params = {
        "client_id": jamendo_id,
        "format": "json",
        "limit": limit,
        "tags": tag,
        "audioformat": "mp32"
    }

    response = requests.get(url, params=params)
    if response.status_code == 200:
        return response.json()["results"]
    else:
        return None

