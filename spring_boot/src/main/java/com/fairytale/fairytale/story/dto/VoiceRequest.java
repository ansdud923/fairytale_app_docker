package com.fairytale.fairytale.story.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class VoiceRequest {
    private Long storyId;
    private String text;
    private String voice;
    // 🎯 속도 필드 추가!
    private Double speed;
}
