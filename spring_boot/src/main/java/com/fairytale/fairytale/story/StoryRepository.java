package com.fairytale.fairytale.story;

import com.fairytale.fairytale.users.Users;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface StoryRepository extends JpaRepository<Story,Long> {
    Optional<Story> findByIdAndUser(Long id, Users user);
    /**
     * 사용자의 이미지가 있는 스토리들 조회 (최신순)
     */
    List<Story> findByUserAndImageIsNotNullOrderByCreatedAtDesc(Users user);

    /**
     * 사용자의 이미지가 있는 스토리 개수
     */
    long countByUserAndImageIsNotNull(Users user);

    /**
     * 사용자의 총 스토리 개수
     */
    long countByUser(Users user);
}
