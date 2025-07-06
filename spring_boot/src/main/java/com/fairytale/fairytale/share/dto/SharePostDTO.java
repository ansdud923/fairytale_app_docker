// src/main/java/com/fairytale/fairytale/share/dto/SharePostDTO.java
package com.fairytale.fairytale.share.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SharePostDTO {
    private Long id;
    private String userName;        // "아이이름의 부모" 형식
    private String storyTitle;
    private String videoUrl;        // Stories에서만 사용
    private String imageUrl;        // Gallery에서 사용
    private String thumbnailUrl;
    private String sourceType;      // "STORY" 또는 "GALLERY"
    private Integer likeCount;      // 좋아요 수
    private Boolean isLiked;        // 현재 사용자가 좋아요했는지
    private Boolean isOwner;        // 현재 사용자가 작성자인지
    private LocalDateTime createdAt;
    private int commentCount; // 🎯 이 필드 추가

}