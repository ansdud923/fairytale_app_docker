package com.fairytale.fairytale.baby;

import com.fairytale.fairytale.users.Users;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BabyRepository extends JpaRepository<Baby, Long> {

    // 사용자 ID로 아이 정보 조회
    @Query("SELECT b FROM Baby b WHERE b.user.id = :userId")
    Baby findByUserId(@Param("userId") Long userId);

    // 사용자 ID로 모든 아이 정보 조회 (다중 자녀 지원용)
    @Query("SELECT b FROM Baby b WHERE b.user.id = :userId ORDER BY b.createdAt DESC")
    List<Baby> findAllByUserId(@Param("userId") Long userId);

    // 아이 이름으로 검색
    @Query("SELECT b FROM Baby b WHERE b.babyName LIKE %:name%")
    List<Baby> findByBabyNameContaining(@Param("name") String name);

    // 특정 사용자의 아이 개수 조회
    @Query("SELECT COUNT(b) FROM Baby b WHERE b.user.id = :userId")
    long countByUserId(@Param("userId") Long userId);

    Object findByUser(Users user);
}