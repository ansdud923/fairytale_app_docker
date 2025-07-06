// lib/models/lullaby_models.dart
import 'package:flutter/material.dart';

// VideoTheme 클래스를 먼저 정의
class VideoTheme {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final List<String> searchKeywords;

  VideoTheme({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.searchKeywords,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'searchKeywords': searchKeywords};
  }
}

class LullabyVideoTheme {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String youtubeId;
  final String description;
  final String duration;
  final String thumbnail;
  final String? channelTitle;
  final String? viewCount;
  final String? publishedAt;
  final Map<String, dynamic>? metadata;

  LullabyVideoTheme({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.youtubeId,
    required this.description,
    required this.duration,
    required this.thumbnail,
    this.channelTitle,
    this.viewCount,
    this.publishedAt,
    this.metadata,
  });

  // 기존 JSON 변환 (Spring Boot에서 저장된 데이터용)
  factory LullabyVideoTheme.fromJson(Map<String, dynamic> json) {
    return LullabyVideoTheme(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      icon: _getIconFromString(json['icon'] ?? 'music_note'),
      color: Color(int.parse(json['color'] ?? '0xFF6B73FF', radix: 16)),
      youtubeId: json['youtubeId'] ?? '',
      description: json['description'] ?? '',
      duration: json['duration'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      channelTitle: json['channelTitle'],
      viewCount: json['viewCount'],
      publishedAt: json['publishedAt'],
      metadata: json['metadata'],
    );
  }

  // YouTube 검색 결과에서 변환 (FastAPI 응답용) - 이 메서드를 추가!
  factory LullabyVideoTheme.fromYouTubeSearch(
    Map<String, dynamic> json,
    VideoTheme theme,
  ) {
    // YouTube 영상 ID 추출
    String videoId = '';
    if (json['id'] != null) {
      if (json['id'] is Map && json['id']['videoId'] != null) {
        videoId = json['id']['videoId'];
      } else if (json['id'] is String) {
        videoId = json['id'];
      }
    }

    // null 안전성 강화
    final snippet = json['snippet'] ?? {};
    final contentDetails = json['contentDetails'] ?? {};
    final statistics = json['statistics'] ?? {};

    // 썸네일 URL 구성
    String thumbnailUrl = '';
    if (json['snippet'] != null && json['snippet']['thumbnails'] != null) {
      final thumbnails = json['snippet']['thumbnails'];
      thumbnailUrl =
          thumbnails['high']?['url'] ??
          thumbnails['medium']?['url'] ??
          thumbnails['default']?['url'] ??
          '';
    } else if (videoId.isNotEmpty) {
      thumbnailUrl = 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
    }

    // 제목과 설명 추출
    String title = json['snippet']?['title'] ?? '제목 없음';
    String description = json['snippet']?['description'] ?? '';
    String channelTitle = json['snippet']?['channelTitle'] ?? '';

    // 영상 길이 포맷팅
    String duration = _formatDuration(json['contentDetails']?['duration']);

    // 조회수 포맷팅
    String viewCount = '';
    if (json['statistics'] != null && json['statistics']['viewCount'] != null) {
      viewCount = _formatViewCount(json['statistics']['viewCount']);
    }

    // 발행일 포맷팅
    String publishedAt = '';
    if (json['snippet']?['publishedAt'] != null) {
      publishedAt = _formatPublishedAt(json['snippet']['publishedAt']);
    }

    return LullabyVideoTheme(
      id: videoId,
      title: title,
      icon: theme.icon,
      color: theme.color,
      youtubeId: videoId,
      description: description.isEmpty ? channelTitle : description,
      duration: duration,
      thumbnail: thumbnailUrl,
      channelTitle: channelTitle,
      viewCount: viewCount,
      publishedAt: publishedAt,
      metadata: {'themeId': theme.id, 'themeName': theme.title},
    );
  }

  // 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'icon': _getStringFromIcon(icon),
      'color': '0x${color.value.toRadixString(16).toUpperCase()}',
      'youtubeId': youtubeId,
      'description': description,
      'duration': duration,
      'thumbnail': thumbnail,
      'channelTitle': channelTitle,
      'viewCount': viewCount,
      'publishedAt': publishedAt,
      'metadata': metadata,
    };
  }

  // YouTube duration (ISO 8601) 포맷 변환
  static String _formatDuration(dynamic duration) {
    if (duration == null) return '시간 정보 없음';

    if (duration is String && duration.startsWith('PT')) {
      try {
        final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
        final match = regex.firstMatch(duration);

        if (match != null) {
          final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
          final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
          final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;

          if (hours > 0) {
            return '${hours}시간 ${minutes}분';
          } else if (minutes > 0) {
            return '${minutes}분';
          } else {
            return '${seconds}초';
          }
        }
      } catch (e) {
        return '시간 정보 없음';
      }
    }

    return duration.toString();
  }

  // 조회수 포맷팅
  static String _formatViewCount(dynamic count) {
    if (count == null) return '';

    int viewCount = 0;
    if (count is String) {
      viewCount = int.tryParse(count) ?? 0;
    } else if (count is int) {
      viewCount = count;
    }

    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M 조회';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}K 조회';
    }
    return '$viewCount 조회';
  }

  // 발행일 포맷팅
  static String _formatPublishedAt(String? dateString) {
    if (dateString == null) return '';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()}년 전';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()}개월 전';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}일 전';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}시간 전';
      } else {
        return '방금 전';
      }
    } catch (e) {
      return '';
    }
  }

  // 문자열을 IconData로 변환
  static IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'piano':
        return Icons.piano;
      case 'music_note':
        return Icons.music_note;
      case 'eco':
        return Icons.eco;
      case 'library_music':
        return Icons.library_music;
      case 'blur_on':
        return Icons.blur_on;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'child_care':
        return Icons.child_care;
      default:
        return Icons.music_note;
    }
  }

  // IconData를 문자열로 변환
  static String _getStringFromIcon(IconData icon) {
    if (icon == Icons.piano) return 'piano';
    if (icon == Icons.music_note) return 'music_note';
    if (icon == Icons.eco) return 'eco';
    if (icon == Icons.library_music) return 'library_music';
    if (icon == Icons.blur_on) return 'blur_on';
    if (icon == Icons.self_improvement) return 'self_improvement';
    if (icon == Icons.child_care) return 'child_care';
    return 'music_note';
  }
}
