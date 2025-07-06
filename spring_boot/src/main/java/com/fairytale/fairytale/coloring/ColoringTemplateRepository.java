package com.fairytale.fairytale.coloring;

import com.fairytale.fairytale.users.Users;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ColoringTemplateRepository extends JpaRepository<ColoringTemplate, Long> {
    // ====== 🎯 사용자별 조회 메서드들 (새로 추가) ======

    // 사용자별 동화 ID로 색칠공부 템플릿 조회
    Optional<ColoringTemplate> findByStoryIdAndUser(String storyId, Users user);

    // 사용자별 최신순 조회
    Page<ColoringTemplate> findByUserOrderByCreatedAtDesc(Users user, Pageable pageable);

    // 사용자별 제목 검색
    Page<ColoringTemplate> findByUserAndTitleContainingOrderByCreatedAtDesc(Users user, String keyword, Pageable pageable);

    // 사용자별 특정 동화 ID들의 템플릿 조회
    Page<ColoringTemplate> findByUserAndStoryIdInOrderByCreatedAtDesc(Users user, List<String> storyIds, Pageable pageable);

    // 사용자별 모든 템플릿 조회 (List 형태)
    List<ColoringTemplate> findByUser(Users user);

    // ====== 기존 메서드들 (관리자용 또는 호환성용) ======

    // 전체 최신순 조회 (관리자용)
    Page<ColoringTemplate> findAllByOrderByCreatedAtDesc(Pageable pageable);

    // 동화 ID로 조회 (사용자 구분 없음 - 주의해서 사용)
    Optional<ColoringTemplate> findByStoryId(String storyId);

    // 제목 검색 (사용자 구분 없음 - 관리자용)
    Page<ColoringTemplate> findByTitleContainingOrderByCreatedAtDesc(String keyword, Pageable pageable);

    // 특정 동화 ID들의 템플릿 조회 (사용자 구분 없음 - 관리자용)
    Page<ColoringTemplate> findByStoryIdInOrderByCreatedAtDesc(List<String> storyIds, Pageable pageable);
}
