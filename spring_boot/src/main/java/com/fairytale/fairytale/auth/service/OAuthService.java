package com.fairytale.fairytale.auth.service;

import com.fairytale.fairytale.auth.dto.OAuthLoginRequest;
import com.fairytale.fairytale.auth.dto.RefreshToken;
import com.fairytale.fairytale.auth.dto.TokenResponse;
import com.fairytale.fairytale.auth.repository.RefreshTokenRepository;
import com.fairytale.fairytale.auth.strategy.JwtAuthStrategy;
import com.fairytale.fairytale.role.Role;
import com.fairytale.fairytale.role.RoleRepository;
import com.fairytale.fairytale.users.Users;
import com.fairytale.fairytale.users.UsersRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class OAuthService {
    private final RestTemplate restTemplate;
    private final UsersRepository usersRepository;
    private final RoleRepository roleRepository;
    private final JwtAuthStrategy jwtAuthStrategy;
    private final RefreshTokenRepository refreshTokenRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${KAKAO_USER_INFO_URI:https://kapi.kakao.com/v2/user/me}")
    private String kakaoUserInfoUri;
    @Value("${GOOGLE_USER_INFO_URI:https://openidconnect.googleapis.com/v1/userinfo}")
    private String googleUserInfoUri;
    @Value("${KAKAO_REDIRECT_URI:http://localhost:8080/login/oauth2/code/kakao}")
    private String kakaoUserRedirectUri;
    @Value("${GOOGLE_REDIRECT_URI:http://localhost:8080/login/oauth2/code/google}")
    private String googleUserRedirectUri;
    @Value("${KAKAO_CLIENT_ID}")
    private String kakaoClientId;
    @Value("${GOOGLE_CLIENT_ID}")
    private String googleClientId;
    @Value("${GOOGLE_CLIENT_SECRET}")
    private String googleClientSecret;

// OAuthService.java의 loginWithAccessToken 메서드에서 TokenResponse 생성 부분만 수정

    @Transactional
    public TokenResponse loginWithAccessToken(OAuthLoginRequest request) {
        System.out.println("🔍 OAuth 로그인 시작 - Provider: " + request.getProvider());
        // 클라이언트가 보낸 accessToken으로 바로 유저 정보 조회
        Users user = getUserInfoFromProvider(request.getProvider(), request.getAccessToken());
        System.out.println("🔍 소셜 로그인 사용자 정보: " + user.getUsername());
        // 사용자 DB에 저장 또는 업데이트
        Users savedUser = saveOrUpdateUser(user);
        System.out.println("🔍 DB 저장 완료 - ID: " + savedUser.getId() + ", Username: " + savedUser.getUsername());

        // 🎯 중요: JWT에 실제 username이 들어가도록 확인
        System.out.println("🔍 JWT 토큰 생성 - Username: " + savedUser.getUsername() + ", Nickname: " + savedUser.getNickname());

        // JWT 토큰 발급
        TokenResponse tokens = jwtAuthStrategy.generateTokens(savedUser);
        System.out.println("🔍 JWT 토큰 발급 완료");

        // RefreshToken 저장
        refreshTokenRepository.save(new RefreshToken(savedUser.getId(), tokens.getRefreshToken()));

        // 🎯 TokenResponse에서 userName을 실제 username으로 설정
        return TokenResponse.builder()
                .accessToken(tokens.getAccessToken())
                .refreshToken(tokens.getRefreshToken())
                .type(tokens.getType())
                .userId(savedUser.getId())
                .userEmail(savedUser.getEmail())
                .userName(savedUser.getUsername())    // 🎯 nickname이 아닌 username 사용!
                .build();
    }

    private Users getUserInfoFromProvider(String provider, String accessToken) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(accessToken);
        HttpEntity<String> entity = new HttpEntity<>(headers);

        String uri;
        if ("kakao".equalsIgnoreCase(provider)) {
            uri = kakaoUserInfoUri;
        } else if ("google".equalsIgnoreCase(provider)) {
            uri = googleUserInfoUri;
        } else {
            throw new IllegalArgumentException("지원하지 않는 소셜 로그인 제공자입니다.");
        }

        ResponseEntity<String> response = restTemplate.exchange(uri, HttpMethod.GET, entity, String.class);

        try {
            JsonNode root = objectMapper.readTree(response.getBody());

            if ("kakao".equalsIgnoreCase(provider)) {
                return parseKakaoUser(root);
            } else if ("google".equalsIgnoreCase(provider)) {
                return parseGoogleUser(root);
            }
        } catch (Exception e) {
            throw new RuntimeException(provider + " 사용자 정보 파싱 실패", e);
        }

        throw new IllegalStateException("사용자 정보 파싱 실패");
    }

    private Users parseKakaoUser(JsonNode root) {
        String kakaoId = root.get("id").asText();
        JsonNode account = root.get("kakao_account");
        String email = account.has("email") ? account.get("email").asText() : kakaoId + "@kakao.com";
        String nickname = account.get("profile").get("nickname").asText();

        // 🔧 고유한 사용자명 생성
        String username = generateUniqueUsername("kakao_" + kakaoId);
        String uniqueNickname = generateUniqueNickname(nickname);

        return Users.builder()
                .kakaoId(kakaoId)
                .email(email)
                .nickname(uniqueNickname)
                .username(username)
                .build();
    }

    private Users parseGoogleUser(JsonNode root) {
        String googleId = root.get("sub").asText();
        String email = root.get("email").asText();
        String nickname = root.get("name").asText();
        // 🔧 고유한 사용자명 생성
        String username = generateUniqueUsername("google_" + googleId);
        String uniqueNickname = generateUniqueNickname(nickname);

        return Users.builder()
                .googleId(googleId)
                .email(email)
                .nickname(uniqueNickname)
                .username(username)
                .build();
    }

    // 🆕 고유한 사용자명 생성 메서드 추가
    private String generateUniqueUsername(String baseUsername) {
        String username = baseUsername;
        int counter = 1;

        // 사용자명이 존재하면 뒤에 숫자 추가
        while (usersRepository.findByUsername(username).isPresent()) {
            username = baseUsername + "_" + counter;
            counter++;
            System.out.println("🔍 사용자명 중복으로 인한 변경: " + username);
        }

        return username;
    }

    // 🆕 고유한 닉네임 생성 메서드 추가
    private String generateUniqueNickname(String baseNickname) {
        String nickname = baseNickname;
        int counter = 1;

        while (usersRepository.findByNickname(nickname).isPresent()) {
            nickname = baseNickname + "_" + counter;
            counter++;
            System.out.println("🔍 닉네임 중복으로 인한 변경: " + nickname);
        }

        return nickname;
    }

    private Users saveOrUpdateUser(Users oauthUser) {
        System.out.println("🔍 saveOrUpdateUser 시작 - 이메일: " + oauthUser.getEmail());

        try {
            // 🆕 기본 USER 역할 설정
            System.out.println("🔍 USER 역할 찾는 중...");
            Role userRole = roleRepository.findByRoleName("USER")
                    .orElseGet(() -> {
                        System.out.println("⚠️ USER 역할이 없어서 새로 생성합니다.");
                        Role newRole = new Role();
                        newRole.setRoleName("USER");
                        return roleRepository.save(newRole);
                    });
            System.out.println("🔍 USER 역할 조회 완료");

            // OAuth 사용자에게 역할 설정
            oauthUser.setRole(userRole);
            System.out.println("🔍 사용자 역할 설정 완료: " + userRole.getRoleName());

            // 이메일로 찾기
            System.out.println("🔍 이메일로 사용자 찾는 중: " + oauthUser.getEmail());
            Optional<Users> emailUser = usersRepository.findByEmail(oauthUser.getEmail());
            System.out.println("🔍 이메일 조회 결과: " + (emailUser.isPresent() ? "발견" : "없음"));

            if (emailUser.isPresent()) {
                Users existingUser = emailUser.get();
                System.out.println("🔍 기존 사용자 업데이트: " + existingUser.getUsername());
                existingUser.setNickname(oauthUser.getNickname());

                if (existingUser.getRole() == null) {
                    existingUser.setRole(userRole);
                }

                if (oauthUser.getGoogleId() != null) {
                    existingUser.setGoogleId(oauthUser.getGoogleId());
                }
                if (oauthUser.getKakaoId() != null) {
                    existingUser.setKakaoId(oauthUser.getKakaoId());
                }

                return usersRepository.save(existingUser);
            }

            // 구글 ID로 찾기
            if (oauthUser.getGoogleId() != null) {
                System.out.println("🔍 구글 ID로 사용자 찾는 중: " + oauthUser.getGoogleId());
                Optional<Users> googleUser = usersRepository.findByGoogleId(oauthUser.getGoogleId());
                System.out.println("🔍 구글 ID 조회 결과: " + (googleUser.isPresent() ? "발견" : "없음"));

                if (googleUser.isPresent()) {
                    Users existingUser = googleUser.get();
                    System.out.println("🔍 기존 사용자 업데이트: " + existingUser.getUsername());
                    existingUser.setNickname(oauthUser.getNickname());
                    existingUser.setEmail(oauthUser.getEmail()); // 이메일 업데이트

                    if (existingUser.getRole() == null) {
                        existingUser.setRole(userRole);
                    }

                    return usersRepository.save(existingUser);
                }
            }

            // 카카오 ID로 찾기
            if (oauthUser.getKakaoId() != null) {
                System.out.println("🔍 카카오 ID로 사용자 찾는 중: " + oauthUser.getKakaoId());
                Optional<Users> kakaoUser = usersRepository.findByKakaoId(oauthUser.getKakaoId());
                System.out.println("🔍 카카오 ID 조회 결과: " + (kakaoUser.isPresent() ? "발견" : "없음"));

                if (kakaoUser.isPresent()) {
                    Users existingUser = kakaoUser.get();
                    System.out.println("🔍 기존 사용자 업데이트: " + existingUser.getUsername());
                    existingUser.setNickname(oauthUser.getNickname());
                    existingUser.setEmail(oauthUser.getEmail()); // 이메일 업데이트

                    if (existingUser.getRole() == null) {
                        existingUser.setRole(userRole);
                    }

                    return usersRepository.save(existingUser);
                }
            }

            // 새 사용자 생성
            // 새 사용자 생성 부분을 이렇게 수정
            try {
                System.out.println("🔍 새 사용자 생성: " + oauthUser.getUsername());
                return usersRepository.save(oauthUser);
            } catch (DataIntegrityViolationException e) {
                System.out.println("⚠️ 중복 데이터로 인한 저장 실패, 다시 조회 시도");

                // 중복 에러 발생 시 다시 한 번 조회 시도
                if (oauthUser.getGoogleId() != null) {
                    Optional<Users> existingUser = usersRepository.findByGoogleId(oauthUser.getGoogleId());
                    if (existingUser.isPresent()) {
                        System.out.println("🔍 중복 에러 후 구글 ID로 기존 사용자 발견: " + existingUser.get().getUsername());
                        return existingUser.get();
                    }
                }

                if (oauthUser.getKakaoId() != null) {
                    Optional<Users> existingUser = usersRepository.findByKakaoId(oauthUser.getKakaoId());
                    if (existingUser.isPresent()) {
                        System.out.println("🔍 중복 에러 후 카카오 ID로 기존 사용자 발견: " + existingUser.get().getUsername());
                        return existingUser.get();
                    }
                }

                Optional<Users> existingUser = usersRepository.findByEmail(oauthUser.getEmail());
                if (existingUser.isPresent()) {
                    System.out.println("🔍 중복 에러 후 이메일로 기존 사용자 발견: " + existingUser.get().getUsername());
                    return existingUser.get();
                }
                throw e; // 여전히 실패하면 에러 재발생
            }

        } catch (Exception e) {
            System.err.println("❌ saveOrUpdateUser에서 예외 발생: " + e.getMessage());
            e.printStackTrace();
            throw e;
        }
    }

    // 로그아웃 기능 추가
    @Transactional
    public void logout(String accessToken) {
        try {
            // 1. 액세스 토큰에서 사용자 정보 추출
            String username = jwtAuthStrategy.getUsername(accessToken);

            // 2. 사용자 ID로 리프레시 토큰 삭제
            Users user = usersRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

            refreshTokenRepository.deleteByUserId(user.getId());

        } catch (Exception e) {
            throw new RuntimeException("로그아웃 처리 중 오류 발생", e);
        }
    }

    // 토큰 갱신 기능 추가
    @Transactional
    public TokenResponse refreshTokens(String refreshToken) {
        try {
            // 1. 리프레시 토큰 유효성 검사
            if (!jwtAuthStrategy.isValid(refreshToken)) {
                throw new RuntimeException("유효하지 않은 리프레시 토큰입니다.");
            }

            // 2. 리프레시 토큰에서 사용자 정보 추출
            String username = jwtAuthStrategy.getUsername(refreshToken);
            Users user = usersRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

            // 3. DB에서 리프레시 토큰 확인
            RefreshToken storedRefreshToken = refreshTokenRepository.findByUserId(user.getId())
                    .orElseThrow(() -> new RuntimeException("저장된 리프레시 토큰이 없습니다."));

            if (!storedRefreshToken.getRefreshToken().equals(refreshToken)) {
                throw new RuntimeException("리프레시 토큰이 일치하지 않습니다.");
            }

            // 4. 새로운 토큰들 생성
            TokenResponse newTokens = jwtAuthStrategy.generateTokens(user);

            // 5. 새로운 리프레시 토큰 저장
            storedRefreshToken.setRefreshToken(newTokens.getRefreshToken());
            refreshTokenRepository.save(storedRefreshToken);

            return newTokens;

        } catch (Exception e) {
            throw new RuntimeException("토큰 갱신 중 오류 발생", e);
        }
    }
}
