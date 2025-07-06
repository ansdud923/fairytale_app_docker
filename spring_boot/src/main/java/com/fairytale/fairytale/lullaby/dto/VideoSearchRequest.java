package com.fairytale.fairytale.lullaby.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;
import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class VideoSearchRequest {
    private String themeId;                    // 테마 ID (예: "piano", "nature")
    private String themeName;                  // 테마 이름 (예: "피아노", "자연")
    private List<String> searchKeywords;       // 검색 키워드 리스트
    private Map<String, Object> filters;       // 필터 옵션 (maxResults, videoDuration 등)
    private String userId;                     // 사용자 ID
}