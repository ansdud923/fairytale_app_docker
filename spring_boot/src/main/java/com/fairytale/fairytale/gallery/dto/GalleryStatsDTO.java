package com.fairytale.fairytale.gallery.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GalleryStatsDTO {
    private long totalImages;        // 총 이미지 개수
    private long coloringImages;     // 색칠한 이미지 개수
    private long totalStories;       // 총 스토리 개수
    private double completionRate;   // 완성률 (색칠한 이미지 / 총 이미지 * 100)
}