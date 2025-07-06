// src/main/java/com/fairytale/fairytale/share/SharePostRepository.java
package com.fairytale.fairytale.share;

import com.fairytale.fairytale.users.Users;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.data.domain.Pageable;
import java.time.LocalDateTime;


import java.util.List;

@Repository
public interface SharePostRepository extends JpaRepository<SharePost, Long> {

    /**
     * 모든 공유 게시물을 최신순으로 조회
     */
    List<SharePost> findAllByOrderByCreatedAtDesc();

    /**
     * 특정 사용자의 공유 게시물 조회
     */
    List<SharePost> findByUserOrderByCreatedAtDesc(Users user);

    /**
     * 특정 소스(Story/Gallery)에서 생성된 게시물 확인
     */
    boolean existsBySourceTypeAndSourceId(String sourceType, Long sourceId);

    // 🎯 추가 메서드들

    // 좋아요 수 기준 내림차순 정렬
    List<SharePost> findAllByOrderByLikeCountDescCreatedAtDesc();

    // 사용자별 게시물 개수
    long countByUser(Users user);

    // 사용자가 받은 총 좋아요 수 (커스텀 쿼리)
    @Query("SELECT COALESCE(SUM(sp.likeCount), 0) FROM SharePost sp WHERE sp.user = :user")
    long sumLikesByUser(@Param("user") Users user);

    // 인기 게시물 조회 (좋아요 수 기준, 페이징)
    @Query("SELECT sp FROM SharePost sp ORDER BY sp.likeCount DESC, sp.createdAt DESC")
    List<SharePost> findPopularPosts(Pageable pageable);

    // 특정 기간 내 게시물 조회
    @Query("SELECT sp FROM SharePost sp WHERE sp.createdAt >= :startDate ORDER BY sp.createdAt DESC")
    List<SharePost> findPostsSince(@Param("startDate") LocalDateTime startDate);

    // 소스 타입별 게시물 조회
    List<SharePost> findBySourceTypeOrderByCreatedAtDesc(String sourceType);
}