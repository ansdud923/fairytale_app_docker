package com.fairytale.fairytale.lullaby;

import com.fairytale.fairytale.lullaby.dto.JamendoTrack;
import com.fairytale.fairytale.lullaby.dto.YouTubeVideo;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;

@Service
@Slf4j
public class PythonApiService {

    private final RestTemplate restTemplate;

    @Value("${python.fastapi.url:http://localhost:8000}")
    private String pythonApiUrl;

    public PythonApiService(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    // ==================== 음악 검색 기능 ====================

    public List<JamendoTrack> searchMusicByTheme(String theme) {
        try {
            String url = pythonApiUrl + "/search/url";
            Map<String, String> requestBody = Map.of("theme", theme);

            log.info("🔍 [PythonApiService] 음악 검색 API 호출: {} -> {}", theme, url);

            ResponseEntity<String> response = restTemplate.postForEntity(
                    url, requestBody, String.class);

            log.info("🔍 [PythonApiService] 음악 검색 응답 상태: {}", response.getStatusCode());

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                return parseMusicResponse(response.getBody());
            }

            return Collections.emptyList();

        } catch (Exception e) {
            log.error("❌ [PythonApiService] 음악 검색 API 호출 중 오류: {}", e.getMessage(), e);
            return Collections.emptyList();
        }
    }

    // ==================== 영상 검색 기능 ====================

    public List<YouTubeVideo> searchVideosByTheme(String theme) {
        try {
            String url = pythonApiUrl + "/search/video";
            Map<String, String> requestBody = Map.of("theme", theme);

            log.info("🔍 [PythonApiService] 영상 검색 API 호출: {} -> {}", theme, url);

            ResponseEntity<String> response = restTemplate.postForEntity(
                    url, requestBody, String.class);

            log.info("🔍 [PythonApiService] 영상 검색 응답 상태: {}", response.getStatusCode());

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                // 응답 내용 로깅 추가
                log.debug("📝 [PythonApiService] 영상 검색 원본 응답: {}", response.getBody());
                return parseVideoResponse(response.getBody());
            }

            return Collections.emptyList();

        } catch (Exception e) {
            log.error("❌ [PythonApiService] 영상 검색 API 호출 중 오류: {}", e.getMessage(), e);
            return Collections.emptyList();
        }
    }

    // ==================== 응답 파싱 메서드들 ====================

    private List<JamendoTrack> parseMusicResponse(String responseBody) {
        try {
            ObjectMapper objectMapper = new ObjectMapper();
            Map<String, Object> responseMap = objectMapper.readValue(
                    responseBody, new TypeReference<Map<String, Object>>() {});

            Object musicResultsObj = responseMap.get("music_results");

            if (musicResultsObj instanceof List) {
                @SuppressWarnings("unchecked")
                List<Object> musicResultsList = (List<Object>) musicResultsObj;

                List<JamendoTrack> tracks = new ArrayList<>();
                for (int i = 0; i < musicResultsList.size(); i++) {
                    try {
                        JamendoTrack track = objectMapper.convertValue(musicResultsList.get(i), JamendoTrack.class);
                        tracks.add(track);
                        log.info("✅ [PythonApiService] 음악 트랙 변환 성공 {}: {}", i, track.getName());
                    } catch (Exception e) {
                        log.error("❌ [PythonApiService] 음악 트랙 {} 변환 실패: {}", i, e.getMessage());
                    }
                }
                return tracks;
            }

            return Collections.emptyList();

        } catch (Exception e) {
            log.error("❌ [PythonApiService] 음악 응답 파싱 실패: {}", e.getMessage());
            return Collections.emptyList();
        }
    }

    private List<YouTubeVideo> parseVideoResponse(String responseBody) {
        try {
            // 응답 내용 로깅
            log.info("📝 [PythonApiService] 영상 응답 파싱 시작");
            log.debug("📝 [PythonApiService] 파싱할 응답 내용: {}", responseBody);

            ObjectMapper objectMapper = new ObjectMapper();
            Map<String, Object> responseMap = objectMapper.readValue(
                    responseBody, new TypeReference<Map<String, Object>>() {});

            // 응답 구조 로깅
            log.info("📝 [PythonApiService] 응답 맵 키들: {}", responseMap.keySet());

            Object videoResultsObj = responseMap.get("video_results");

            if (videoResultsObj == null) {
                log.warn("⚠️ [PythonApiService] video_results 키가 없습니다!");
                return Collections.emptyList();
            }

            if (videoResultsObj instanceof List) {
                @SuppressWarnings("unchecked")
                List<Object> videoResultsList = (List<Object>) videoResultsObj;

                log.info("📝 [PythonApiService] video_results 리스트 크기: {}", videoResultsList.size());

                List<YouTubeVideo> videos = new ArrayList<>();
                for (int i = 0; i < videoResultsList.size(); i++) {
                    try {
                        // 각 비디오 객체 로깅
                        log.debug("📝 [PythonApiService] 비디오 {} 원본 데이터: {}", i, videoResultsList.get(i));

                        YouTubeVideo video = objectMapper.convertValue(videoResultsList.get(i), YouTubeVideo.class);
                        videos.add(video);
                        log.info("✅ [PythonApiService] 영상 변환 성공 {}: {} (URL: {})",
                                i, video.getTitle(), video.getUrl());
                    } catch (Exception e) {
                        log.error("❌ [PythonApiService] 영상 {} 변환 실패: {}", i, e.getMessage());
                        log.error("상세 오류: ", e);
                    }
                }

                log.info("📝 [PythonApiService] 총 변환된 영상 수: {}", videos.size());
                return videos;
            } else {
                log.warn("⚠️ [PythonApiService] video_results가 List 타입이 아닙니다. 실제 타입: {}",
                        videoResultsObj.getClass().getName());
            }

            return Collections.emptyList();

        } catch (Exception e) {
            log.error("❌ [PythonApiService] 영상 응답 파싱 실패: {}", e.getMessage());
            log.error("상세 오류: ", e);
            return Collections.emptyList();
        }
    }

    // ==================== 공통 기능 ====================

    public boolean isApiHealthy() {
        try {
            String healthUrl = pythonApiUrl + "/health";
            ResponseEntity<Map> response = restTemplate.getForEntity(healthUrl, Map.class);
            return response.getStatusCode() == HttpStatus.OK;
        } catch (Exception e) {
            log.error("❌ [PythonApiService] 파이썬 API 헬스체크 실패: {}", e.getMessage());
            return false;
        }
    }
}