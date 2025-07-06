package com.fairytale.fairytale.story;

// 📚 필요한 라이브러리들 import
import com.fairytale.fairytale.coloring.ColoringTemplateService;
import com.fairytale.fairytale.story.dto.*;
import com.fairytale.fairytale.service.S3Service;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.fasterxml.jackson.databind.SerializationFeature;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

/**
 * 🎭 StoryController - 최적화된 S3 연동 버전
 * <p>
 * 주요 개선사항:
 * 1. 실제 존재하는 메서드만 호출
 * 2. 효율적인 흑백 변환 처리
 * 3. 정확한 S3 헬스체크
 * 4. 에러 처리 강화
 */
@Slf4j
@RestController
@RequestMapping("api/fairytale")
@RequiredArgsConstructor
public class StoryController {

    // 🔧 의존성 주입
    private final StoryService storyService;
    private final RestTemplate restTemplate;
    private final S3Service s3Service;
    private final ColoringTemplateService coloringTemplateService;
    private final ObjectMapper objectMapper;

    /**
     * 🎯 동화 생성 API
     */
    @PostMapping("/generate/story")
    public ResponseEntity<Story> createStory(
            @RequestBody StoryCreateRequest request,
            Authentication auth
    ) {
        try {
            String username = auth.getName();
            log.info("🔍 컨트롤러에서 받은 username: {}", username);

            Story story = storyService.createStory(request, username);
            return ResponseEntity.ok(story);

        } catch (Exception e) {
            log.error("❌ 컨트롤러 에러: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * 📖 특정 동화 조회 API
     */
    @GetMapping("/story/{id}")
    public ResponseEntity<Story> getStory(
            @PathVariable Long id,
            Authentication auth
    ) {
        try {
            String username = auth.getName();
            Story story = storyService.getStoryById(id, username);
            return ResponseEntity.ok(story);
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * 🗣️ 음성 변환 API (S3 업로드 포함)
     */
    @PostMapping("/generate/voice")
    public ResponseEntity<Story> createVoice(@RequestBody VoiceRequest request) {
        try {
            log.info("🎤 음성 생성 요청 - StoryId: {}", request.getStoryId());

            Story result = storyService.createVoice(request);

            log.info("✅ 음성 생성 완료 - VoiceContent: {}", result.getVoiceContent());
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            log.error("❌ 음성 생성 실패: {}", e.getMessage());
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * 📁 S3 오디오 파일 다운로드 API (관리자용)
     */
    @PostMapping("/download/audio/s3")
    public ResponseEntity<byte[]> downloadAudioFromS3(@RequestBody Map<String, String> request) {
        try {
            String s3Url = request.get("s3Url");
            log.info("🔍 [S3 오디오 다운로드] 요청된 S3 URL: {}", s3Url);

            if (s3Url == null || s3Url.trim().isEmpty()) {
                log.warn("❌ S3 URL이 비어있음");
                return ResponseEntity.badRequest()
                        .body("S3 URL이 제공되지 않았습니다.".getBytes());
            }

            // 🔍 S3 URL 유효성 검사
            if (!s3Url.contains("amazonaws.com") && !s3Url.contains("cloudfront.net")) {
                log.warn("❌ 유효하지 않은 S3 URL: {}", s3Url);
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body("유효하지 않은 S3 URL입니다.".getBytes());
            }

            // 📥 S3에서 파일 다운로드
            byte[] audioBytes = s3Service.downloadAudioFile(
                    s3Service.extractS3KeyFromUrl(s3Url)
            );

            log.info("✅ S3 파일 다운로드 완료: {} bytes", audioBytes.length);

            // 📋 HTTP 응답 헤더 설정
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(getAudioMediaType(s3Url));
            headers.setContentLength(audioBytes.length);
            headers.setCacheControl("no-cache");

            // 🌐 CORS 헤더 추가
            headers.add("Access-Control-Allow-Origin", "*");
            headers.add("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
            headers.add("Access-Control-Allow-Headers", "Content-Type, Authorization");

            log.info("✅ S3 오디오 파일 다운로드 성공");

            return ResponseEntity.ok()
                    .headers(headers)
                    .body(audioBytes);

        } catch (Exception e) {
            log.error("❌ S3 오디오 다운로드 처리 실패: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(("S3 다운로드 실패: " + e.getMessage()).getBytes());
        }
    }

    /**
     * 🔗 임시 접근 URL 생성 API (보안이 필요한 경우)
     */
    @PostMapping("/audio/presigned-url")
    public ResponseEntity<Map<String, String>> generatePresignedUrl(
            @RequestBody Map<String, Object> request,
            Authentication auth) {
        try {
            Long storyId = Long.valueOf(request.get("storyId").toString());
            Integer expirationMinutes = (Integer) request.getOrDefault("expirationMinutes", 60);

            log.info("🔗 Presigned URL 생성 요청 - StoryId: {}, 만료시간: {}분", storyId, expirationMinutes);

            // 🔒 사용자 권한 확인
            String username = auth.getName();
            Story story = storyService.getStoryById(storyId, username);

            if (story.getVoiceContent() == null || story.getVoiceContent().isEmpty()) {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "음성 파일이 없습니다.");
                return ResponseEntity.badRequest().body(errorResponse);
            }

            // 🔗 Presigned URL 생성
            String presignedUrl = storyService.generateTemporaryVoiceUrl(storyId, expirationMinutes);

            Map<String, String> response = new HashMap<>();
            response.put("presigned_url", presignedUrl);
            response.put("expiration_minutes", expirationMinutes.toString());
            response.put("story_id", storyId.toString());

            log.info("✅ Presigned URL 생성 완료");
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ Presigned URL 생성 실패: {}", e.getMessage());
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * 🗑️ 스토리 삭제 API (S3 파일 포함)
     */
    @DeleteMapping("/story/{id}")
    public ResponseEntity<Map<String, String>> deleteStory(
            @PathVariable Long id,
            Authentication auth) {
        try {
            String username = auth.getName();
            log.info("🗑️ 스토리 삭제 요청 - StoryId: {}, Username: {}", id, username);

            storyService.deleteStoryWithVoiceFile(id, username);

            Map<String, String> response = new HashMap<>();
            response.put("message", "스토리와 관련 파일이 삭제되었습니다.");
            response.put("story_id", id.toString());

            log.info("✅ 스토리 삭제 완료 - StoryId: {}", id);
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 스토리 삭제 실패: {}", e.getMessage());
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * 🎨 이미지 생성 API
     */
    @PostMapping("/generate/image")
    public ResponseEntity<Story> createImage(@RequestBody ImageRequest request, Authentication auth) {
        try {
            String username = auth.getName(); // 🎯 이 1줄 추가!
            Story result = storyService.createImage(request, username); // 🎯 username 파라미터 추가!

            // 🔍 응답 전 디버깅 로그 (기존 코드 그대로)
            log.info("=== 컨트롤러 응답 데이터 ===");
            log.info("Story ID: {}", result.getId());
            log.info("Title: {}", result.getTitle());
            log.info("Image URL: {}", result.getImage());
            log.info("Image URL 길이: {}", (result.getImage() != null ? result.getImage().length() : "null"));
            log.info("Voice Content: {}", result.getVoiceContent());

            // 🔍 JSON 직렬화 테스트 (기존 코드 그대로)
            try {
                ObjectMapper mapper = new ObjectMapper();
                mapper.registerModule(new JavaTimeModule());
                mapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
                String jsonResponse = mapper.writeValueAsString(result);
                log.debug("🔍 JSON 응답 미리보기: {}", jsonResponse.substring(0, Math.min(500, jsonResponse.length())));
            } catch (Exception e) {
                log.warn("❌ JSON 직렬화 실패: {}", e.getMessage());
            }

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            log.error("❌ 컨트롤러 에러: {}", e.getMessage());
            return ResponseEntity.badRequest().build();
        }
    }
    /**
     * 🎨 흑백 변환 API (색칠하기 버튼용) - 수정됨
     */
    @PostMapping("/convert/bwimage")
    public ResponseEntity<String> convertToBlackWhiteImage(@RequestBody Map<String, String> request) {
        try {
            String imageUrl = request.get("text");
            log.info("🔍 흑백 변환 요청: {}", imageUrl);

            if (imageUrl == null || imageUrl.trim().isEmpty() || "null".equals(imageUrl)) {
                log.warn("❌ 이미지 URL이 null이거나 비어있음: {}", imageUrl);

                Map<String, Object> errorResponse = new HashMap<>();
                errorResponse.put("image_url", null);
                errorResponse.put("error", "이미지 URL이 null입니다.");
                errorResponse.put("conversion_method", "Flutter_Filter");

                String errorJson = objectMapper.writeValueAsString(errorResponse);
                return ResponseEntity.ok(errorJson);
            }

            // 🎯 StoryService의 흑백 변환 메서드 호출
            String blackWhiteUrl = storyService.processImageToBlackWhite(imageUrl);

            Map<String, Object> response = new HashMap<>();
            response.put("image_url", blackWhiteUrl);
            response.put("conversion_method", "S3_PIL_OpenCV");
            response.put("original_url", imageUrl);

            String responseJson = objectMapper.writeValueAsString(response);
            log.info("✅ 흑백 변환 완료 - 원본: {}, 변환: {}", imageUrl, blackWhiteUrl);
            return ResponseEntity.ok(responseJson);

        } catch (Exception e) {
            log.error("❌ 흑백 변환 실패: {}", e.getMessage());

            Map<String, Object> fallbackResponse = new HashMap<>();
            fallbackResponse.put("image_url", request.get("text"));
            fallbackResponse.put("conversion_method", "Flutter_Filter");
            fallbackResponse.put("error", "서버 변환 실패로 Flutter에서 필터링 처리됩니다.");
            fallbackResponse.put("message", e.getMessage());

            try {
                String fallbackJson = objectMapper.writeValueAsString(fallbackResponse);
                return ResponseEntity.ok(fallbackJson);
            } catch (Exception jsonError) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                        .body("{\"error\": \"" + e.getMessage() + "\"}");
            }
        }
    }

    /**
     * 🎵 파일 확장자에 따른 MediaType 반환
     */
    private MediaType getAudioMediaType(String filePath) {
        String lowerPath = filePath.toLowerCase();

        if (lowerPath.endsWith(".mp3")) {
            return MediaType.valueOf("audio/mpeg");
        } else if (lowerPath.endsWith(".wav")) {
            return MediaType.valueOf("audio/wav");
        } else if (lowerPath.endsWith(".m4a")) {
            return MediaType.valueOf("audio/mp4");
        } else if (lowerPath.endsWith(".ogg")) {
            return MediaType.valueOf("audio/ogg");
        } else {
            return MediaType.APPLICATION_OCTET_STREAM;
        }
    }

    /**
     * 📊 S3 연결 상태 확인 API (✅ 수정됨)
     */
    @GetMapping("/health/s3")
    public ResponseEntity<Map<String, Object>> checkS3Health() {
        try {
            // ✅ 수정: 실제 존재하는 메서드 호출
            boolean isConnected = s3Service.isS3Available();

            Map<String, Object> healthStatus = new HashMap<>();
            healthStatus.put("s3_connected", isConnected);
            healthStatus.put("timestamp", System.currentTimeMillis());
            healthStatus.put("status", isConnected ? "UP" : "DOWN");

            HttpStatus status = isConnected ? HttpStatus.OK : HttpStatus.SERVICE_UNAVAILABLE;

            log.info("📊 S3 헬스체크 - 상태: {}", isConnected ? "정상" : "오류");
            return ResponseEntity.status(status).body(healthStatus);

        } catch (Exception e) {
            log.error("❌ S3 헬스체크 실패: {}", e.getMessage());

            Map<String, Object> errorStatus = new HashMap<>();
            errorStatus.put("s3_connected", false);
            errorStatus.put("error", e.getMessage());
            errorStatus.put("timestamp", System.currentTimeMillis());
            errorStatus.put("status", "ERROR");

            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorStatus);
        }
    }

    /**
     * 💾 기존 로컬 파일 다운로드 API (호환성 유지, 추후 제거 예정)
     */
    @PostMapping("/download/audio")
    @Deprecated
    public ResponseEntity<byte[]> downloadAudioFile(@RequestBody Map<String, String> request) {
        try {
            String filePath = request.get("filePath");
            log.warn("⚠️ [DEPRECATED] 기존 로컬 파일 다운로드 API 호출: {}", filePath);
            log.warn("⚠️ 이 API는 곧 제거됩니다. S3 URL을 직접 사용하세요.");

            // S3 URL인 경우 리다이렉트 응답
            if (filePath != null && (filePath.contains("amazonaws.com") || filePath.contains("cloudfront.net"))) {
                log.info("🔄 S3 URL 감지, 클라이언트에게 직접 접근 안내");

                HttpHeaders headers = new HttpHeaders();
                headers.add("X-S3-Direct-Access", "true");
                headers.add("X-S3-URL", filePath);

                return ResponseEntity.status(HttpStatus.MOVED_PERMANENTLY)
                        .headers(headers)
                        .body("S3 URL로 직접 접근하세요.".getBytes());
            }

            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body("로컬 파일 지원이 중단되었습니다. S3를 사용하세요.".getBytes());

        } catch (Exception e) {
            log.error("❌ 기존 API 호출 실패: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(("API가 변경되었습니다: " + e.getMessage()).getBytes());
        }
    }

}