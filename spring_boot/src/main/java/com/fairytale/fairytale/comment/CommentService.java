package com.fairytale.fairytale.comment;

import com.fairytale.fairytale.share.SharePost;
import com.fairytale.fairytale.share.SharePostRepository;
import com.fairytale.fairytale.users.Users;
import com.fairytale.fairytale.users.UsersRepository;
import com.fairytale.fairytale.baby.Baby;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class CommentService {

    private final CommentRepository commentRepository;
    private final SharePostRepository sharePostRepository;
    private final UsersRepository usersRepository;

    /**
     * 🗨️ 댓글 작성
     */
    public Comment createComment(Long sharePostId, String username, String content) {
        log.info("🗨️ 댓글 작성 - SharePostId: {}, Username: {}, Content: {}", sharePostId, username, content);

        // 1. 게시물 존재 확인
        SharePost sharePost = sharePostRepository.findById(sharePostId)
                .orElseThrow(() -> new RuntimeException("게시물을 찾을 수 없습니다: " + sharePostId));

        // 2. 사용자 정보 조회
        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + username));

        // 🎯 3. Users 엔티티의 메서드 사용
        String displayName = user.getDisplayNameWithBaby(); // 🎯 Users에서 제공하는 메서드 사용
        log.info("🎯 댓글 작성자 표시명: {}", displayName);

        // 4. 댓글 생성
        Comment comment = Comment.builder()
                .sharePost(sharePost)
                .username(username)
                .userName(displayName) // 🎯 "아이이름의 부모" 형식
                .content(content)
                .build();

        Comment savedComment = commentRepository.save(comment);
        log.info("✅ 댓글 작성 완료 - CommentId: {}, DisplayName: {}", savedComment.getId(), displayName);

        return savedComment;
    }

    /**
     * 📖 게시물별 댓글 조회
     */
    public Page<Comment> getCommentsBySharePostId(Long sharePostId, Pageable pageable) {
        log.info("📖 댓글 조회 - SharePostId: {}", sharePostId);

        if (!sharePostRepository.existsById(sharePostId)) {
            throw new RuntimeException("게시물을 찾을 수 없습니다: " + sharePostId);
        }

        return commentRepository.findBySharePostIdOrderByCreatedAtDesc(sharePostId, pageable);
    }

    /**
     * ✏️ 댓글 수정
     */
    public Comment updateComment(Long commentId, String username, String content) {
        log.info("✏️ 댓글 수정 - CommentId: {}, Username: {}", commentId, username);

        Comment comment = commentRepository.findById(commentId)
                .orElseThrow(() -> new RuntimeException("댓글을 찾을 수 없습니다: " + commentId));

        if (!comment.getUsername().equals(username)) {
            throw new RuntimeException("댓글을 수정할 권한이 없습니다.");
        }

        comment.setContent(content);
        comment.setUpdatedAt(java.time.LocalDateTime.now());

        return commentRepository.save(comment);
    }

    /**
     * 🗑️ 댓글 삭제
     */
    public void deleteComment(Long commentId, String username) {
        log.info("🗑️ 댓글 삭제 - CommentId: {}, Username: {}", commentId, username);

        Comment comment = commentRepository.findById(commentId)
                .orElseThrow(() -> new RuntimeException("댓글을 찾을 수 없습니다: " + commentId));

        if (!comment.getUsername().equals(username)) {
            throw new RuntimeException("댓글을 삭제할 권한이 없습니다.");
        }

        commentRepository.delete(comment);
        log.info("✅ 댓글 삭제 완료 - CommentId: {}", commentId);
    }

    /**
     * 🔢 댓글 개수 조회
     */
    public long getCommentCount(Long sharePostId) {
        return commentRepository.countBySharePostId(sharePostId);
    }

    /**
     * 🎯 사용자 표시명 생성 (ShareService와 동일한 로직)
     */
    private String generateDisplayName(String username) {
        try {
            log.info("🔍 댓글 작성자 표시명 생성 - Username: {}", username);

            // 1. 사용자 정보 조회
            Users user = usersRepository.findByUsername(username).orElse(null);
            if (user == null) {
                log.warn("⚠️ 사용자를 찾을 수 없음: {}", username);
                return username + "님";
            }

            // 2. 🎯 Baby 엔티티에서 아이 이름 가져오기
            try {
                List<Baby> babies = user.getBabies();
                if (babies != null && !babies.isEmpty()) {
                    // 첫 번째 아기의 이름 사용
                    Baby firstBaby = babies.get(0);
                    String babyName = firstBaby.getBabyName(); // 🎯 실제 필드명 사용

                    if (babyName != null && !babyName.trim().isEmpty()) {
                        String displayName = babyName + "의 부모";
                        log.info("✅ 댓글 작성자 표시명 생성: {}", displayName);
                        return displayName;
                    }
                }
            } catch (Exception e) {
                log.info("ℹ️ Baby 정보 조회 실패, 다른 방법 시도: {}", e.getMessage());
            }

            // 3. Users의 getName() 메서드 사용
            String userName = user.getName();
            if (userName != null && !userName.trim().isEmpty()) {
                String displayName = userName + "님";
                log.info("✅ 사용자명으로 표시명 생성: {}", displayName);
                return displayName;
            }

            // 4. 최종 폴백
            String displayName = username + "님";
            log.info("✅ 최종 폴백 표시명 생성: {}", displayName);
            return displayName;

        } catch (Exception e) {
            log.error("❌ 표시명 생성 실패: {}", e.getMessage());
            return username + "님"; // 최종 폴백
        }
    }
}