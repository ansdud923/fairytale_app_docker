package com.fairytale.fairytale.coloring;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ColoringWorkRepository extends JpaRepository<ColoringWork, Long> {

    // 사용자별 색칠 완성작 조회 (최신순)
    List<ColoringWork> findByUsernameOrderByCreatedAtDesc(String username);

    // 사용자별 색칠 완성작 개수
    long countByUsername(String username);

    // 특정 기간 내 색칠 완성작 조회
    List<ColoringWork> findByUsernameAndCreatedAtAfterOrderByCreatedAtDesc(
            String username, java.time.LocalDateTime after);
}