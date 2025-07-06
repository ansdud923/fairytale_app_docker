// lib/screens/lullaby/lullaby_video_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'video_player_screen.dart';
import '../../models/lullaby_models.dart';
import '../service/api_service.dart';

class LullabyVideoScreen extends StatefulWidget {
  const LullabyVideoScreen({super.key});

  @override
  State<LullabyVideoScreen> createState() => _LullabyVideoScreenState();
}

class _LullabyVideoScreenState extends State<LullabyVideoScreen> {
  // 🎯 ApiService.baseUrl 사용 (하드코딩된 URL 제거)
  static const String searchEndpoint = '/api/lullaby/search';
  static const String recommendEndpoint = '/api/lullaby/recommend';

  // 테마 목록 추가
  final List<VideoTheme> themes = [
    VideoTheme(
      id: 'piano',
      title: '잔잔한 피아노',
      icon: Icons.piano,
      color: const Color(0xFF6B73FF),
      searchKeywords: [
        'piano',
        'piano lullaby',
        'relaxing piano',
        'sleep piano music',
      ],
    ),
    VideoTheme(
      id: 'guitar',
      title: '기타',
      icon: Icons.audiotrack,
      color: const Color(0xFF8D6E63),
      searchKeywords: ['guitar', 'guitar lullaby', 'guitar lullaby sleep'],
    ),
    VideoTheme(
      id: 'nature',
      title: '자연',
      icon: Icons.eco,
      color: const Color(0xFF27AE60),
      searchKeywords: [
        'nature',
        'nature sounds sleep',
        'rain sounds',
        'ocean waves',
      ],
    ),
    VideoTheme(
      id: 'moon',
      title: '달빛',
      icon: Icons.nightlight_round,
      color: const Color(0xFF34495E),
      searchKeywords: ['moon', 'moon sleep', 'moon lullaby'],
    ),
    VideoTheme(
      id: 'sky',
      title: '하늘',
      icon: Icons.cloud,
      color: const Color(0xFF5DADE2),
      searchKeywords: ['sky', 'sky music', 'sky sleep', 'sky lullaby'],
    ),
    VideoTheme(
      id: 'classical',
      title: '클래식',
      icon: Icons.library_music,
      color: const Color(0xFFE74C3C),
      searchKeywords: [
        'classical',
        'classical lullaby',
        'mozart sleep',
        'brahms lullaby',
      ],
    ),
  ];

  // 상태 변수
  VideoTheme? _selectedTheme;
  List<LullabyVideoTheme> _videoThemes = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // 사용자 선호도 저장 (로컬 상태)
  Map<String, int> _userPreferences = {};

  @override
  void initState() {
    super.initState();
    // 초기 로드 시에는 테마 선택을 기다림
  }

  // 테마 선택 처리
  void _selectTheme(VideoTheme theme) {
    setState(() {
      _selectedTheme = theme;
      _videoThemes.clear();
      _errorMessage = '';
    });
    _searchVideos();
  }

  // YouTube 검색 (Spring Boot → FastAPI)
  Future<void> _searchVideos() async {
    if (_selectedTheme == null) return;

    final selectedTheme = _selectedTheme!; // null이 아님을 보장하는 로컬 변수

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // 🎯 ApiService.baseUrl 사용 (플랫폼 자동 감지)
      final baseUrl = ApiService.baseUrl;
      print('🔍 영상 검색 - 플랫폼: ${Platform.operatingSystem}');
      print('🔍 영상 검색 - 서버 URL: $baseUrl');

      final response = await http
          .post(
        Uri.parse('$baseUrl$searchEndpoint'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'themeId': selectedTheme.id,
          'themeName': selectedTheme.title,
          'searchKeywords': selectedTheme.searchKeywords,
          'filters': {
            'maxResults': 20,
            'videoDuration': 'long',
            'order': 'relevance',
          },
          'userId': 'user123',
        }),
      )
          .timeout(const Duration(seconds: 15));

