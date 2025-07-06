package com.fairytale.fairytale.auth.dto;

import lombok.*;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Builder
public class TokenResponse {
    private String accessToken;
    private String refreshToken;
    private String type;

    // 🆕 추가!
    private Long userId;        // DB PK
    private String userEmail;   // 이메일
    private String userName;    // username

    public TokenResponse(String accessToken, String refreshToken) {
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
    }
}
