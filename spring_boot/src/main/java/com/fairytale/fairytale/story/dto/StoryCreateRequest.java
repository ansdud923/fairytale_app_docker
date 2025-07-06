package com.fairytale.fairytale.story.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class StoryCreateRequest {
    private String theme;
    private String voice;
    private String imageMode;
    private String name;
    private String voiceSpeed;
    private Long babyId;  // 아기 ID 추가 (선택사항)
}
