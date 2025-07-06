package com.fairytale.fairytale.auth.strategy;

import com.fairytale.fairytale.users.Users;
import org.springframework.security.core.Authentication;

public interface AuthStrategy {
    String authenticate(Users user, Long durationMs); // 로그인 후 토큰 발급
    boolean isValid(String token); // 유효성 검사
    String getUsername(String token); // 토큰에서 사용자 정보 추출
    Authentication getAuthentication(String token);
}
