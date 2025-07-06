package com.fairytale.fairytale.users;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class UsersController {
    private final UsersService usersService;

    /**
     * 프로필 이미지 URL 업데이트 (실제 DB 연동)
     */
    @PutMapping("/profile-image")
    public ResponseEntity<Map<String, Object>> updateProfileImage(
            @RequestBody Map<String, Object> request) {

        try {
            Long userId = Long.valueOf(request.get("userId").toString());
            String profileImageKey = request.get("profileImageKey").toString();

            log.info("🔍 프로필 이미지 URL 업데이트 요청: userId={}, profileImageKey={}",
                    userId, profileImageKey);

            // S3 URL 생성
            String profileImageUrl = String.format(
                    "https://fairytale-s3bucket.s3.ap-northeast-2.amazonaws.com/%s",
                    profileImageKey
            );

            // ✅ 실제 데이터베이스 업데이트
            usersService.updateProfileImageUrl(userId, profileImageUrl);

            log.info("✅ 프로필 이미지 URL 업데이트 성공: userId={}, url={}", userId, profileImageUrl);

            // 성공 응답
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "프로필 이미지가 성공적으로 업데이트되었습니다.");
            response.put("profileImageUrl", profileImageUrl);
            response.put("userId", userId);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 프로필 이미지 URL 업데이트 실패: error={}", e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", e.getMessage());

            return ResponseEntity.internalServerError().body(response);
        }
    }

    /**
     * 사용자 프로필 조회 (실제 DB 연동)
     */
    @GetMapping("/profile/{userId}")
    public ResponseEntity<Map<String, Object>> getUserProfile(@PathVariable Long userId) {
        try {
            log.info("🔍 사용자 프로필 조회: userId={}", userId);

            // ✅ 실제 데이터베이스에서 사용자 정보 조회
            Users user = usersService.getUserById(userId);

            if (user == null) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("error", "사용자를 찾을 수 없습니다.");
                return ResponseEntity.badRequest().body(response);
            }

            // 사용자 데이터 구성
            Map<String, Object> userData = new HashMap<>();
            userData.put("id", user.getId());
            userData.put("username", user.getUsername());
            userData.put("nickname", user.getNickname());
            userData.put("email", user.getEmail());
            userData.put("profileImageUrl", user.getProfileImageUrl()); // ✅ 실제 DB에서 조회
            userData.put("createdAt", user.getCreatedAt());

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("user", userData);

            log.info("✅ 사용자 프로필 조회 성공: userId={}, profileImageUrl={}",
                    userId, user.getProfileImageUrl());

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 사용자 프로필 조회 실패: userId={}, error={}", userId, e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "사용자 정보 조회 중 오류가 발생했습니다.");

            return ResponseEntity.internalServerError().body(response);
        }
    }

    /**
     * 프로필 이미지 삭제 (실제 DB 연동)
     */
    @DeleteMapping("/profile-image/{userId}")
    public ResponseEntity<Map<String, Object>> removeProfileImage(@PathVariable Long userId) {
        try {
            log.info("🔍 프로필 이미지 삭제 요청: userId={}", userId);

            // ✅ 실제 데이터베이스에서 프로필 이미지 URL 삭제
            usersService.removeProfileImageUrl(userId);

            log.info("✅ 프로필 이미지 삭제 성공: userId={}", userId);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "프로필 이미지가 성공적으로 삭제되었습니다.");
            response.put("userId", userId);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 프로필 이미지 삭제 실패: userId={}, error={}", userId, e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", e.getMessage());

            return ResponseEntity.internalServerError().body(response);
        }
    }

    /**
     * 헬스 체크 (테스트용)
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "UP");
        response.put("service", "Users API");
        response.put("timestamp", System.currentTimeMillis());
        return ResponseEntity.ok(response);
    }
}