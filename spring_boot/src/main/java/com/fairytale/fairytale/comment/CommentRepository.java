// src/main/java/com/fairytale/fairytale/comment/CommentRepository.java
package com.fairytale.fairytale.comment;

import jakarta.transaction.Transactional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface CommentRepository extends JpaRepository<Comment, Long> {

    // 특정 게시물의 댓글 조회 (최신순)
    List<Comment> findBySharePostIdOrderByCreatedAtDesc(Long sharePostId);

    // 특정 게시물의 댓글 페이징 조회
    Page<Comment> findBySharePostIdOrderByCreatedAtDesc(Long sharePostId, Pageable pageable);

    // 특정 게시물의 댓글 개수
    long countBySharePostId(Long sharePostId);

    // 사용자별 댓글 조회
    List<Comment> findByUsernameOrderByCreatedAtDesc(String username);

    // 게시물별 댓글 개수 조회 (여러 게시물)
    @Query("SELECT c.sharePost.id, COUNT(c) FROM Comment c WHERE c.sharePost.id IN :sharePostIds GROUP BY c.sharePost.id")
    List<Object[]> countCommentsBySharePostIds(@Param("sharePostIds") List<Long> sharePostIds);

    @Modifying
    @Transactional
    @Query("DELETE FROM Comment c WHERE c.sharePost.id = :sharePostId")
    void deleteBySharePostId(@Param("sharePostId") Long sharePostId);

}
