# 엄빠, 읽어도! 📖

![header](https://capsule-render.vercel.app/api?type=waving&color=0:EEFF00,100:a82da8&height=300&section=header&text=Fairytale%20App%20%F0%9F%93%96)

## 👀 About Project
#### :raising_hand: AI 기반 개인화 동화생성 모바일 애플리케이션 "엄빠, 읽어도!"<br/>
#### :fire: 아이만을 위한 맞춤형 동화와 색칠공부를 제공하는 풀스택 프로젝트<br/>
#### :mortar_board: 1조 팀 협업 프로젝트 - Flutter + Spring Boot + Python FastAPI

## 🧱 Tech Stack

### Frontend
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white)

### Backend
![Spring Boot](https://img.shields.io/badge/Spring_Boot-6DB33F?style=flat-square&logo=spring-boot&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=flat-square&logo=FastAPI&logoColor=white)

### Database & Storage
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=flat-square&logo=postgresql&logoColor=white)
![Amazon S3](https://img.shields.io/badge/Amazon_S3-FF9900?style=flat-square&logo=amazon-s3&logoColor=white)
![AWS EC2](https://img.shields.io/badge/AWS_EC2-FF9900?style=flat-square&logo=amazon-ec2&logoColor=white)
![AWS RDS](https://img.shields.io/badge/AWS_RDS-527FFF?style=flat-square&logo=amazon-rds&logoColor=white)

### AI & APIs
![OpenAI](https://img.shields.io/badge/OpenAI-412991?style=flat-square&logo=openai&logoColor=white)
![Stability AI](https://img.shields.io/badge/Stability_AI-000000?style=flat-square&logo=stability-ai&logoColor=white)
![YouTube API](https://img.shields.io/badge/YouTube_API-FF0000?style=flat-square&logo=youtube&logoColor=white)
![OpenCV](https://img.shields.io/badge/OpenCV-5C3EE8?style=flat-square&logo=opencv&logoColor=white)

### Tools
![GitHub](https://img.shields.io/badge/GitHub-181717?style=flat-square&logo=github&logoColor=white)
![Notion](https://img.shields.io/badge/Notion-000000?style=flat-square&logo=notion&logoColor=white)
![Figma](https://img.shields.io/badge/Figma-F24E1E?style=flat-square&logo=figma&logoColor=white)

## 🌟 Main Features
#### 🎨 AI 동화 생성 - OpenAI GPT를 활용한 개인화된 동화 창작
#### 🖼️ AI 이미지 생성 - Stability AI로 동화 일러스트 자동 생성  
#### 🎵 TTS 음성 합성 - 9가지 목소리로 동화 읽어주기
#### 🎨 색칠공부 - 생성된 이미지를 흑백 변환하여 디지털 색칠
#### 📱 갤러리 - 동화와 색칠 작품 저장 및 관리
#### 🎬 커뮤니티 공유 - 동영상 생성 후 사용자간 공유
#### 🎵 스마트 자장가 - YouTube API 기반 테마별 자장가 추천

## 🏗️ Architecture
```
📱 Flutter App (Client)
    ↕️
🌐 Spring Boot Server (API Gateway & Auth)
    ↕️  
🧠 Python FastAPI Server (AI Processing)
    ↕️
☁️ AWS S3 + PostgreSQL + OpenAI API
```

## 📂 Project Structure

### Flutter App (Frontend)
```
lib/
├── models/ - 데이터 모델
├── screens/
│   ├── coloring/ - 색칠공부
│   ├── gallery/ - 갤러리  
│   ├── lullaby/ - 자장가
│   ├── profile/ - 프로필 관리
│   ├── service/ - API 통신
│   ├── share/ - 커뮤니티
│   ├── home_screen.dart
│   └── stories_screen.dart
└── main.dart
```

### Spring Boot Server (Backend)
```
src/main/java/com/fairytale/fairytale/
├── auth/ - 인증/인가 (JWT, OAuth2.0)
├── baby/ - 아이 정보 관리
├── coloring/ - 색칠공부 기능
├── gallery/ - 갤러리 관리
├── lullaby/ - 자장가 서비스
├── share/ - 커뮤니티 공유
└── story/ - 동화 생성 관리
```

### Python AI Server (AI Processing)
```
python/
├── controllers/
│   ├── music_controller.py - 자장가 추천
│   ├── story_controller.py - 동화 생성
│   └── video_controller.py - 영상 생성
└── ai_server.py - FastAPI 메인 서버
```

## 💻 My Main Technologies
#### 📱 **Frontend**: Flutter/Dart - 크로스플랫폼 모바일 앱 개발
#### 🌐 **Backend**: Spring Boot/Java - RESTful API 서버 및 인증 시스템  
#### 🧠 **AI Server**: Python/FastAPI - AI 모델 통합 및 처리
#### 🗄️ **Database**: PostgreSQL - 관계형 데이터베이스 설계 및 관리
#### ☁️ **DevOps**: AWS (EC2, RDS, S3) - 클라우드 인프라 구축

## 🚀 Key Technologies & Features

### 🧠 AI Integration
- **Text Generation**: OpenAI GPT-4o-mini로 개인화 동화 생성
- **Image Generation**: Stability AI (Stable Diffusion)로 동화 일러스트 생성
- **Image Processing**: OpenCV로 흑백 변환 및 색칠공부 템플릿 제작
- **Text-to-Speech**: OpenAI TTS API로 9가지 음성 지원

### 🔐 Authentication & Security
- **소셜 로그인**: 카카오, 구글 OAuth 2.0 연동
- **JWT 토큰**: Access Token (1시간) + Refresh Token (14일)
- **Strategy Pattern**: 확장 가능한 인증 시스템 설계

### ☁️ Cloud & Infrastructure
- **AWS S3**: Presigned URL을 통한 안전한 파일 스토리지
- **AWS RDS**: PostgreSQL 기반 관계형 데이터베이스
- **AWS EC2**: 백엔드 서버 호스팅

### 📱 Mobile Development
- **Flutter**: 크로스플랫폼 네이티브 성능
- **반응형 UI**: MediaQuery를 활용한 다양한 화면 크기 대응
- **CustomPainter**: 실시간 디지털 색칠 기능
- **오디오 플레이어**: 동화 음성 재생 기능

### 🎵 External APIs
- **YouTube Data API**: 테마별 자장가 추천
- **영상 생성**: 이미지와 음성을 결합한 동화 영상 제작

## 📋 Development Info
#### 📅 **개발기간**: 2025년 5월 19일 ~ 6월 23일 (총 36일)
#### 👥 **팀구성**: 1조 <일단해조> (3명 풀스택 협업)
#### 📱 **버전**: v1.0.0
#### 🎯 **타겟**: 부모와 아이를 위한 교육 앱

## 🤔 Project Stats
[![GitHub stats](https://github-readme-stats.vercel.app/api?username=ansdud923&show_icons=true&theme=sunset-gradient&title_color=FF6B6B&text_color=8B4513&bg_color=0,FFCCCB,FFFFE0&border_color=FF6B6B)](https://github.com/anuraghazra/github-readme-stats)

[![Top Langs](https://github-readme-stats.vercel.app/api/top-langs/?username=ansdud923&layout=compact&theme=sunset-gradient&title_color=FF6B6B&text_color=8B4513&bg_color=0,FFCCCB,FFFFE0&border_color=FF6B6B&include_repos=fairytale_app&langs_count=8)](https://github.com/anuraghazra/github-readme-stats)


## 🤝 Team Contribution
이 프로젝트에서 **Flutter 모바일 앱 개발**, **Spring Boot 백엔드 API**, **AWS 인프라 구축**, **데이터베이스 설계** 등 전 영역에 걸쳐 기여했습니다.

---

> 🎭 **"엄빠, 읽어도!"**는 AI 기술을 활용해 아이만을 위한 특별한 동화를 만들어주는 혁신적인 교육 앱입니다.
