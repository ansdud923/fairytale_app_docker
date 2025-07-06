package com.fairytale.fairytale.lullaby.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class LullabyVideoTheme {
    private String title;       // 영상 제목
    private String description; // 영상 설명
    private String youtubeId;   // YouTube 영상 ID
    private String url;         // YouTube URL
    private String thumbnail;   // 썸네일 이미지 URL
    private String theme;       // 테마명
    private String color;       // 테마 색상 (Flutter Color 형식)
    private String icon;        // 테마 아이콘 (Flutter IconData 형식)
}