      print('🔍 영상 검색 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);

        setState(() {
          _videoThemes =
              (data['videos'] as List)
                  .map(
                    (item) => LullabyVideoTheme.fromYouTubeSearch(
                  item,
                  selectedTheme,
                ),
              )
                  .toList();
          _isLoading = false;
        });

        print('✅ ${_videoThemes.length}개 영상 로드 성공');

        // 사용자 맞춤 추천 받기
        _getRecommendations();
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 영상 검색 실패: $e');
      setState(() {
        _errorMessage = '비디오 목록을 불러올 수 없습니다: $e';
        _isLoading = false;
      });
    }
  }

  // AI 기반 추천 받기
  Future<void> _getRecommendations() async {
    if (_videoThemes.isEmpty) return;

    try {
      // 🎯 ApiService.baseUrl 사용
      final baseUrl = ApiService.baseUrl;

      final response = await http.post(
        Uri.parse('$baseUrl$recommendEndpoint'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'userId': 'user123',
          'themeId': _selectedTheme?.id,
          'videoIds': _videoThemes.map((v) => v.id).toList(),
          'preferences': _userPreferences,
          'timeOfDay': DateTime.now().hour,
          'recentlyPlayed': _getRecentlyPlayedIds(),
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final recommendations = jsonDecode(responseBody);

        // 추천 순서대로 비디오 정렬
        if (recommendations['recommendedOrder'] != null) {
          _sortVideosByRecommendation(recommendations['recommendedOrder']);
        }
      }
    } catch (e) {
      print('추천 받기 실패: $e');
    }
  }

  // 최근 재생한 비디오 ID 가져오기
  List<String> _getRecentlyPlayedIds() {
    // 실제로는 SharedPreferences나 로컬 DB에서 가져와야 함
    return [];
  }

  // 추천 순서대로 정렬
  void _sortVideosByRecommendation(List<dynamic> recommendedIds) {
    setState(() {
      _videoThemes.sort((a, b) {
        final aIndex = recommendedIds.indexOf(a.id);
        final bIndex = recommendedIds.indexOf(b.id);
        if (aIndex == -1) return 1;
        if (bIndex == -1) return -1;
        return aIndex.compareTo(bIndex);
      });
    });
  }

  // 비디오 재생 및 통계 전송
  Future<void> _playVideo(LullabyVideoTheme theme) async {
    // 재생 통계 Spring Boot로 전송
    _sendPlayStatistics(theme);

    // 사용자 선호도 업데이트
    setState(() {
      _userPreferences[theme.id] = (_userPreferences[theme.id] ?? 0) + 1;
    });

    // 비디오 플레이어 화면으로 이동
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VideoPlayerScreen(theme: theme)),
    );

    // 재생 완료 후 피드백 처리
    if (result != null && result is Map<String, dynamic>) {
      _sendFeedback(theme.id, result);
    }
  }

  // 재생 통계 전송
  Future<void> _sendPlayStatistics(LullabyVideoTheme theme) async {
    try {
      // 🎯 ApiService.baseUrl 사용
      final baseUrl = ApiService.baseUrl;

      await http.post(
        Uri.parse('$baseUrl/api/lullaby/play-stats'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'videoId': theme.id,
          'themeId': _selectedTheme?.id,
          'userId': 'user123',
          'timestamp': DateTime.now().toIso8601String(),
          'deviceInfo': {'platform': 'flutter', 'version': '1.0.0'},
        }),
      );
    } catch (e) {
      print('통계 전송 실패: $e');
    }
  }

  // 사용자 피드백 전송
  Future<void> _sendFeedback(
      String videoId,
      Map<String, dynamic> feedback,
      ) async {
    try {
      // 🎯 ApiService.baseUrl 사용
      final baseUrl = ApiService.baseUrl;

      await http.post(
        Uri.parse('$baseUrl/api/lullaby/feedback'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'videoId': videoId,
          'userId': 'user123',
          'feedback': feedback,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      print('피드백 전송 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_sleep_main.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar 영역
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      '자장가 영상',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // 새로고침 버튼
                    if (_selectedTheme != null && _videoThemes.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _searchVideos,
                      ),
                  ],
                ),
              ),

              // 테마 선택 영역 추가
              Container(
                height: 100,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: themes.length,
                  itemBuilder: (context, index) {
                    final theme = themes[index];
                    final isSelected = _selectedTheme?.id == theme.id;

                    return GestureDetector(
                      onTap: () => _selectTheme(theme),
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors:
                            isSelected
                                ? [
                              theme.color,
                              theme.color.withOpacity(0.7),
                            ]
                                : [
                              theme.color.withOpacity(0.3),
                              theme.color.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                            isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(theme.icon, color: Colors.white, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              theme.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 메인 컨텐츠
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedTheme == null) ...[
                        const Text(
                          '테마를 선택해주세요',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'AI가 선택한 테마에 맞는 최적의 자장가 영상을 찾아드립니다',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ] else ...[
                        Text(
                          '${_selectedTheme!.title} 자장가',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '시각적 효과와 함께 더욱 깊은 휴식을 경험하세요',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // 로딩, 에러, 컨텐츠 표시
                      Expanded(
                        child:
                        _selectedTheme == null
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.touch_app,
                                color: Colors.white.withOpacity(0.5),
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '원하는 테마를 선택하세요',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                            : _isLoading
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: _selectedTheme!.color,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'AI가 최적의 영상을 찾고 있습니다...',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                            : _errorMessage.isNotEmpty
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.white.withOpacity(0.7),
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _searchVideos,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  _selectedTheme!.color,
                                ),
                                child: const Text('다시 시도'),
                              ),
                            ],
                          ),
                        )
                            : ListView.builder(
                          itemCount: _videoThemes.length,
                          itemBuilder: (context, index) {
                            final theme = _videoThemes[index];
                            return _buildVideoCard(theme, index < 3);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard(LullabyVideoTheme theme, bool isRecommended) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
          isRecommended
              ? theme.color.withOpacity(0.6)
              : Colors.white.withOpacity(0.2),
          width: isRecommended ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 추천 배지
          if (isRecommended)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'AI 추천',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Column(
            children: [
              // 썸네일 영역 - YouTube 썸네일 표시로 변경
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  children: [
                    // YouTube 썸네일 이미지
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            theme.thumbnail,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _selectedTheme?.color.withOpacity(0.8) ??
                                          theme.color.withOpacity(0.8),
                                      _selectedTheme?.color.withOpacity(0.4) ??
                                          theme.color.withOpacity(0.4),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    theme.icon,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                          // 어두운 오버레이
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 재생 버튼
                    Center(
                      child: GestureDetector(
                        onTap: () => _playVideo(theme),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: theme.color,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                    // 시간 표시
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          theme.duration,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 정보 영역
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.color.withOpacity(0.8),
                            theme.color.withOpacity(0.4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(theme.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            theme.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            theme.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_userPreferences[theme.id] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${_userPreferences[theme.id]}회 재생됨',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _playVideo(theme),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: theme.color,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}