import os
import requests
from dotenv import load_dotenv
import streamlit as st
from openai import OpenAI
from langchain.tools import DuckDuckGoSearchRun
from langchain.agents import initialize_agent, AgentType
from langchain.chat_models import ChatOpenAI

load_dotenv()  # .env 파일에서 환경변수 로드

# GOOGLE API 키 가져오기
google_api_key = os.getenv('GOOGLE_API_KEY')

## 1. 변수에 값 할당하기
# google_api_key = st.secrets["GOOGLE"]["GOOGLE_API_KEY"]

## 2. 값이 없으면 에러 처리
# if not google_api_key:
#     raise ValueError("환경변수 'GOOGLE_API_KEY'가 설정되지 않았습니다.")



# 테마 목록과 키워드 매칭
THEME_KEYWORDS = {
    "piano": "piano",
    "guitar": "guitar",
    "nature": "nature sounds",
    "moon": "moonlight", 
    "sky": "sky",
    "classical": "classical",
}

def search_videos(theme):
    keyword = THEME_KEYWORDS.get(theme, "")
    if not keyword:
        return []

    query = f"{keyword} baby lullabby"
    url = (
        f"https://www.googleapis.com/youtube/v3/search"
        f"?part=snippet&maxResults=5&type=video&q={query}&key={google_api_key}"
    )

    response = requests.get(url)

    # 응답코드가 200이 아닐 때 (응답 실패)
    if response.status_code != 200:
        print(f"YouTube API 요청 실패: {response.status_code}")
        return []
    
    data = response.json()
    results = []

    for item in data.get("items", []):
        video_id = item["id"]["videoId"]
        title = item["snippet"]["title"]
        thumbnail = item["snippet"]["thumbnails"]["medium"]["url"]
        video_url = f"https://www.youtube.com/watch?v={video_id}"

        results.append({
            "title": title,
            "url": video_url,
            "thumbnail": thumbnail
        })

    return results
        

# controllers/video_controller.py (기존 파일에 아래 내용 추가)

# 🎬 비디오 생성 관련 함수들을 기존 파일 끝에 추가해주세요:

import uuid
import tempfile
import logging
from datetime import datetime
from pydantic import BaseModel
from typing import Optional

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 🎬 비디오 생성을 위한 새로운 함수들 (기존 코드 아래에 추가)

def create_video_from_image_audio(image_url: str, audio_url: str, story_title: str):
    """
    이미지와 오디오를 결합하여 비디오 생성
    """
    try:
        logger.info(f"🎬 비디오 생성 시작 - 이미지: {image_url}, 오디오: {audio_url}")
        
        # moviepy가 설치되어 있는지 확인
        try:
            from moviepy.editor import ImageClip, AudioFileClip, CompositeVideoClip
        except ImportError:
            logger.error("❌ moviepy가 설치되지 않았습니다. 'pip install moviepy' 실행")
            raise Exception("moviepy 라이브러리가 필요합니다.")
        
        # 임시 디렉토리 생성
        temp_dir = tempfile.mkdtemp()
        
        # 1. 이미지 다운로드
        image_path = download_file_from_url(image_url, temp_dir, "image")
        logger.info(f"📥 이미지 다운로드 완료: {image_path}")
        
        # 2. 오디오 다운로드
        audio_path = download_file_from_url(audio_url, temp_dir, "audio")
        logger.info(f"📥 오디오 다운로드 완료: {audio_path}")
        
        # 3. 비디오 생성
        output_path = os.path.join(temp_dir, f"video_{uuid.uuid4().hex[:8]}.mp4")
        
        # MoviePy로 비디오 생성
        audio_clip = AudioFileClip(audio_path)
        audio_duration = audio_clip.duration
        
        # 이미지를 오디오 길이만큼 재생되는 비디오로 변환
        image_clip = ImageClip(image_path, duration=audio_duration)
        
        # 이미지 크기 조정 (1080p 기준)
        image_clip = image_clip.resize(height=1080)
        
        # 오디오와 이미지 결합
        final_clip = image_clip.set_audio(audio_clip)
        
        # 비디오 파일로 저장
        final_clip.write_videofile(
            output_path,
            codec='libx264',
            audio_codec='aac',
            temp_audiofile=os.path.join(temp_dir, "temp_audio.m4a"),
            remove_temp=True,
            fps=24
        )
        
        # 메모리 정리
        audio_clip.close()
        image_clip.close()
        final_clip.close()
        
        logger.info(f"✅ 비디오 생성 완료: {output_path}")
        
        return {
            "success": True,
            "video_path": output_path,
            "duration": audio_duration,
            "message": "비디오 생성이 완료되었습니다."
        }
        
    except Exception as e:
        logger.error(f"❌ 비디오 생성 실패: {str(e)}")
        return {
            "success": False,
            "error": str(e),
            "message": "비디오 생성에 실패했습니다."
        }

