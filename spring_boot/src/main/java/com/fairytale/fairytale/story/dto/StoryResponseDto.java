package com.fairytale.fairytale.story.dto;

import com.fairytale.fairytale.story.Story;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
public class StoryResponseDto {
    private Long id;
    private String title;
    private String content;
    private String theme;
    private String image;
    private String voice;
    private LocalDateTime createdAt;

    // Story 엔티티에서 DTO로 변환하는 생성자
    public StoryResponseDto(Story story) {
        this.id = story.getId();
        this.title = story.getTitle();
        this.content = story.getContent();
        this.theme = story.getTheme();
        this.image = story.getImage();
        this.voice = story.getVoice();
        this.createdAt = story.getCreatedAt();
    }
}