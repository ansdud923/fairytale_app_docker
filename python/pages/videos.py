import streamlit as st
from controllers.video_controller import search_videos, THEME_KEYWORDS

st.title("🎵 우리 아가를 위한 자장가 재생기")
st.markdown("테마를 선택하면 아기를 위한 자장가 영상을 드려요")

# 테마 선택
theme = st.selectbox("🎨 자장가 테마를 선택해 주세요", list(THEME_KEYWORDS.keys()))

# 현재 재생 중인 track index를 세션 상태에 저장
if "playing_index" not in st.session_state:
    st.session_state.playing_index = None

if "youtube_url" not in st.session_state:
    st.session_state.youtube_url = None

if "search_results" not in st.session_state:
    st.session_state.search_results = []

if st.button("🔍 자장가 불러오기"):
    st.info(f"'{theme}' 테마에 맞는 자장가를 불러오는 중입니다.")
    results = search_videos(theme)

    if results:
        st.session_state.search_results = results if isinstance(results, list) else results.split('\n')

        for video in st.session_state.search_results:
            st.video(video["url"])
        
    else:
        st.warning("🔇 해당 테마에 맞는 자장가를 찾지 못했습니다.")