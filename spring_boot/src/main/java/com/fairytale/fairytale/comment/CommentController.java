// src/main/java/com/fairytale/fairytale/comment/CommentController.java
package com.fairytale.fairytale.comment;

import com.fairytale.fairytale.users.Users;
import com.fairytale.fairytale.users.UsersRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequestMapping("/api/share/comments") // 🎯 경로 확인
@RequiredArgsConstructor
public class CommentController {

    private final CommentService commentService;
    private final UsersRepository usersRepository; // 🎯 추가

    /**
     * 🗨️ 댓글 작성
     */
    @PostMapping("/{sharePostId}")
    public ResponseEntity<?> createComment(
            @PathVariable Long sharePostId,
            @RequestBody Map<String, String> request,
            Authentication authentication) {

        try {
            String username = getCurrentUsername(authentication);
            String content = request.get("content");

            log.info("🗨️ 댓글 작성 - SharePostId: {}, Username: {}", sharePostId, username);

            if (content == null || content.trim().isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(Map.of("success", false, "error", "댓글 내용을 입력해주세요"));
            }

            Comment comment = commentService.createComment(sharePostId, username, content.trim());

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("comment", convertCommentToDTO(comment, username)); // 🎯 isOwner 정보 포함
            response.put("message", "댓글이 작성되었습니다");

            log.info("✅ 댓글 작성 완료 - CommentId: {}", comment.getId());
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 댓글 작성 실패: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("success", false, "error", e.getMessage()));
        }
    }

    /**
     * 📖 댓글 조회 (isOwner 정보 포함)
     */
    @GetMapping("/{sharePostId}")
    public ResponseEntity<Map<String, Object>> getComments(
            @PathVariable Long sharePostId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Authentication authentication) {
        try {
            String currentUsername = getCurrentUsername(authentication);
            log.info("📖 댓글 조회 - SharePostId: {}, CurrentUser: {}", sharePostId, currentUsername);

            Pageable pageable = PageRequest.of(page, size);
            Page<Comment> commentPage = commentService.getCommentsBySharePostId(sharePostId, pageable);

            // 🎯 댓글 DTO 변환 (isOwner 정보 포함)
            List<Map<String, Object>> commentDTOs = commentPage.getContent().stream()
                    .map(comment -> convertCommentToDTO(comment, currentUsername))
                    .collect(Collectors.toList());

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("comments", commentDTOs);
            response.put("currentPage", commentPage.getNumber());
            response.put("totalPages", commentPage.getTotalPages());
            response.put("totalElements", commentPage.getTotalElements());

            log.info("✅ 댓글 조회 완료 - {}개", commentDTOs.size());
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 댓글 조회 실패: {}", e.getMessage());
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("message", "댓글 조회에 실패했습니다: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * ✏️ 댓글 수정
     */
    @PutMapping("/{commentId}")
    public ResponseEntity<?> updateComment(
            @PathVariable Long commentId,
            @RequestBody Map<String, String> request,
            Authentication authentication) {

        try {
            String username = getCurrentUsername(authentication);
            String content = request.get("content");

            log.info("✏️ 댓글 수정 - CommentId: {}, Username: {}", commentId, username);

            if (content == null || content.trim().isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(Map.of("success", false, "error", "댓글 내용을 입력해주세요"));
            }

            Comment comment = commentService.updateComment(commentId, username, content.trim());

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("comment", convertCommentToDTO(comment, username)); // 🎯 isOwner 정보 포함
            response.put("message", "댓글이 수정되었습니다");

            log.info("✅ 댓글 수정 완료 - CommentId: {}", comment.getId());
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 댓글 수정 실패: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("success", false, "error", e.getMessage()));
        }
    }

    /**
     * 🗑️ 댓글 삭제
     */
    @DeleteMapping("/{commentId}")
    public ResponseEntity<Map<String, Object>> deleteComment(
            @PathVariable Long commentId,
            Authentication authentication) {
        try {
            String username = getCurrentUsername(authentication);
            log.info("🗑️ 댓글 삭제 요청 - CommentId: {}, Username: {}", commentId, username);

            commentService.deleteComment(commentId, username);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "댓글이 삭제되었습니다.");

            log.info("✅ 댓글 삭제 완료 - CommentId: {}", commentId);
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 댓글 삭제 실패: {}", e.getMessage());
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("message", "댓글 삭제에 실패했습니다: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(errorResponse);
        }
    }

    /**
     * 🔢 게시물별 댓글 개수 조회
     */
    @GetMapping("/count/{sharePostId}")
    public ResponseEntity<?> getCommentCount(@PathVariable Long sharePostId) {
        try {
            long count = commentService.getCommentCount(sharePostId);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("commentCount", count);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 댓글 개수 조회 실패: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("success", false, "error", e.getMessage()));
        }
    }

    /**
     * 🔧 현재 사용자명 가져오기
     */
    private String getCurrentUsername(Authentication authentication) {
        return authentication != null ? authentication.getName() : null;
    }

    /**
     * 🔧 Comment 엔티티를 DTO로 변환 (아기 이름으로 표시명 생성)
     */
    private Map<String, Object> convertCommentToDTO(Comment comment, String currentUsername) {
        Map<String, Object> dto = new HashMap<>();
        dto.put("id", comment.getId());
        dto.put("content", comment.getContent());
        dto.put("username", comment.getUsername());

        // 🎯 사용자 정보 조회해서 아기 이름으로 표시명 생성
        String displayName = generateDisplayName(comment.getUsername());
        dto.put("userName", displayName);

        dto.put("createdAt", comment.getCreatedAt().toString());
        dto.put("updatedAt", comment.getUpdatedAt() != null ?
                comment.getUpdatedAt().toString() : null);
        dto.put("isEdited", comment.getUpdatedAt() != null);

        // 🎯 작성자 여부 확인 (가장 중요한 부분!)
        dto.put("isOwner", comment.getUsername().equals(currentUsername));

        return dto;
    }

    /**
     * 🎯 사용자명을 아기 이름으로 변환하는 메서드
     */
    private String generateDisplayName(String username) {
        try {
            Optional<Users> userOpt = usersRepository.findByUsername(username);
            if (userOpt.isPresent()) {
                Users user = userOpt.get();
                // Users 엔티티에 getDisplayNameWithBaby() 메서드가 있으면 사용
                if (user.getDisplayNameWithBaby() != null) {
                    return user.getDisplayNameWithBaby();
                } else {
                    return user.getNickname() + "님";
                }
            }
        } catch (Exception e) {
            log.warn("⚠️ 사용자 표시명 생성 실패: {}", e.getMessage());
        }
        return username + "님";
    }
}