package com.fairytale.fairytale.auth.dto;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.Getter;
import lombok.Setter;

@Entity
@Getter
@Setter
public class RefreshToken {
    @Id
    private Long userId;

    @Column(nullable = false)
    private String refreshToken;

    // 기본 생성자 (JPA 필수)
    public RefreshToken() {}

    // 생성자
    public RefreshToken(Long userId, String refreshToken) {
        this.userId = userId;
        this.refreshToken = refreshToken;
    }
}
