// src/main/java/com/fairytale/fairytale/controller/UploadController.java
package com.fairytale.fairytale.controller;

import com.fairytale.fairytale.service.S3Service;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/upload")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class UploadController {

    private final S3Service s3Service;

    /**
     * 프로필 이미지 직접 업로드
     */
    @PostMapping("/profile-image")
    public ResponseEntity<Map<String, Object>> uploadProfileImage(
            @RequestParam("file") MultipartFile file,
            @RequestParam("userId") Long userId) {

        try {
            log.info("🔍 프로필 이미지 업로드 요청: userId={}, fileName={}, size={}",
                    userId, file.getOriginalFilename(), file.getSize());

            // 입력값 검증
            if (file.isEmpty()) {
                return ResponseEntity.badRequest().body(createErrorResponse("파일이 비어있습니다."));
            }

            if (userId == null || userId <= 0) {
                return ResponseEntity.badRequest().body(createErrorResponse("유효하지 않은 사용자 ID입니다."));
            }

            // S3에 업로드
            String imageUrl = s3Service.uploadProfileImage(file, userId);

            // 성공 응답
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "프로필 이미지가 성공적으로 업로드되었습니다.");
            response.put("profileImageUrl", imageUrl);
            response.put("userId", userId);

            log.info("✅ 프로필 이미지 업로드 성공: userId={}, url={}", userId, imageUrl);
            return ResponseEntity.ok(response);

        } catch (IllegalArgumentException e) {
            log.warn("⚠️ 프로필 이미지 업로드 실패 (잘못된 입력): userId={}, error={}", userId, e.getMessage());
            return ResponseEntity.badRequest().body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            log.error("❌ 프로필 이미지 업로드 실패: userId={}, error={}", userId, e.getMessage());
            return ResponseEntity.internalServerError().body(createErrorResponse("서버 오류가 발생했습니다."));
        }
    }

    /**
     * Presigned URL 생성 (클라이언트에서 직접 업로드용)
     */
    @PostMapping("/profile-image/presigned-url")
    public ResponseEntity<Map<String, Object>> generatePresignedUrl(
            @RequestBody Map<String, Object> request) {

        try {
            // 요청 파라미터 추출
            Long userId = Long.valueOf(request.get("userId").toString());
            String fileType = request.get("fileType").toString();

            log.info("🔍 Presigned URL 생성 요청: userId={}, fileType={}", userId, fileType);

            // 입력값 검증
            if (userId == null || userId <= 0) {
                return ResponseEntity.badRequest().body(createErrorResponse("유효하지 않은 사용자 ID입니다."));
            }

            if (fileType == null || !fileType.startsWith("image/")) {
                return ResponseEntity.badRequest().body(createErrorResponse("지원하지 않는 파일 형식입니다."));
            }

            // Presigned URL 생성
            Map<String, Object> presignedData = s3Service.generatePresignedUrl(userId, fileType);

            // 성공 응답
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Presigned URL이 생성되었습니다.");
            response.putAll(presignedData);

            log.info("✅ Presigned URL 생성 성공: userId={}", userId);
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ Presigned URL 생성 실패: error={}", e.getMessage());
            return ResponseEntity.internalServerError().body(createErrorResponse("서버 오류가 발생했습니다."));
        }
    }

    /**
     * 업로드 완료 확인
     */
    @PostMapping("/profile-image/verify")
    public ResponseEntity<Map<String, Object>> verifyUpload(@RequestBody Map<String, String> request) {
        try {
            String fileName = request.get("fileName");

            if (fileName == null || fileName.trim().isEmpty()) {
                return ResponseEntity.badRequest().body(createErrorResponse("파일명이 필요합니다."));
            }

            boolean exists = s3Service.doesFileExist(fileName);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("exists", exists);

            if (exists) {
                response.put("message", "파일이 성공적으로 업로드되었습니다.");
                response.put("publicUrl", String.format("https://fairytale-s3bucket.s3.ap-northeast-2.amazonaws.com/%s", fileName));
            } else {
                response.put("message", "파일을 찾을 수 없습니다.");
            }

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 업로드 확인 실패: error={}", e.getMessage());
            return ResponseEntity.internalServerError().body(createErrorResponse("서버 오류가 발생했습니다."));
        }
    }

    // === Helper Methods ===

    private Map<String, Object> createErrorResponse(String message) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", false);
        response.put("error", message);
        return response;
    }
}