package com.fairytale.fairytale.lullaby;

import com.fairytale.fairytale.lullaby.dto.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
@Slf4j
public class LullabyService {

    private final PythonApiService pythonApiService;

    // 테마 키워드 매핑
    private final Map<String, String> THEME_KEYWORDS = Map.of(
            "잔잔한 피아노", "piano",
            "기타 멜로디", "guitar",
            "자연의 소리", "nature",
            "달빛", "moon",
            "하늘", "sky",
            "클래식", "classical"
    );

    public LullabyService(PythonApiService pythonApiService) {
        this.pythonApiService = pythonApiService;
    }

    // ==================== 음악 검색 기능 ====================

    public List<LullabyTheme> getDefaultLullabies() {
        try {
            log.info("🔍 [LullabyService] 기본 자장가 목록 조회 시작");
            List<JamendoTrack> tracks = pythonApiService.searchMusicByTheme("lullaby");
            List<LullabyTheme> themes = tracks.stream()
                    .map(this::convertToLullabyTheme)
                    .collect(Collectors.toList());
            log.info("✅ [LullabyService] 기본 자장가 {}개 조회 완료", themes.size());
            return themes;
        } catch (Exception e) {
            log.error("❌ [LullabyService] 기본 자장가 목록 조회 중 오류: {}", e.getMessage(), e);
            return getEmergencyLullabies();
        }
    }

    public List<LullabyTheme> searchByTheme(String themeName, int limit) {
        try {
            log.info("🔍 [LullabyService] 테마별 음악 검색 시작: {}", themeName);
            String englishKeyword = THEME_KEYWORDS.getOrDefault(themeName, themeName);
            List<JamendoTrack> tracks = pythonApiService.searchMusicByTheme(englishKeyword);
            List<LullabyTheme> themes = tracks.stream()
                    .limit(limit)
                    .map(this::convertToLullabyTheme)
                    .collect(Collectors.toList());
            log.info("✅ [LullabyService] 테마 '{}' 음악 검색 완료: {}개", themeName, themes.size());
            return themes;
        } catch (Exception e) {
            log.error("❌ [LullabyService] 테마 '{}' 음악 검색 중 오류: {}", themeName, e.getMessage(), e);
            return Collections.emptyList();
        }
    }

    public List<LullabyTheme> searchByTag(String tag, int limit) {
        try {
            log.info("🔍 [LullabyService] 태그 음악 검색 시작: {}", tag);
            List<JamendoTrack> tracks = pythonApiService.searchMusicByTheme(tag);
            List<LullabyTheme> themes = tracks.stream()
                    .limit(limit)
                    .map(this::convertToLullabyTheme)
                    .collect(Collectors.toList());
            log.info("✅ [LullabyService] 태그 '{}' 음악 검색 완료: {}개", tag, themes.size());
            return themes;
        } catch (Exception e) {
            log.error("❌ [LullabyService] 태그 '{}' 음악 검색 중 오류: {}", tag, e.getMessage(), e);
            return Collections.emptyList();
        }
    }

    // ==================== 영상 검색 기능 ====================

    public List<LullabyVideoTheme> searchVideosByTheme(String themeName, int limit) {
        try {
            log.info("🔍 [LullabyService] 테마별 영상 검색 시작: {}", themeName);
            String englishKeyword = THEME_KEYWORDS.getOrDefault(themeName, themeName);
            List<YouTubeVideo> videos = pythonApiService.searchVideosByTheme(englishKeyword);
            List<LullabyVideoTheme> videoThemes = videos.stream()
                    .limit(limit)
                    .map(video -> convertToLullabyVideoTheme(video, themeName))
                    .collect(Collectors.toList());
            log.info("✅ [LullabyService] 테마 '{}' 영상 검색 완료: {}개", themeName, videoThemes.size());
            return videoThemes;
        } catch (Exception e) {
            log.error("❌ [LullabyService] 테마 '{}' 영상 검색 중 오류: {}", themeName, e.getMessage(), e);
            return getEmergencyVideos(themeName);
        }
    }

    public List<LullabyVideoTheme> getDefaultLullabyVideos() {
        try {
            log.info("🔍 [LullabyService] 기본 자장가 영상 목록 조회 시작");
            List<YouTubeVideo> videos = pythonApiService.searchVideosByTheme("lullaby");
            List<LullabyVideoTheme> videoThemes = videos.stream()
                    .map(video -> convertToLullabyVideoTheme(video, "기본 자장가"))
                    .collect(Collectors.toList());
            log.info("✅ [LullabyService] 기본 자장가 영상 {}개 조회 완료", videoThemes.size());
            return videoThemes;
        } catch (Exception e) {
            log.error("❌ [LullabyService] 기본 자장가 영상 목록 조회 중 오류: {}", e.getMessage(), e);
            return getEmergencyVideos("기본 자장가");
        }
    }

    // ==================== 공통 기능 ====================

    public List<String> getAvailableThemes() {
        return new ArrayList<>(THEME_KEYWORDS.keySet());
    }

    public boolean isPythonApiHealthy() {
        return pythonApiService.isApiHealthy();
    }

    // ==================== 변환 메서드들 ====================

