from dotenv import load_dotenv
load_dotenv()
# ai_server.py 수정 버전

from typing import Optional
from fastapi import FastAPI, Body, HTTPException
from pydantic import BaseModel
from controllers.story_controller import generate_fairy_tale, generate_image_from_fairy_tale, convert_bw_image, generate_openai_voice
from controllers.music_controller import search_tracks_by_tag
from controllers.video_controller import search_videos
from datetime import datetime
import os
import base64
import requests
import tempfile
import cv2
import numpy as np
from PIL import Image
import io
from fastapi.responses import Response
from moviepy.editor import ImageClip, AudioFileClip, VideoFileClip
import uuid
import shutil
from fastapi import Request
from io import BytesIO
import logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("app")


# FastAPI 애플리케이션 생성
app = FastAPI()

# 헬스체크 엔드포인트
@app.get("/health")
async def health_check():
    return {
        "status": "ok",
        "service": "fastapi",
        "timestamp": datetime.now().isoformat(),
        "endpoints": [
            "/generate/story",
            "/generate/voice", 
            "/generate/image",
            "/convert/bwimage"
        ]
    }

# 기존 클래스들
class StoryRequest(BaseModel):
    name: str
    theme: str

class TTSRequest(BaseModel):
    text: str
    voice: str
    speed: float = 1.0

class ImageRequest(BaseModel):
    text: str

# ✅ 흑백 변환 요청 클래스 (S3 URL 지원)
class BWImageRequest(BaseModel):
    text: str  # S3 URL 또는 로컬 파일 경로

# 기존 엔드포인트들
@app.post("/generate/story")
def generate_story(req: StoryRequest):
    try:
        result = generate_fairy_tale(req.name, req.theme)
        return {"story": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"동화 생성 실패: {str(e)}")

@app.post("/generate/voice")
def generate_voice(req: TTSRequest):
    try:
        audio_data = generate_openai_voice(req.text, req.voice, req.speed)
        if audio_data is None:
            raise HTTPException(status_code=500, detail="음성 파일 생성 실패")
        
        audio_base64 = base64.b64encode(audio_data).decode('utf-8')
        
        return {
            "audio_base64": audio_base64,
            "voice": req.voice,
            "speed": req.speed,
            "format": "mp3"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"음성 생성 실패: {str(e)}")

@app.post("/generate/image")
def generate_image(req: ImageRequest):
    try:
        image_path = generate_image_from_fairy_tale(req.text)
        if image_path is None:
            raise HTTPException(status_code=500, detail="이미지 생성 실패")
        
        return {"image_url": os.path.abspath(image_path)}  # ✨ 절대 경로
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"이미지 생성 실패: {str(e)}")

from io import BytesIO

@app.post("/convert/bwimage")
async def convert_to_bw(request: Request):
    try:
        data = await request.json()
        image_url = data.get("text")
        logger.info(f"받은 이미지 URL: {image_url}")

        try:
            if image_url.startswith("http"):
                headers = {'User-Agent': 'Mozilla/5.0'}
                response = requests.get(image_url, headers=headers, timeout=30)
                response.raise_for_status()
                image = Image.open(BytesIO(response.content))
            else:
                if not os.path.exists(image_url):
                    raise HTTPException(status_code=404, detail="이미지 파일을 찾을 수 없습니다")
                image = Image.open(image_url)
        except Exception as e:
            logger.error(f"이미지 열기 실패: {e}")
            raise HTTPException(status_code=400, detail=f"이미지 열기 실패: {str(e)}")

        if image.mode != 'RGB':
            image = image.convert('RGB')

        cv_image = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
        gray = cv2.cvtColor(cv_image, cv2.COLOR_BGR2GRAY)
        edges = cv2.Canny(gray, 50, 150)
        edges_inv = cv2.bitwise_not(edges)
        result_image = Image.fromarray(edges_inv)
        buffered = BytesIO()
        result_image.save(buffered, format="PNG")
        img_base64 = base64.b64encode(buffered.getvalue()).decode()

        logger.info("흑백 변환 성공")
        return {"image": img_base64}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"예상치 못한 오류: {e}")
        raise HTTPException(status_code=500, detail=f"흑백 변환 실패: {str(e)}")

    
