package com.fairytale.fairytale.story.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class FastApiVoiceRequest {
    private String text;  // FastAPI가 기대하는 필드명
    private String voice;
    private double speed;
}