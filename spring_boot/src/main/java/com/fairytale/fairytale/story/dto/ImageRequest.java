package com.fairytale.fairytale.story.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ImageRequest {
    private Long storyId;
    private String style;        // Flutter의 'style' 필드와 일치
    private String resolution;   // Flutter의 'resolution' 필드와 일치
    private String description;  // 추가 설명 (선택사항)
}