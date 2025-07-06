package com.fairytale.fairytale.config;

import com.fairytale.fairytale.auth.strategy.JwtAuthStrategy;
import com.fairytale.fairytale.auth.strategy.JwtAuthenticationFilter;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Slf4j
@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthStrategy jwtAuthStrategy;

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        SecurityConfig.log.info("🔍 [SecurityConfig] AuthenticationManager 빈 생성됨!");
        return config.getAuthenticationManager();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        SecurityConfig.log.info("🔍 [SecurityConfig] SecurityFilterChain 빈 생성 시작!");
        SecurityConfig.log.info("🔍 [SecurityConfig] jwtAuthStrategy: " + jwtAuthStrategy);

        SecurityFilterChain result = http
                // ⭐ CSRF 완전 비활성화
                .csrf(AbstractHttpConfigurer::disable)

                // ⭐ CORS 허용
                .cors(AbstractHttpConfigurer::disable)

                // ⭐ 세션 비활성화 (JWT 사용)
                .sessionManagement(sess -> sess.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

                // ⭐ 경로별 권한 설정 (중요!)
                .authorizeHttpRequests(auth -> auth
                        // OAuth 관련 경로는 모두 허용
                        .requestMatchers("/oauth/**").permitAll()
                        .requestMatchers("/api/auth/**").permitAll()

                        // 🎯 색칠공부 API 임시 전체 허용 (임시 해결)
                        .requestMatchers("/api/coloring/**").authenticated()

                        // 업로드 관련 경로
                        .requestMatchers("/api/upload/**").authenticated()

                        // 사용자 관련 경로
                        .requestMatchers(HttpMethod.PUT, "/api/user/profile-image").authenticated()
                        .requestMatchers(HttpMethod.GET, "/api/user/**").authenticated()
                        .requestMatchers("/api/user/health").permitAll()

                        // 갤러리 API
                        .requestMatchers("/api/gallery/**").authenticated()

                        // 정적 리소스 경로 허용
                        .requestMatchers("coloring/**").permitAll()

                        // 자장가 허용
                        .requestMatchers("/api/lullaby/**").permitAll()

                        // FastAPI 경로 허용
                        .requestMatchers("/api/fairytale/**").authenticated()

                        // 헬스체크 및 관리 경로
                        .requestMatchers("/health", "/actuator/**", "/h2-console/**").permitAll()

                        // 나머지는 인증 필요
                        .anyRequest().authenticated()
                )

                // ⭐ JWT 필터 추가
                .addFilterBefore(new JwtAuthenticationFilter(jwtAuthStrategy), UsernamePasswordAuthenticationFilter.class)

                .build();

        SecurityConfig.log.info("🔍 [SecurityConfig] SecurityFilterChain 빈 생성 완료!");
        return result;
    }
}