    private LullabyTheme convertToLullabyTheme(JamendoTrack track) {
        try {
            return LullabyTheme.builder()
                    .title(track.getName() != null ? track.getName() : "제목 없음")
                    .duration(formatDuration(track.getDuration() != null ? track.getDuration() : 0))
                    .audioUrl(track.getAudio() != null ? track.getAudio() : "")
                    .description(buildMusicDescription(track))
                    .artist(track.getArtist_name() != null ? track.getArtist_name() : "미상")
                    .imageUrl(track.getImage() != null ? track.getImage() : "")
                    .build();
        } catch (Exception e) {
            log.error("❌ [LullabyService] 음악 트랙 변환 실패: {}", e.getMessage());
            return createEmptyLullabyTheme();
        }
    }

    private LullabyVideoTheme convertToLullabyVideoTheme(YouTubeVideo video, String theme) {
        try {
            String youtubeId = extractYouTubeId(video.getUrl());
            return LullabyVideoTheme.builder()
                    .title(video.getTitle() != null ? video.getTitle() : "제목 없음")
                    .description(buildVideoDescription(video, theme))
                    .youtubeId(youtubeId)
                    .url(video.getUrl() != null ? video.getUrl() : "")
                    .thumbnail(video.getThumbnail() != null ? video.getThumbnail() : "")
                    .theme(theme)
                    .color(getThemeColor(theme))
                    .icon(getThemeIcon(theme))
                    .build();
        } catch (Exception e) {
            log.error("❌ [LullabyService] 영상 변환 실패: {}", e.getMessage());
            return createEmptyVideoTheme(theme);
        }
    }

    // ==================== 유틸리티 메서드들 ====================

    private String extractYouTubeId(String url) {
        if (url == null || url.isEmpty()) return "";
        try {
            if (url.contains("watch?v=")) {
                return url.split("watch\\?v=")[1].split("&")[0];
            } else if (url.contains("youtu.be/")) {
                return url.split("youtu.be/")[1].split("\\?")[0];
            }
            return "";
        } catch (Exception e) {
            log.error("❌ [LullabyService] YouTube ID 추출 실패: {}", e.getMessage());
            return "";
        }
    }

    private String getThemeColor(String theme) {
        Map<String, String> themeColors = Map.of(
                "잔잔한 피아노", "0xFF6B73FF",
                "기타 멜로디", "0xFFFF6B6B",
                "자연의 소리", "0xFF4ECDC4",
                "달빛", "0xFFFFE66D",
                "하늘", "0xFF74B9FF",
                "클래식", "0xFFA29BFE"
        );
        return themeColors.getOrDefault(theme, "0xFF6B73FF");
    }

    private String getThemeIcon(String theme) {
        Map<String, String> themeIcons = Map.of(
                "잔잔한 피아노", "Icons.piano",
                "기타 멜로디", "Icons.music_note",
                "자연의 소리", "Icons.nature",
                "달빛", "Icons.nightlight",
                "하늘", "Icons.cloud",
                "클래식", "Icons.library_music"
        );
        return themeIcons.getOrDefault(theme, "Icons.music_note");
    }

    private String buildMusicDescription(JamendoTrack track) {
        if (track.getArtist_name() != null && track.getName() != null) {
            return track.getArtist_name() + "의 " + track.getName();
        } else if (track.getArtist_name() != null) {
            return track.getArtist_name() + "의 음악";
        } else {
            return "편안한 자장가";
        }
    }

    private String buildVideoDescription(YouTubeVideo video, String theme) {
        if (video.getTitle() != null && !video.getTitle().isEmpty()) {
            return theme + " 테마의 " + video.getTitle();
        } else {
            return theme + " 테마의 편안한 자장가 영상";
        }
    }

    private String formatDuration(int durationInSeconds) {
        if (durationInSeconds <= 0) return "0:00";
        int minutes = durationInSeconds / 60;
        int seconds = durationInSeconds % 60;
        return String.format("%d:%02d", minutes, seconds);
    }

    // ==================== 비상용 데이터 ====================

    private List<LullabyTheme> getEmergencyLullabies() {
        return Arrays.asList(
                createEmptyLullabyTheme(),
                LullabyTheme.builder()
                        .title("Emergency Lullaby 2")
                        .duration("4:00")
                        .audioUrl("")
                        .description("파이썬 서버 연결 실패시 임시 데이터")
                        .artist("System")
                        .imageUrl("")
                        .build()
        );
    }

    private List<LullabyVideoTheme> getEmergencyVideos(String theme) {
        return Arrays.asList(
                createEmptyVideoTheme(theme),
                LullabyVideoTheme.builder()
                        .title("Emergency Video 2")
                        .description("파이썬 서버 연결 실패시 임시 영상")
                        .youtubeId("dQw4w9WgXcQ")
                        .url("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
                        .thumbnail("")
                        .theme(theme)
                        .color(getThemeColor(theme))
                        .icon(getThemeIcon(theme))
                        .build()
        );
    }

    private LullabyTheme createEmptyLullabyTheme() {
        return LullabyTheme.builder()
                .title("연결 실패")
                .duration("0:00")
                .audioUrl("")
                .description("파이썬 서버 연결 실패시 임시 데이터")
                .artist("System")
                .imageUrl("")
                .build();
    }

    private LullabyVideoTheme createEmptyVideoTheme(String theme) {
        return LullabyVideoTheme.builder()
                .title("연결 실패")
                .description("파이썬 서버 연결 실패시 임시 영상")
                .youtubeId("dQw4w9WgXcQ")
                .url("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
                .thumbnail("")
                .theme(theme)
                .color(getThemeColor(theme))
                .icon(getThemeIcon(theme))
                .build();
    }
}
