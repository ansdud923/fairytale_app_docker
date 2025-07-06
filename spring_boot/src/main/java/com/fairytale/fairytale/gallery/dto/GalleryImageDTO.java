package com.fairytale.fairytale.gallery.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GalleryImageDTO {
    private Long storyId;
    private String storyTitle;
    private String colorImageUrl;      // 컬러 이미지 URL (Story 테이블에서)
    private String coloringImageUrl;   // 색칠한 이미지 URL (Gallery 테이블에서)
    private LocalDateTime createdAt;

    @Builder.Default
    private boolean isColoringWork = false; // 색칠 완성작 여부 (기존 필드 유지)

    // 🎯 새로 추가된 필드들 (기존 구조 유지하면서 추가)
    private String type;               // "story" 또는 "coloring"
    private Long coloringWorkId;       // 색칠 완성작인 경우의 실제 ColoringWork ID
    private Boolean isOwner;           // 소유자 여부 (선택사항)
}