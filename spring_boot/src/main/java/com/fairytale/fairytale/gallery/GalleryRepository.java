package com.fairytale.fairytale.gallery;

import com.fairytale.fairytale.users.Users;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface GalleryRepository extends JpaRepository<Gallery, Long> {

    /**
     * 사용자의 모든 갤러리 이미지 조회 (최신순)
     */
    List<Gallery> findByUserOrderByCreatedAtDesc(Users user);

    Optional<Gallery> findByStoryId(Long storyId);

    /**
     * 특정 스토리의 갤러리 이미지 조회
     */
    @Query("SELECT g FROM Gallery g WHERE g.storyId = :storyId AND g.user = :user")
    Gallery findByStoryIdAndUser(@Param("storyId") Long storyId, @Param("user") Users user);

    /**
     * 사용자의 색칠한 이미지 개수 조회
     */
    long countByUserAndColoringImageUrlIsNotNull(Users user);

    /**
     * 사용자의 특정 스토리 갤러리 존재 여부 확인
     */
    boolean existsByStoryIdAndUser(Long storyId, Users user);

    /**
     * 사용자의 최근 갤러리 이미지들 조회 (제한된 개수)
     */
    @Query("SELECT g FROM Gallery g WHERE g.user = :user ORDER BY g.createdAt DESC")
    List<Gallery> findTop10ByUserOrderByCreatedAtDesc(@Param("user") Users user);

    /**
     * 색칠한 이미지가 있는 갤러리만 조회
     */
    List<Gallery> findByUserAndColoringImageUrlIsNotNullOrderByCreatedAtDesc(Users user);
}