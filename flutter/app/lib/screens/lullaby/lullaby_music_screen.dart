// lib/screens/lullaby/lullaby_music_screen.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../service/api_service.dart';

class LullabyMusicScreen extends StatefulWidget {
  const LullabyMusicScreen({super.key});

  @override
  State<LullabyMusicScreen> createState() => _LullabyMusicScreenState();
}

class _LullabyMusicScreenState extends State<LullabyMusicScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _currentPlayingTheme;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  int _selectedThemeIndex = 0;

  List<LullabyTheme> _themes = [];

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
    _loadThemesFromSpringBoot();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _position = position;
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _currentPlayingTheme = null;
        _position = Duration.zero;
      });
    });
  }

  /**
   * 스프링부트 서버에서 자장가 테마 목록을 가져오는 함수
   *
   * 왜 스프링부트를 거치는가?
   * - 파이썬 FastAPI에 직접 접근하지 않고 스프링부트를 경유
   * - 스프링부트에서 데이터 가공, 에러 처리, 로깅 등 담당
   * - 일관된 API 응답 형식 제공
   * - 보안 및 접근 제어 가능
   */
  /**
   * 개선된 테마 로드 (에러 처리 강화)
   */
// 🎯 _loadThemesFromSpringBoot 메서드 완전 수정
  Future<void> _loadThemesFromSpringBoot() async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('🔍 자장가 테마 로드 시작');

      // 🎯 ApiService의 baseUrl 사용 (플랫폼 자동 감지)
      final serverUrl = ApiService.baseUrl;
      print('🔍 플랫폼: ${Platform.operatingSystem}');
      print('🔍 서버 URL: $serverUrl');

      final response = await http.get(
        Uri.parse('$serverUrl/api/lullaby/themes'),
        headers: await _getAuthHeaders(), // 인증 헤더 추가
      ).timeout(Duration(seconds: 15)); // 타임아웃 15초로 연장

      print('🔍 테마 로드 응답: ${response.statusCode}');
      print('🔍 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final List<dynamic> themesData = jsonData['data'];

          setState(() {
            _themes = themesData.map((json) => LullabyTheme.fromJson(json)).toList();
            _isLoading = false;
          });

          print('✅ ${_themes.length}개 테마 로드 성공');

          if (_themes.isEmpty) {
            _showEmptyThemesDialog();
          }
        } else {
          print('❌ API 응답 형식 오류: ${jsonData['message']}');
          _loadFallbackThemes();
        }
      } else if (response.statusCode == 404) {
        print('❌ API 엔드포인트를 찾을 수 없음 (404)');
        _showApiNotImplementedDialog();
      } else if (response.statusCode == 500) {
        print('❌ 서버 내부 오류 (500)');
        _showServerErrorDialog();
      } else {
        print('❌ 서버 오류: ${response.statusCode}');
        _loadFallbackThemes();
      }
    } on TimeoutException catch (e) {
      print('❌ 요청 타임아웃: $e');
      _showTimeoutDialog();
    } on SocketException catch (e) {
      print('❌ 네트워크 연결 실패: $e');
      _showNetworkErrorDialog();
    } catch (e) {
      print('❌ 테마 로드 실패: $e');
      _loadFallbackThemes();
    }
  }

// 🎯 인증 헤더 가져오기 메서드 추가
  Future<Map<String, String>> _getAuthHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      return {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };
    } catch (e) {
      return {'Content-Type': 'application/json'};
    }
  }

// 🎯 API 미구현 안내 다이얼로그
  void _showApiNotImplementedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.construction, color: Colors.orange),
            SizedBox(width: 8),
            Text('기능 개발 중'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('자장가 기능이 아직 개발 중입니다.'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🎵 곧 추가될 기능:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('• 다양한 자장가 음원'),
                  Text('• 테마별 음악 검색'),
                  Text('• 수면 타이머 기능'),
                  Text('• 사용자 맞춤 플레이리스트'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadFallbackThemes();
            },
            child: Text('샘플 음악 듣기'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

// 🎯 서버 내부 오류 다이얼로그
  void _showServerErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('서버 오류'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('자장가 서비스에 일시적인 문제가 발생했습니다.'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.refresh, color: Colors.orange[700]),
                  SizedBox(height: 8),
                  Text(
                    '잠시 후 다시 시도해주세요',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadFallbackThemes();
            },
            child: Text('오프라인 모드'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadThemesFromSpringBoot();
            },
            child: Text('다시 시도'),
          ),
        ],
      ),
    );
  }

