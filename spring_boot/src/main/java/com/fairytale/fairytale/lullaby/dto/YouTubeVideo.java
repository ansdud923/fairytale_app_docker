package com.fairytale.fairytale.lullaby.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class YouTubeVideo {
    private String title;      // 영상 제목
    private String url;        // YouTube URL
    private String thumbnail;  // 썸네일 이미지 URL

    @Override
    public String toString() {
        return "YouTubeVideo{" +
                "title='" + title + '\'' +
                ", url='" + url + '\'' +
                ", thumbnail='" + thumbnail + '\'' +
                '}';
    }
}