# ✅ 기존 로컬 파일용 엔드포인트 (호환성 유지)
@app.post("/convert/bwimage-local")
def convert_local_image(req: ImageRequest):
    try:
        image_path = req.text
        
        if not os.path.exists(image_path):
            raise HTTPException(status_code=404, detail="이미지 파일을 찾을 수 없습니다")
        
        bw_image_path = convert_bw_image(image_path)
        if bw_image_path is None:
            raise HTTPException(status_code=500, detail="흑백 변환 실패")
        
        return {"image_url": os.path.abspath(bw_image_path)}  # ✨ 절대 경로
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"흑백 변환 실패: {str(e)}")

# ✅ 테스트 엔드포인트
@app.get("/test/download")
def test_image_download(url: str):
    """S3 이미지 다운로드 테스트"""
    try:
        response = requests.get(url, timeout=10)
        return {
            "status_code": response.status_code,
            "content_type": response.headers.get("content-type"),
            "content_length": len(response.content),
            "success": response.status_code == 200
        }
    except Exception as e:
        return {"error": str(e)}

# 음악/비디오 검색 엔드포인트들
class MusicRequest(BaseModel):
    theme: str

@app.post("/search/url")
def get_music(req: MusicRequest):
    results = search_tracks_by_tag(req.theme)
    return {"music_results": results}

class VideoRequest(BaseModel):
    theme: str

@app.post("/search/video")
def get_video(req: VideoRequest):
    results = search_videos(req.theme)
    return {"video_results": results}


# ============ 비디오 생성 기능 추가 ============

# 비디오 생성 요청/응답 모델
class VideoCreateRequest(BaseModel):
    image_url: str
    audio_url: str
    story_title: str

class VideoCreateResponse(BaseModel):
    success: bool
    video_path: Optional[str] = None
    thumbnail_path: Optional[str] = None
    duration: Optional[float] = None
    message: str
    error: Optional[str] = None

class ThumbnailCreateRequest(BaseModel):
    video_url: str

# 🎬 비디오 생성 엔드포인트
@app.post("/video/create-from-image-audio", response_model=VideoCreateResponse)
async def create_video_endpoint(request: VideoCreateRequest):
    """이미지와 오디오를 결합하여 비디오 생성 (로컬 경로 반환)"""
    try:
        logger.info(f"🎬 비디오 생성 요청 - 제목: {request.story_title}")
        logger.info(f"📸 이미지 URL: {request.image_url}")
        logger.info(f"🎵 오디오 URL: {request.audio_url}")
        
        # 임시 디렉토리 생성
        temp_dir = tempfile.mkdtemp()
        
        try:
            # 1. 이미지 다운로드
            headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}
            
            image_response = requests.get(request.image_url, headers=headers, timeout=30)
            image_response.raise_for_status()
            
            image_path = os.path.join(temp_dir, f"image_{uuid.uuid4().hex[:8]}.jpg")
            with open(image_path, 'wb') as f:
                f.write(image_response.content)
            logger.info(f"✅ 이미지 다운로드 완료: {image_path}")
            
            # 2. 오디오 다운로드
            audio_response = requests.get(request.audio_url, headers=headers, timeout=60)
            audio_response.raise_for_status()
            
            audio_path = os.path.join(temp_dir, f"audio_{uuid.uuid4().hex[:8]}.mp3")
            with open(audio_path, 'wb') as f:
                f.write(audio_response.content)
            logger.info(f"✅ 오디오 다운로드 완료: {audio_path}")
            
            # 3. 비디오 생성
            video_filename = f"video_{uuid.uuid4().hex[:8]}.mp4"
            video_path = os.path.join(temp_dir, video_filename)
            
            # MoviePy로 비디오 생성
            audio_clip = AudioFileClip(audio_path)
            audio_duration = audio_clip.duration
            
            # 이미지를 오디오 길이만큼 재생
            image_clip = ImageClip(image_path, duration=audio_duration)
            
            # 이미지 크기 조정 (1080p)
            image_clip = image_clip.resize(height=1080)
            
            # 오디오와 이미지 결합
            final_clip = image_clip.set_audio(audio_clip)
            
            # 비디오 저장
            final_clip.write_videofile(
                video_path,
                codec='libx264',
                audio_codec='aac',
                temp_audiofile=os.path.join(temp_dir, "temp_audio.m4a"),
                remove_temp=True,
                fps=24,
                logger=None  # moviepy 로그 비활성화
            )
            
            # 메모리 정리
            audio_clip.close()
            image_clip.close()
            final_clip.close()
            
            logger.info(f"✅ 비디오 생성 완료: {video_path}")
            
            # Java가 파일을 읽을 수 있도록 output 디렉토리로 이동
            output_dir = "output/videos"
            os.makedirs(output_dir, exist_ok=True)
            
            final_video_path = os.path.join(output_dir, video_filename)
            shutil.move(video_path, final_video_path)
            
            # 임시 파일 정리
            try:
                os.remove(image_path)
                os.remove(audio_path)
            except:
                pass
            
            return VideoCreateResponse(
                success=True,
                video_path=os.path.abspath(final_video_path),  # 절대 경로 반환
                duration=audio_duration,
                message="비디오 생성이 완료되었습니다."
            )
            
        finally:
            # 임시 디렉토리 정리
            try:
                shutil.rmtree(temp_dir)
            except:
                pass
                
    except Exception as e:
        logger.error(f"❌ 비디오 생성 실패: {str(e)}")
        return VideoCreateResponse(
            success=False,
            message="비디오 생성에 실패했습니다.",
            error=str(e)
        )

