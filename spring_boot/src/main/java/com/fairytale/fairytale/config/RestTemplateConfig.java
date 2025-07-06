package com.fairytale.fairytale.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestTemplate;

@Configuration
public class RestTemplateConfig {
    @Bean
    public RestTemplate restTemplate() {
        RestTemplate restTemplate = new RestTemplate();

        // 기본 JDK의 SimpleClientHttpRequestFactory 사용 (스프링부트 3.x 호환)
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();

        // 타임아웃 설정
        factory.setConnectTimeout(10000);     // 연결 타임아웃
        factory.setReadTimeout(900000);       // 읽기 타임아웃

        restTemplate.setRequestFactory(factory);

        return restTemplate;
    }
}
