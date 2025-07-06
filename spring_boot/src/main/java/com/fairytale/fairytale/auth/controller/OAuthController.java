package com.fairytale.fairytale.auth.controller;

import com.fairytale.fairytale.auth.dto.OAuthLoginRequest;
import com.fairytale.fairytale.auth.dto.RefreshTokenRequest;
import com.fairytale.fairytale.auth.dto.TokenResponse;
import com.fairytale.fairytale.auth.service.OAuthService;
import com.fairytale.fairytale.auth.strategy.JwtAuthStrategy;
import com.fairytale.fairytale.role.Role;
import com.fairytale.fairytale.role.RoleRepository;
import com.fairytale.fairytale.users.Users;
import com.fairytale.fairytale.users.UsersRepository;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.Map;

@RestController
@RequestMapping("/oauth")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class OAuthController {
    private final OAuthService oauthService;
    private final UsersRepository usersRepository;
    private final RoleRepository roleRepository;
    private final JwtAuthStrategy jwtAuthStrategy;

    @PostMapping("/login")
    public ResponseEntity<TokenResponse> socialLogin(@RequestBody OAuthLoginRequest request) {
        try {
            log.info("OAuth 로그인 요청 - Provider: {}", request.getProvider());
            TokenResponse tokenResponse = oauthService.loginWithAccessToken(request);
            log.info("OAuth 로그인 성공 - Provider: {}", request.getProvider());
            return ResponseEntity.ok(tokenResponse);
        } catch (Exception e) {
            log.error("OAuth 로그인 실패 - Provider: {}, Error: {}", request.getProvider(), e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(TokenResponse.builder()
                            .accessToken("error")
                            .refreshToken("error")
                            .build());
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<String> logout(HttpServletRequest request) {
        String token = resolveToken(request);
        if (token != null) {
            oauthService.logout(token);
            return ResponseEntity.ok("로그아웃 성공");
        }
        return ResponseEntity.badRequest().body("토큰이 없습니다.");
    }

    // 토큰 갱신 추가
    @PostMapping("/refresh")
    public ResponseEntity<TokenResponse> refreshToken(@RequestBody RefreshTokenRequest request) {
        TokenResponse newTokens = oauthService.refreshTokens(request.getRefreshToken());
        return ResponseEntity.ok(newTokens);
    }

    // Authorization 헤더에서 토큰 추출
    private String resolveToken(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }

    // 🆕 테스트용 토큰 발급 엔드포인트
    @PostMapping("/test/token")
    public ResponseEntity<TokenResponse> getTestToken(@RequestBody Map<String, String> request) {
        try {
            String username = request.getOrDefault("username", "testuser123");

            Users testUser = usersRepository.findByUsername(username)
                    .orElseGet(() -> {
                        // 테스트 사용자가 없으면 생성
                        Role userRole = roleRepository.findByRoleName("USER")
                                .orElseGet(() -> {
                                    Role newRole = new Role();
                                    newRole.setRoleName("USER");
                                    return roleRepository.save(newRole);
                                });

                        Users newUser = Users.builder()
                                .username(username)
                                .nickname("테스트사용자")
                                .email(username + "@test.com")
                                .role(userRole)
                                .build();
                        return usersRepository.save(newUser);
                    });

            TokenResponse tokens = jwtAuthStrategy.generateTokens(testUser);
            log.info("테스트 토큰 발급 완료 - Username: {}", username);
            return ResponseEntity.ok(tokens);
        } catch (Exception e) {
            log.error("테스트 토큰 발급 실패: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    // 🆕 헬스체크 엔드포인트
    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        return ResponseEntity.ok(Map.of(
                "status", "ok",
                "service", "oauth",
                "timestamp", LocalDateTime.now().toString()
        ));
    }
}