# 🖼️ 썸네일 생성 엔드포인트
@app.post("/video/create-thumbnail")
async def create_thumbnail_endpoint(request: ThumbnailCreateRequest):
    """비디오에서 썸네일 생성 (로컬 경로 반환)"""
    try:
        logger.info(f"🖼️ 썸네일 생성 요청 - 비디오: {request.video_url}")
        
        temp_dir = tempfile.mkdtemp()
        
        try:
            # 비디오가 URL인 경우 다운로드
            if request.video_url.startswith('http'):
                headers = {'User-Agent': 'Mozilla/5.0'}
                video_response = requests.get(request.video_url, headers=headers, stream=True)
                video_response.raise_for_status()
                
                video_path = os.path.join(temp_dir, f"video_{uuid.uuid4().hex[:8]}.mp4")
                with open(video_path, 'wb') as f:
                    for chunk in video_response.iter_content(chunk_size=8192):
                        f.write(chunk)
            else:
                # 로컬 경로인 경우
                video_path = request.video_url
            
            # 썸네일 생성
            video_clip = VideoFileClip(video_path)
            
            # 첫 번째 프레임 또는 0.5초 지점
            thumbnail_time = min(0.5, video_clip.duration / 2)
            
            thumbnail_filename = f"thumbnail_{uuid.uuid4().hex[:8]}.jpg"
            thumbnail_path = os.path.join(temp_dir, thumbnail_filename)
            
            video_clip.save_frame(thumbnail_path, t=thumbnail_time)
            video_clip.close()
            
            # output 디렉토리로 이동
            output_dir = "output/thumbnails"
            os.makedirs(output_dir, exist_ok=True)
            
            final_thumbnail_path = os.path.join(output_dir, thumbnail_filename)
            shutil.move(thumbnail_path, final_thumbnail_path)
            
            return {
                "success": True,
                "thumbnail_path": os.path.abspath(final_thumbnail_path),
                "message": "썸네일 생성이 완료되었습니다."
            }
            
        finally:
            try:
                shutil.rmtree(temp_dir)
            except:
                pass
                
    except Exception as e:
        logger.error(f"❌ 썸네일 생성 실패: {str(e)}")
        return {
            "success": False,
            "message": "썸네일 생성에 실패했습니다.",
            "error": str(e)
        }

# 🔧 테스트용 엔드포인트
@app.get("/video/test")
async def test_video_service():
    """비디오 서비스 상태 확인"""
    try:
        import moviepy
        import imageio
        
        return {
            "status": "ok",
            "moviepy_installed": True,
            "imageio_installed": True,
            "output_dirs": {
                "videos": os.path.exists("output/videos"),
                "thumbnails": os.path.exists("output/thumbnails")
            }
        }
    except ImportError as e:
        return {
            "status": "error",
            "error": str(e),
            "message": "필요한 라이브러리가 설치되지 않았습니다. pip install moviepy imageio imageio-ffmpeg"
        }