def create_thumbnail_from_video(video_url: str):
    """
    비디오에서 썸네일 이미지 생성 (첫 번째 프레임)
    """
    try:
        logger.info(f"🖼️ 썸네일 생성 시작 - 비디오: {video_url}")
        
        try:
            from moviepy.editor import VideoFileClip
        except ImportError:
            logger.error("❌ moviepy가 설치되지 않았습니다.")
            raise Exception("moviepy 라이브러리가 필요합니다.")
        
        # 임시 디렉토리 생성
        temp_dir = tempfile.mkdtemp()
        
        # 1. 비디오 다운로드
        video_path = download_file_from_url(video_url, temp_dir, "video")
        logger.info(f"📥 비디오 다운로드 완료: {video_path}")
        
        # 2. 썸네일 생성
        video_clip = VideoFileClip(video_path)
        
        # 첫 번째 프레임 (0.5초 지점) 추출
        thumbnail_time = min(0.5, video_clip.duration / 2)
        
        thumbnail_path = os.path.join(temp_dir, f"thumbnail_{uuid.uuid4().hex[:8]}.jpg")
        video_clip.save_frame(thumbnail_path, t=thumbnail_time)
        
        video_clip.close()
        
        logger.info(f"✅ 썸네일 생성 완료: {thumbnail_path}")
        
        return {
            "success": True,
            "thumbnail_path": thumbnail_path,
            "message": "썸네일 생성이 완료되었습니다."
        }
        
    except Exception as e:
        logger.error(f"❌ 썸네일 생성 실패: {str(e)}")
        return {
            "success": False,
            "error": str(e),
            "message": "썸네일 생성에 실패했습니다."
        }

def download_file_from_url(url: str, temp_dir: str, file_type: str) -> str:
    """
    URL에서 파일 다운로드
    """
    try:
        response = requests.get(url, stream=True, timeout=30)
        response.raise_for_status()
        
        # 파일 확장자 추출
        content_type = response.headers.get('content-type', '')
        
        if file_type == "image":
            if 'jpeg' in content_type or 'jpg' in content_type:
                ext = '.jpg'
            elif 'png' in content_type:
                ext = '.png'
            elif 'gif' in content_type:
                ext = '.gif'
            else:
                ext = '.jpg'  # 기본값
        elif file_type == "audio":
            if 'mp3' in content_type:
                ext = '.mp3'
            elif 'wav' in content_type:
                ext = '.wav'
            elif 'mp4' in content_type or 'm4a' in content_type:
                ext = '.m4a'
            else:
                ext = '.mp3'  # 기본값
        elif file_type == "video":
            if 'mp4' in content_type:
                ext = '.mp4'
            elif 'avi' in content_type:
                ext = '.avi'
            else:
                ext = '.mp4'  # 기본값
        else:
            ext = '.tmp'
        
        file_path = os.path.join(temp_dir, f"{file_type}_{uuid.uuid4().hex[:8]}{ext}")
        
        with open(file_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        logger.info(f"📥 파일 다운로드 완료: {file_path} ({os.path.getsize(file_path)} bytes)")
        return file_path
        
    except Exception as e:
        logger.error(f"❌ 파일 다운로드 실패 ({url}): {str(e)}")
        raise Exception(f"파일 다운로드 실패: {str(e)}")


