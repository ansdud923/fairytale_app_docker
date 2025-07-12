import os
import openai
import tempfile
from playsound import playsound
import asyncio
from dotenv import load_dotenv
import streamlit as st
from openai import OpenAI
from io import BytesIO
import requests
import cv2
import numpy as np
from PIL import Image
import random
import re
from typing import Optional
import base64

# ===== 수정된 부분: Secrets Manager 사용 =====
try:
    # 운영 환경에서는 Secrets Manager 사용
    from utils.secrets import get_openai_key, get_stability_key, get_google_api_key
    print("🔐 Secrets Manager에서 API 키 로드 시도...")
    
    openai_api_key = get_openai_key()
    stability_api_key = get_stability_key()
    google_api_key = get_google_api_key()
    
    if not openai_api_key:
        print("⚠️ Secrets Manager에서 OpenAI 키를 찾을 수 없음, .env 파일 시도...")
        raise ImportError("Secrets Manager 연결 실패")
    else:
        print("✅ Secrets Manager에서 API 키 로드 성공!")
        
except (ImportError, Exception) as e:
    # 개발 환경이나 Secrets Manager 실패 시 .env 파일 사용
    print(f"🔄 .env 파일에서 API 키 로드 중... ({e})")
    load_dotenv()
    
    openai_api_key = os.getenv('OPENAI_API_KEY')
    stability_api_key = os.getenv('STABILITY_API_KEY')
    google_api_key = os.getenv('GOOGLE_API_KEY')

# API 키 검증
if not openai_api_key:
    raise ValueError("❌ OpenAI API Key가 설정되지 않았습니다. Secrets Manager 또는 .env 파일을 확인하세요.")

if not stability_api_key:
    print("⚠️ Stability API Key가 없습니다. 이미지 생성 기능이 제한될 수 있습니다.")

print(f"🔑 API 키 상태: OpenAI={'✅' if openai_api_key else '❌'}, Stability={'✅' if stability_api_key else '❌'}")

# OpenAI 클라이언트 초기화
openai.api_key = openai_api_key
client = OpenAI(api_key=openai_api_key)


# 동화 생성 함수
def generate_fairy_tale(name, thema):
    prompt = (
        f"""
        너는 동화 작가야.
        '{thema}'를 주제로, '{name}'이 주인공인 길고 아름다운 동화를 써줘.
        엄마가 아이에게 읽어주듯 다정한 말투로 써줘.
        """
    )
    try:
        completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=16384,
            temperature=0.5
        )
        return completion.choices[0].message.content
    except Exception as e:
        return f"동화 생성 중 오류 발생: {e}"


# OpenAI TTS를 사용하여 음성 데이터 생성 (파일 저장 없음)
def generate_openai_voice(text, voice="alloy", speed=1.0):
    try:
        # TTS 음성 생성
        response = openai.audio.speech.create(
            model="tts-1",
            voice=voice,
            input=text,
            speed=speed
        )
        
        # 바이너리 데이터 직접 반환
        return response.content
        
    except Exception as e:
        print(f"TTS 생성 오류: {e}")
        return None

def audio_to_base64(audio_data):
    """
    오디오 바이너리 데이터를 Base64로 인코딩
    모바일 앱에서 사용하기 위함
    """
    if audio_data:
        return base64.b64encode(audio_data).decode('utf-8')
    return None


# 중복되지 않는 파일명 생성 함수
def get_available_filename(base_name: str, extension: str = ".png", folder: str = ".") -> str:
    """
    중복되지 않는 파일명을 자동으로 생성
    예: fairy_tale_image.png, fairy_tale_image_1.png, ...
    """
    counter = 0
    while True:
        filename = f"{base_name}{f'_{counter}' if counter > 0 else ''}{extension}"
        filepath = os.path.join(folder, filename)
        if not os.path.exists(filepath):
            return filepath
        counter += 1

# 프롬프트 생성 함수 (staility_sdxl는 영어만 처리 가능)
def generate_image_prompt_from_story(fairy_tale_text: str) -> Optional[str]:
    """
    동화 내용을 기반으로 이미지 생성용 영어 프롬프트 생성
    """
    try:
        system_prompt = (
            "You are a prompt generator for staility_sdxl. "
            f"From the given {fairy_tale_text}, choose one vivid, heartwarming scene. "
            "Describe it in English in a single short sentence suitable for generating a simple, child-friendly fairy tale illustration style. "
            "Use a soft, cute, minimal detail. "
            "No text, no words, no letters, no signs, no numbers."
        )

        completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"다음은 동화야:\n\n{fairy_tale_text}\n\n이 동화에 어울리는 그림을 그릴 수 있도록 프롬프트를 영어로 짧게 써줘."}
            ],
            temperature=0.5,
            max_tokens=150
        )

        return completion.choices[0].message.content.strip()

    except Exception as e:
        print(f"이미지 프롬프트 생성 오류: {e}")
        return None


