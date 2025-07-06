package com.fairytale.fairytale.story.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class FastApiImageRequest {
    private String mode;  // FastAPI가 기대하는 필드명
    private String text;  // FastAPI가 기대하는 필드명
}