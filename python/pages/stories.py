import streamlit as st
from controllers.story_controller import generate_fairy_tale, generate_image_from_fairy_tale, convert_bw_image, generate_openai_voice, audio_to_base64 # play_openai_voice,
import os

# 초기 상태 설정
if 'fairy_tale_text' not in st.session_state:
    st.session_state.fairy_tale_text = ""

if 'image_url' not in st.session_state:
    st.session_state.image_url = None

# Streamlit 앱 설정
title = "태교 동화 생성봇"
st.markdown("# 인공지능 동화작가 동글이입니다.")

# 태아 또는 자녀 이름 입력 받기
name = st.text_input("아이의 이름(태명)을 입력해 주세요", "")
st.write(f"{name}을(를) 위한 동화를 생성해 드립니다.")

# 속도 버튼
speed = st.slider("속도를 선택해 주세요", 0, 2, 1) # 최소, 최대, 기본값
st.write("선택한 속도:", speed)

# 테마 버튼
thema = st.selectbox("테마를 선택해 주세요", ["자연", "도전", "가족", "사랑", "우정", "용기"])
st.write("선택한 테마:", thema)

# 목소리 선택
voice_choices = ["alloy", "echo", "fable", "onyx", "nova", "shimmer", "ash", "coral", "sage"]

# 음성 선택을 세션 상태로 관리
if "selected_voice" not in st.session_state:
    st.session_state.selected_voice = "alloy"

voice = st.selectbox(
    "목소리를 선택해 주세요", 
    voice_choices,
    index=voice_choices.index(st.session_state.selected_voice),
    key="voice_selector"
)

# 선택된 음성을 세션 상태에 저장
st.session_state.selected_voice = voice
st.write("선택한 목소리:", voice)

# 동화 생성 버튼
if st.button("동화 생성"):
    st.session_state.fairy_tale_text = generate_fairy_tale(name, thema)  # 동화 생성
    st.success("동화가 생성되었습니다!")  # 사용자 피드백

# 동화 내용 표시
st.text_area("생성된 동화:", st.session_state.fairy_tale_text, height=300)

# 음성 재생 버튼
if st.button("음성으로 듣기"):
    if st.session_state.get("fairy_tale_text"):
        with st.spinner(f"{voice} 목소리로 음성을 생성하는 중..."):
            audio_data = generate_openai_voice(
                    st.session_state.fairy_tale_text, 
                    voice=voice,
                    speed=speed
                )
                
            if audio_data:
                st.success(f"{voice} 목소리로 생성 완료!")
                
                # Streamlit에서 바이너리 데이터 직접 재생
                st.audio(audio_data, format='audio/mp3')
                
                # Base64 인코딩된 데이터도 표시 (모바일 앱 개발 참고용)
                with st.expander("개발자용 - Base64 데이터"):
                    base64_audio = audio_to_base64(audio_data)
                    st.text_area("Base64 Audio Data (모바일 앱용)", 
                                value=base64_audio[:200] + "...", 
                                height=100)
            # audio_file = play_openai_voice(
            #     st.session_state.fairy_tale_text, 
            #     voice=voice,  # 선택된 음성 전달
            #     speed=speed   # 선택된 속도 전달
            # )
            
            # if audio_file and os.path.exists(audio_file):
            #     st.success(f"{voice} 목소리로 생성 완료!")
            #     st.audio(audio_file)
                
            #     # 파일 정리 (재생 후 잠시 후 삭제)
            #     if st.button("파일 정리"):
            #         try:
            #             os.remove(audio_file)
            #             st.success("임시 파일이 삭제되었습니다.")
            #         except:
            #             pass
            else:
                st.error("음성 생성에 실패했습니다.")
    else:
        st.warning("먼저 동화를 생성하세요.")

# 이미지 생성 버튼
if st.button("동화 이미지 생성"):
    if st.session_state.fairy_tale_text.strip():
        image_url = generate_image_from_fairy_tale(st.session_state.fairy_tale_text)
        if image_url:
            st.session_state.image_url = image_url
            st.success("이미지가 생성되었습니다!")
        else:
            st.warning("이미지 생성에 실패했습니다. 입력을 다시 확인해주세요.")
    else:
        st.warning("먼저 동화 내용을 입력해주세요.")

# 이미지 표시
if st.session_state.image_url:
    st.image(st.session_state.image_url, caption="동화 이미지") #, use_container_width=True)

# 흑백 이미지 변환 버튼
#if st.session_state.get("image_url"):
if st.button("흑백 이미지 변환"):
    bw_path = convert_bw_image(st.session_state.image_url)
    if bw_path:
        st.session_state.bw_image_path = bw_path
        st.success("흑백 이미지로 변환되었습니다.")
    else:
        st.error("흑백 이미지로 변환에 실패하였습니다.")

# 흑백 이미지 표시
if st.session_state.get("bw_image_path"):
    st.image(st.session_state.bw_image_path, caption="색칠용 라인 드로잉") #, use_container_width=True)
