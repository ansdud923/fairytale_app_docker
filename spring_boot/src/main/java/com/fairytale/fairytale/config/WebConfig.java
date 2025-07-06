package com.fairytale.fairytale.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 🎯 /coloring/** 경로로 접근하면 static/coloring/ 폴더의 파일 제공
        registry.addResourceHandler("/coloring/**")
                .addResourceLocations("classpath:/static/coloring/");

        System.out.println("✅ [WebConfig] 정적 리소스 핸들러 등록: /coloring/**");
    }
}