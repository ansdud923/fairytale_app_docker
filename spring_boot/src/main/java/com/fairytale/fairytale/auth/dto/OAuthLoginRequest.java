package com.fairytale.fairytale.auth.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class OAuthLoginRequest {
    private String provider;
    private String accessToken;
}