// 🎯 네트워크 연결 오류 다이얼로그
  void _showNetworkErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.grey),
            SizedBox(width: 8),
            Text('네트워크 오류'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.signal_wifi_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('네트워크 연결을 확인해주세요.'),
            SizedBox(height: 12),
            Text(
              '• Wi-Fi 또는 모바일 데이터 연결 확인\n• 네트워크 설정 재설정\n• 잠시 후 다시 시도',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadFallbackThemes();
            },
            child: Text('오프라인 모드'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadThemesFromSpringBoot();
            },
            child: Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  /**
   * API 엔드포인트 없음 안내
   */
  void _showApiNotFoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('API 준비 중'),
        content: Text('자장가 기능이 아직 준비되지 않았습니다.\n곧 업데이트 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadFallbackThemes();
            },
            child: Text('오프라인 모드로'),
          ),
        ],
      ),
    );
  }

  /**
   * 타임아웃 안내
   */
  void _showTimeoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('연결 시간 초과'),
        content: Text('서버 응답이 너무 늦습니다.\n네트워크 상태를 확인해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadThemesFromSpringBoot();
            },
            child: Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  /**
   * 빈 테마 목록 안내
   */
  void _showEmptyThemesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('자장가 준비 중'),
        content: Text('아직 이용 가능한 자장가가 없습니다.\n잠시 후 다시 시도해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  /**
   * 특정 테마로 음악 검색
   * 스프링부트 API를 통해 파이썬 FastAPI 호출
   */
  Future<void> _searchByTheme(String themeName) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // URL 인코딩 (한국어 테마명 처리)
      final encodedThemeName = Uri.encodeComponent(themeName);

      // 🎯 ApiService.baseUrl 사용
      final serverUrl = ApiService.baseUrl;

      final response = await http.get(
        Uri.parse(
          '$serverUrl/api/lullaby/theme/$encodedThemeName?limit=5',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final List<dynamic> themesData = jsonData['data'];

          setState(() {
            _themes =
                themesData.map((json) => LullabyTheme.fromJson(json)).toList();
            _selectedThemeIndex = 0; // 첫 번째 곡으로 선택
            _isLoading = false;
          });

          print('$themeName 테마로 ${_themes.length}개 곡을 찾았습니다.');
          print('메시지: ${jsonData['message']}');
        }
      }
    } catch (e) {
      print('테마 검색 중 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

// 🎯 개선된 폴백 테마 (더 많은 샘플 음악)
  void _loadFallbackThemes() {
    setState(() {
      _themes = [
        LullabyTheme(
          title: '🎹 브람스 자장가',
          duration: '3:45',
          audioUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav', // 샘플 URL
          description: '클래식 피아노 자장가',
          artist: '브람스',
          imageUrl: '',
        ),
        LullabyTheme(
          title: '🌊 바다 소리',
          duration: '10:00',
          audioUrl: '', // 실제 음원이 없으면 빈 값
          description: '잔잔한 파도 소리',
          artist: 'Nature Sounds',
          imageUrl: '',
        ),
        LullabyTheme(
          title: '🌙 달빛 소나타',
          duration: '5:30',
          audioUrl: '',
          description: '베토벤의 달빛 소나타',
          artist: '베토벤',
          imageUrl: '',
        ),
        LullabyTheme(
          title: '🎵 오르골 멜로디',
          duration: '4:15',
          audioUrl: '',
          description: '부드러운 오르골 소리',
          artist: 'Music Box',
          imageUrl: '',
        ),
        LullabyTheme(
          title: '🌲 숲 속의 소리',
          duration: '8:20',
          audioUrl: '',
          description: '새소리와 바람소리',
          artist: 'Forest Sounds',
          imageUrl: '',
        ),
      ];
      _isLoading = false;
    });

    // 오프라인 모드 안내
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.offline_bolt, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text('오프라인 모드로 전환되었습니다. 일부 기능이 제한될 수 있습니다.')),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: '재시도',
          textColor: Colors.white,
          onPressed: _loadThemesFromSpringBoot,
        ),
      ),
    );
  }

  /**
   * 개선된 서버 상태 확인 및 폴백 처리
   */
  Future<void> _checkServerHealth() async {
    try {
      print('🔍 서버 상태 확인 시작');

      // 🎯 ApiService.baseUrl 사용
      final serverUrl = ApiService.baseUrl;
      print('🔍 사용할 서버 URL: $serverUrl');

      // 스프링부트 서버 상태 확인 (타임아웃 5초)
      final springResponse = await http.get(
        Uri.parse('$serverUrl/api/lullaby/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));

      print('🔍 스프링부트 서버 응답: ${springResponse.statusCode}');

      if (springResponse.statusCode == 200) {
        // 파이썬 서버 상태 확인 (타임아웃 3초)
        try {
          final pythonResponse = await http.get(
            Uri.parse('$serverUrl/api/lullaby/python-health'),
            headers: {'Content-Type': 'application/json'},
          ).timeout(Duration(seconds: 3));

          print('🔍 파이썬 서버 응답: ${pythonResponse.statusCode}');

          if (pythonResponse.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('모든 서버가 정상 작동 중입니다!'),
                  ],
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            _showServerIssueDialog('파이썬 서버 연결 실패', 'Jamendo API 서버에 연결할 수 없습니다.');
          }
        } catch (e) {
          print('❌ 파이썬 서버 연결 실패: $e');
          _showServerIssueDialog('파이썬 서버 타임아웃', 'Jamendo API 서버가 응답하지 않습니다.');
        }
      } else {
        _showServerIssueDialog('스프링부트 서버 오류', '메인 서버에 문제가 있습니다.');
      }
    } catch (e) {
      print('❌ 서버 상태 확인 실패: $e');
      _showServerIssueDialog('네트워크 연결 실패', '서버에 연결할 수 없습니다. 네트워크를 확인해주세요.');
    }
  }

  /**
   * 서버 문제 안내 다이얼로그
   */
  void _showServerIssueDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 해결 방법:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('• 잠시 후 다시 시도해보세요'),
                  Text('• 네트워크 연결을 확인해보세요'),
                  Text('• 앱을 다시 시작해보세요'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadThemesFromSpringBoot(); // 다시 시도
            },
            child: Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_themes.isEmpty) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        // 실제 Jamendo 음악 URL로 재생
        final currentTheme = _themes[_selectedThemeIndex];
        if (currentTheme.audioUrl.isNotEmpty) {
          await _audioPlayer.play(UrlSource(currentTheme.audioUrl));
          print('재생: ${currentTheme.title} - ${currentTheme.audioUrl}');
        } else {
          print('재생할 수 있는 URL이 없습니다: ${currentTheme.title}');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('재생할 수 있는 음악이 없습니다.')));
          return;
        }
      }

      setState(() {
        _isPlaying = !_isPlaying;
        _currentPlayingTheme = _themes[_selectedThemeIndex].title;
      });
    } catch (e) {
      print('재생 중 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('음악 재생 중 오류가 발생했습니다.')));
    }
  }

  void _playTheme(int index) {
    if (_themes.isEmpty || index >= _themes.length) return;

    setState(() {
      _selectedThemeIndex = index;
      _currentPlayingTheme = _themes[index].title;
      _isPlaying = false; // 일시 정지 상태로 설정
      _position = Duration.zero;
    });

    // 자동으로 재생 시작
    _togglePlayPause();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_sleep.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // 상단 헤더
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
                        const Spacer(),
                        // 새로고침 버튼
                        GestureDetector(
                          onTap: _loadThemesFromSpringBoot,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 서버 상태 확인 버튼
                        GestureDetector(
                          onTap: _checkServerHealth,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.health_and_safety,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 곰돌이 일러스트 영역
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 별들
                          Positioned(
                            top: 20,
                            left: 50,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 60,
                            right: 80,
                            child: Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 하단 플레이어 영역
                  Expanded(
                    flex: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(30, 25, 30, 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 80),

                            // 제목과 설명
                            const Text(
                              'Sleep Music',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // 테마 검색 버튼 추가
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children:
                                [
                                  '잔잔한 피아노',
                                  '기타 멜로디',
                                  '자연의 소리',
                                  '달빛',
                                  '하늘',
                                  '클래식',
                                ]
                                    .map(
                                      (theme) => Padding(
                                    padding: const EdgeInsets.only(
                                      right: 8,
                                    ),
                                    child: ElevatedButton(
                                      onPressed:
                                          () => _searchByTheme(theme),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF6B73FF,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                      child: Text(theme),
                                    ),
                                  ),
                                )
                                    .toList(),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 플레이어 컨트롤
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 이전 버튼 (10초 뒤로)
                                GestureDetector(
                                  onTap: () async {
                                    final newPosition =
                                        _position - const Duration(seconds: 10);
                                    if (newPosition.inSeconds >= 0) {
                                      await _audioPlayer.seek(newPosition);
                                    }
                                  },
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.replay_10,
                                      color: Colors.grey,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 30),
                                // 재생/일시정지 버튼
                                GestureDetector(
                                  onTap: _togglePlayPause,
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4A4A4A),
                                      shape: BoxShape.circle,
                                    ),
                                    child:
                                    _isLoading
                                        ? const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    )
                                        : Icon(
                                      _isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 30),
                                // 다음 버튼 (10초 앞으로)
                                GestureDetector(
                                  onTap: () async {
                                    final newPosition =
                                        _position + const Duration(seconds: 10);
                                    if (newPosition.inSeconds <=
                                        _duration.inSeconds) {
                                      await _audioPlayer.seek(newPosition);
                                    }
                                  },
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.forward_10,
                                      color: Colors.grey,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),

                            // 프로그레스 바
                            Column(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: const Color(0xFF6B73FF),
                                    inactiveTrackColor: Colors.grey[300],
                                    thumbColor: const Color(0xFF6B73FF),
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 8,
                                    ),
                                    trackHeight: 4,
                                  ),
                                  child: Slider(
                                    value:
                                    _duration.inSeconds > 0
                                        ? _position.inSeconds
                                        .toDouble()
                                        .clamp(
                                      0.0,
                                      _duration.inSeconds
                                          .toDouble(),
                                    )
                                        : 0.0,
                                    max: _duration.inSeconds.toDouble(),
                                    onChanged: (value) async {
                                      final position = Duration(
                                        seconds: value.toInt(),
                                      );
                                      await _audioPlayer.seek(position);
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(_position),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(_duration),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),

                            // 플레이리스트
                            Expanded(
                              child:
                              _isLoading
                                  ? const Center(
                                child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text('음악을 불러오는 중...'),
                                  ],
                                ),
                              )
                                  : _themes.isEmpty
                                  ? Center(
                                child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.music_off,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text('음악을 불러올 수 없습니다'),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed:
                                      _loadThemesFromSpringBoot,
                                      child: const Text('다시 시도'),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: _checkServerHealth,
                                      child: const Text('서버 상태 확인'),
                                    ),
                                  ],
                                ),
                              )
                                  : ListView.builder(
                                itemCount: _themes.length,
                                itemBuilder: (context, index) {
                                  final theme = _themes[index];
                                  final isSelected =
                                      _selectedThemeIndex == index;

                                  return GestureDetector(
                                    onTap: () => _playTheme(index),
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color:
                                        isSelected
                                            ? const Color(
                                          0xFF6B73FF,
                                        ).withOpacity(0.15)
                                            : Colors.white
                                            .withOpacity(0.7),
                                        borderRadius:
                                        BorderRadius.circular(16),
                                        border:
                                        isSelected
                                            ? Border.all(
                                          color: const Color(
                                            0xFF6B73FF,
                                          ).withOpacity(0.4),
                                          width: 1.5,
                                        )
                                            : Border.all(
                                          color: Colors.grey
                                              .withOpacity(0.2),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withOpacity(0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color:
                                              isSelected
                                                  ? const Color(
                                                0xFF6B73FF,
                                              )
                                                  : Colors
                                                  .grey[300],
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  blurRadius: 4,
                                                  offset: const Offset(
                                                    0,
                                                    2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              isSelected && _isPlaying
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                              color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors
                                                  .grey[600],
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                              children: [
                                                Text(
                                                  theme.title,
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                    FontWeight.w600,
                                                    color:
                                                    isSelected
                                                        ? const Color(
                                                      0xFF6B73FF,
                                                    )
                                                        : Colors
                                                        .black87,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 4,
                                                ),
                                                Text(
                                                  '${theme.duration} • ${theme.artist}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                    Colors
                                                        .grey[600],
                                                  ),
                                                ),
                                                if (theme
                                                    .description
                                                    .isNotEmpty) ...[
                                                  const SizedBox(
                                                    height: 2,
                                                  ),
                                                  Text(
                                                    theme.description,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                      Colors
                                                          .grey[500],
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                    TextOverflow
                                                        .ellipsis,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          // 음악 URL 상태 표시
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color:
                                              theme
                                                  .audioUrl
                                                  .isNotEmpty
                                                  ? Colors.green
                                                  : Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 곰돌이 이미지
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset(
                      'assets/sleep_bear.png',
                      width: 320,
                      height: 320,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 320,
                          height: 320,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDEB887),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Text('🧸', style: TextStyle(fontSize: 150)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// LullabyTheme 클래스 - JSON 파싱 기능 포함
class LullabyTheme {
  final String title;
  final String duration;
  final String audioUrl;
  final String description;
  final String artist;
  final String imageUrl;

  LullabyTheme({
    required this.title,
    required this.duration,
    required this.audioUrl,
    required this.description,
    required this.artist,
    required this.imageUrl,
  });

  /**
   * JSON에서 LullabyTheme 객체로 변환하는 팩토리 생성자
   * 스프링부트 ApiResponse의 data 부분을 파싱
   */
  factory LullabyTheme.fromJson(Map<String, dynamic> json) {
    return LullabyTheme(
      title: json['title'] ?? 'Unknown Title',
      duration: json['duration'] ?? '0:00',
      audioUrl: json['audioUrl'] ?? '',
      description: json['description'] ?? '',
      artist: json['artist'] ?? 'Unknown Artist',
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  /**
   * LullabyTheme 객체를 JSON으로 변환하는 메서드
   */
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'duration': duration,
      'audioUrl': audioUrl,
      'description': description,
      'artist': artist,
      'imageUrl': imageUrl,
    };
  }
}