# ===== 수정된 부분: Stability API 키 동적 로딩 =====
def generate_image_from_fairy_tale(fairy_tale_text):
    """
    이미지 생성 함수 (staility_sdxl 사용)
    """
    try:
        endpoint = "https://api.stability.ai/v2beta/stable-image/generate/core"
        
        # API 키 확인
        if not stability_api_key:
            print("❌ Stability API 키가 설정되지 않았습니다.")
            return None
        
        # 동화 프롬프트 처리
        base_prompt = generate_image_prompt_from_story(fairy_tale_text)
        if not base_prompt:
            print("❌ 이미지 프롬프트 생성에 실패했습니다.")
            return None

        prompt = (
            "no text in the image "
            "Minimul detail "
            f"Please create a single, simple illustration that matches the content about {base_prompt}, in a child-friendly style. "
        )

        headers = {
            "Authorization": f"Bearer {stability_api_key}",
            "Accept": "image/*",
        }

        # multipart/form-data 형태로 데이터 전송
        files = {
            "prompt": (None, prompt),
            "model": (None, "stable-diffusion-xl-1024-v1-0"),
            "output_format": (None, "png"),
            "height": (None, "514"),
            "width": (None, "514"),
            "seed": (None, "1234")
        }

        response = requests.post(endpoint, headers=headers, files=files)

        if response.status_code == 200:
            save_path = get_available_filename("fairy_tale_image", ".png", folder=".")
            with open(save_path, "wb") as f:
                f.write(response.content)
            print(f"✅ 이미지 저장 완료: {save_path}")
            return save_path
        else:
            print(f"❌ 이미지 생성 실패: {response.status_code}")
            print("응답 내용:", response.text)
            return None

    except Exception as e:
        print(f"❌ 이미지 생성 중 오류 발생: {e}")
        return None


# 흑백 이미지 변환 (URL과 로컬 파일 모두 지원)
def convert_bw_image(image_input, save_path=None):
    try:
        print(f"🎨 [convert_bw_image] 변환 시작: {image_input}")
        
        # 저장 경로가 지정되지 않은 경우 자동 생성
        if save_path is None:
            save_path = get_available_filename("bw_fairy_tale_image", ".png", folder=".")
            print(f"🔍 [convert_bw_image] 자동 생성된 저장 경로: {save_path}")

        # URL인지 로컬 파일인지 판단
        if image_input.startswith(('http://', 'https://')):
            print(f"🌐 [convert_bw_image] URL에서 이미지 다운로드 중...")
            # URL에서 이미지 다운로드
            response = requests.get(image_input, timeout=30)
            if response.status_code != 200:
                raise Exception(f"이미지 다운로드 실패: HTTP {response.status_code}")
            image = Image.open(BytesIO(response.content)).convert("RGB")
            print(f"✅ [convert_bw_image] URL 이미지 로드 완료")
        else:
            print(f"📁 [convert_bw_image] 로컬 파일에서 이미지 로드 중...")
            # 로컬 파일에서 이미지 로드
            if not os.path.exists(image_input):
                raise Exception(f"로컬 파일을 찾을 수 없습니다: {image_input}")
            image = Image.open(image_input).convert("RGB")
            print(f"✅ [convert_bw_image] 로컬 이미지 로드 완료")

        # Numpy 배열로 변환
        np_image = np.array(image)
        print(f"🔍 [convert_bw_image] 이미지 크기: {np_image.shape}")

        # 흑백 변환
        gray = cv2.cvtColor(np_image, cv2.COLOR_RGB2GRAY)

        # 가우시안 블러로 노이즈 제거
        blurred = cv2.GaussianBlur(gray, (3, 3), 0)

        # 캐니 엣지 디텍션 (더 부드러운 선)
        edges = cv2.Canny(blurred, 50, 150)
        
        # 선 두께 조절
        kernel = np.ones((2,2), np.uint8)
        dilated_edges = cv2.dilate(edges, kernel, iterations=1)
        
        # 흰 배경에 검은 선
        line_drawing = 255 - dilated_edges
        
        # 이미지 저장
        cv2.imwrite(save_path, line_drawing)
        print(f"✅ [convert_bw_image] 흑백 변환 완료: {save_path}")
        
        return save_path
    
    except Exception as e:
        print(f"❌ [convert_bw_image] 변환 오류: {e}")
        return None