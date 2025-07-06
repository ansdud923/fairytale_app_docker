package com.fairytale.fairytale.lullaby.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CombinedLullabyContent {
    private List<LullabyTheme> music;          // 음악 목록
    private List<LullabyVideoTheme> videos;    // 영상 목록
    private String theme;                      // 검색 테마
    private int totalCount;                    // 전체 컨텐츠 수
}