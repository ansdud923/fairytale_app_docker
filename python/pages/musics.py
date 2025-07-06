import streamlit as st
from controllers.music_controller import search_tracks_by_tag, THEME_KEYWORDS

st.title("🎵 우리 아가를 위한 자장가 재생기")
st.markdown("테마를 선택하면 아기를 위한 자장가 목록을 드려요")

# 테마 선택
theme = st.selectbox("🎨 자장가 테마를 선택해 주세요", list(THEME_KEYWORDS.keys()))

# 현재 재생 중인 track index를 세션 상태에 저장
if "playing_index" not in st.session_state:
    st.session_state.playing_index = None

if "audio_url" not in st.session_state:
    st.session_state.audio_url = None

if "search_results" not in st.session_state:
    st.session_state.search_results = []

if st.button("🔍 자장가 불러오기"):
    st.info(f"'{theme}' 테마에 맞는 자장가를 불러오는 중입니다.")

    # 선택된 테마에 해당하는 검색어로 검색
    query = THEME_KEYWORDS[theme]
    results = search_tracks_by_tag(query)

    if results:
        st.session_state.search_results = results
    else:
        st.session_state.search_results = []
        st.warning("🔇 해당 테마에 맞는 자장가를 찾지 못했습니다.")

# 검색 결과가 있을 경우
if st.session_state.search_results:
    for i, track in enumerate(st.session_state.search_results):
        name = track.get("name", "제목 없음")
        artist = track.get("artist_name", "미상")
        audio_url = track.get("audio")

        st.subheader(f"{name} - {artist}")
        
        # 재생 버튼
        if st.button(f"▶ {name} 재생", key=f"play_{i}"):
            st.session_state.playing_index = i
            st.session_state.audio_url = audio_url

    # 버튼 생성 반복문 이후 오디오 재생
    if st.session_state.audio_url:
        st.audio(st.session_state.audio_url, format="audio/mp3")

else:
    st.warning("🔇 해당 테마에 맞는 자장가를 찾지 못했습니다.")