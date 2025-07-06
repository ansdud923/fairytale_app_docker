// src/main/java/com/fairytale/fairytale/service/VideoService.java
package com.fairytale.fairytale.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class VideoService {

    private final S3Service s3Service;
    private final RestTemplate restTemplate;

    @Value("${FASTAPI_BASE_URL:http://localhost:8000}")
    private String fastApiBaseUrl;

    /**
     * 이미지와 오디오를 결합하여 비디오 생성
     */
    public String createVideoFromImageAndAudio(String imageUrl, String audioUrl, String storyTitle) {
        try {
            log.info("🎬 비디오 생성 시작 - 이미지: {}, 오디오: {}", imageUrl, audioUrl);

            // 1. Python FastAPI로 비디오 생성 요청
            Map<String, Object> requestData = new HashMap<>();
            requestData.put("image_url", imageUrl);
            requestData.put("audio_url", audioUrl);
            requestData.put("story_title", storyTitle);

            String pythonVideoEndpoint = fastApiBaseUrl + "/video/create-from-image-audio";
            log.info("🔍 Python API 호출: {}", pythonVideoEndpoint);

            try {
                ResponseEntity<Map> response = restTemplate.postForEntity(
                        pythonVideoEndpoint,
                        requestData,
                        Map.class
                );

                if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                    Map<String, Object> responseBody = response.getBody();

                    Boolean success = (Boolean) responseBody.get("success");
                    if (Boolean.TRUE.equals(success)) {
                        String localVideoPath = (String) responseBody.get("video_path");
                        log.info("✅ Python에서 비디오 생성 완료: {}", localVideoPath);

                        // 2. 생성된 비디오를 S3에 업로드 (이미 구현된 메서드 활용)
                        String s3VideoUrl = s3Service.uploadVideoFromLocalFile(localVideoPath, "videos");
                        log.info("✅ S3 비디오 업로드 완료: {}", s3VideoUrl);

                        return s3VideoUrl;
                    } else {
                        String errorMsg = (String) responseBody.get("error");
                        throw new RuntimeException("Python API 비디오 생성 실패: " + errorMsg);
                    }
                } else {
                    throw new RuntimeException("Python API 응답 오류");
                }

            } catch (Exception e) {
                log.error("❌ Python API 호출 실패: {}", e.getMessage());

                // 대체 방안: 이미지를 비디오 URL로 사용
                log.warn("⚠️ 비디오 생성 실패 - 대체 모드: 이미지 URL을 비디오 URL로 사용");
                return imageUrl;
            }

        } catch (Exception e) {
            log.error("❌ 비디오 생성 전체 프로세스 실패: {}", e.getMessage());

            // 최종 대체 방안
            log.warn("⚠️ 최종 대체 모드 활성화");
            return imageUrl;
        }
    }

    /**
     * 썸네일 이미지 생성 (첫 번째 프레임 추출)
     */
    public String createThumbnail(String videoUrl) {
        try {
            log.info("🖼️ 썸네일 생성 시작 - 비디오: {}", videoUrl);

            Map<String, Object> requestData = new HashMap<>();
            requestData.put("video_url", videoUrl);

            String pythonThumbnailEndpoint = fastApiBaseUrl + "/video/create-thumbnail";

            try {
                ResponseEntity<Map> response = restTemplate.postForEntity(
                        pythonThumbnailEndpoint,
                        requestData,
                        Map.class
                );

                if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                    Map<String, Object> responseBody = response.getBody();

                    Boolean success = (Boolean) responseBody.get("success");
                    if (Boolean.TRUE.equals(success)) {
                        String localThumbnailPath = (String) responseBody.get("thumbnail_path");
                        log.info("✅ Python에서 썸네일 생성 완료: {}", localThumbnailPath);

                        // S3에 썸네일 업로드 (이미 구현된 메서드 활용)
                        String s3ThumbnailUrl = s3Service.uploadImageFromLocalFile(localThumbnailPath, "thumbnails");
                        log.info("✅ S3 썸네일 업로드 완료: {}", s3ThumbnailUrl);

                        return s3ThumbnailUrl;
                    }
                }

            } catch (Exception e) {
                log.error("❌ 썸네일 생성 API 호출 실패: {}", e.getMessage());
            }

            // 썸네일 생성 실패 시 null 반환 (비디오 공유는 계속 가능)
            log.warn("⚠️ 썸네일 생성 실패, null 반환");
            return null;

        } catch (Exception e) {
            log.error("❌ 썸네일 생성 전체 프로세스 실패: {}", e.getMessage());
            return null;
        }
    }

    /**
     * 비디오 서비스 상태 확인 (헬스체크)
     */
    public boolean isVideoServiceAvailable() {
        try {
            String testEndpoint = fastApiBaseUrl + "/video/test";
            ResponseEntity<Map> response = restTemplate.getForEntity(testEndpoint, Map.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                Map<String, Object> body = response.getBody();
                return "ok".equals(body.get("status"));
            }

            return false;
        } catch (Exception e) {
            log.warn("⚠️ 비디오 서비스 상태 확인 실패: {}", e.getMessage());
            return false;
        }
    }
}