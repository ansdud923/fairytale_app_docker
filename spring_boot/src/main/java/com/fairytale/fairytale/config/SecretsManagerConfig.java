package com.fairytale.fairytale.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import software.amazon.awssdk.services.secretsmanager.SecretsManagerClient;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueRequest;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueResponse;
import software.amazon.awssdk.regions.Region;

import jakarta.annotation.PostConstruct;
import java.util.Map;

@Configuration
@Order(1)
public class SecretsManagerConfig {

    @Value("${AWS_SECRET_NAME:fairytale-secrets}")
    private String secretName;

    @Value("${AWS_REGION:ap-northeast-2}")
    private String region;

    @Value("${ENVIRONMENT:production}")
    private String environment;

    @PostConstruct
    public void loadSecrets() {
        if ("production".equals(environment)) {
            try {
                System.out.println("🔐 Secrets Manager에서 설정 로드 중...");

                // Secrets Manager 클라이언트 생성
                SecretsManagerClient client = SecretsManagerClient.builder()
                        .region(Region.of(region))
                        .build();

                // Secret 값 요청
                GetSecretValueRequest request = GetSecretValueRequest.builder()
                        .secretId(secretName)
                        .build();

                GetSecretValueResponse response = client.getSecretValue(request);
                String secretString = response.secretString();

                // JSON 파싱
                ObjectMapper mapper = new ObjectMapper();
                Map<String, Object> secrets = mapper.readValue(secretString, Map.class);

                // 시스템 프로퍼티로 설정
                secrets.forEach((key, value) -> {
                    if (value != null) {
                        System.setProperty(key, value.toString());

                        // 민감한 정보는 마스킹해서 로그 출력
                        String logValue = (key.toLowerCase().contains("password") ||
                                key.toLowerCase().contains("secret") ||
                                key.toLowerCase().contains("key"))
                                ? "****" : value.toString();
                        System.out.println("✅ " + key + " = " + logValue);
                    }
                });

                System.out.println("🎉 Secrets Manager에서 " + secrets.size() + "개 설정 로드 완료!");

            } catch (Exception e) {
                System.err.println("❌ Secrets Manager 로드 실패: " + e.getMessage());
                e.printStackTrace();
                throw new RuntimeException("Secrets Manager 연결 실패", e);
            }
        } else {
            System.out.println("💻 개발 환경: .env 파일 사용");
        }
    }
}