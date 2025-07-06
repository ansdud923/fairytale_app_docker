package com.fairytale.fairytale.auth.strategy;

import com.fairytale.fairytale.auth.dto.TokenResponse;
import com.fairytale.fairytale.users.Users;
import com.fairytale.fairytale.users.UsersRepository;
import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.stereotype.Component;
import java.security.Key;
import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.Optional;

@Component("jwtAuthStrategy") // 스프링 빈으로 등록
@RequiredArgsConstructor
public class JwtAuthStrategy implements AuthStrategy {
    private final UsersRepository usersRepository;

    @Value("${JWT_SECRET}") // application.yml에서 jwt.secret 값 주입
    private String secretKeyString;

    @Value("${JWT_EXPIRATION:3600000}") // application.yml에서 accessToken 만료시간 주입
    private Long accessTokenExpirationTimeMs;

    @Value("${JWT_REFRESH_EXPIRATION:1209600000}")
    private Long refreshTokenExpirationMs;

    private Key key; // 실제 JWT 서명에 쓰일 key 객체

    @PostConstruct
    public void init() {
        // secretKeyString을 바이트 배열로 바꿔서
        // HMAC-SHA256 서명용 Key 객체 생성
        this.key = Keys.hmacShaKeyFor(secretKeyString.getBytes());
    }

    public TokenResponse generateTokens(Users user) {
        String accessToken = authenticate(user, accessTokenExpirationTimeMs);
        String refreshToken = authenticate(user, refreshTokenExpirationMs);

        return new TokenResponse(accessToken, refreshToken);
    }

    // 로그인 후 토큰 발급 로직
    @Override
    public String authenticate(Users user, Long durationMs) {
        Date now = new Date(); // 현재 시간 생성
        Date expiry = new Date(now.getTime() + durationMs); // 만료 시간 계산

        // 🎯 여기가 핵심! - JWT subject에 username을 확실히 넣기
        String username = user.getUsername(); // username 필드 사용
        System.out.println("🔍 JWT 생성 - Username: " + username + ", Nickname: " + user.getNickname());

        return Jwts.builder()
                .setSubject(username) // 🎯 확실히 username을 넣기
                .setIssuedAt(now) // 발행 시간 설정
                .setExpiration(expiry) // 만료 시간 설정
                .signWith(key, SignatureAlgorithm.HS256) // 비밀키로 HS256 알고리즘 서명
                .compact(); // 최종 JWT 문자열 생성 후 리턴
    }

    // 유효성 검사 로직
    @Override
    public boolean isValid(String token) {
        try {
            // 토큰을 파싱하며 서명 검증도 같이 함
            Jwts.parserBuilder().setSigningKey(key).build().parseClaimsJws(token);
            return true; // 문제 없으면 true 반환 (유효한 토큰)
        } catch (JwtException | IllegalArgumentException e) {
            // 파싱 실패, 서명 검증 실패, 토큰이 잘못됐을 때 예외 잡음
            return false; // 유효하지 않은 토큰
        }
    }

    // 3. 토큰으로부터 Authentication 객체 얻기
    public Authentication getAuthentication(String token) {
        try {
            String username = getUsername(token);
            System.out.println("🔍 JWT에서 추출한 username: " + username);

            // 간단한 인증 객체 생성 (authorities는 필요에 따라 설정)
            return new UsernamePasswordAuthenticationToken(
                    username,
                    null,
                    Collections.singletonList(new SimpleGrantedAuthority("ROLE_USER"))
            );
        } catch (Exception e) {
            System.out.println("❌ JWT 인증 객체 생성 실패: " + e.getMessage());
            return null;
        }
    }

    // 토큰에서 사용자 정보 추출 로직
    @Override
    public String getUsername(String token) {
        // 토큰에서 페이로드 부분(Claims)(실제 데이터가 담겨 있는 부분) 파싱해서 가져옴
        Claims claims = Jwts.parserBuilder().setSigningKey(key).build()
                .parseClaimsJws(token)
                .getBody();
        return claims.getSubject(); // Claims에서 subject(사용자명) 반환
    }
}
