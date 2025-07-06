package com.fairytale.fairytale.like;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface LIkeRepository extends JpaRepository<Like, Long> {
}
