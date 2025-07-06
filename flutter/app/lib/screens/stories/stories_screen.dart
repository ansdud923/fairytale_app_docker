// lib/stories_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../main.dart';
import '../service/api_service.dart';
import '../service/auth_service.dart';

class StoriesScreen extends StatefulWidget {
  @override
  _StoriesScreenState createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  // 사용자 입력 데이터
  final TextEditingController _nameController = TextEditingController();
  double _speed = 1.0;
  String? _selectedTheme;
  String? _selectedVoice;

  // 🆕 babyId 변수 추가
  int? _selectedBabyId; // baby의 ID를 저장할 변수

  // API 응답 데이터
  String? _generatedStory;
  int? _storyId;
  String? _audioUrl; // 로컬 파일 경로 또는 HTTP URL
  String? _colorImageUrl;

  // 상태 관리
  bool _isLoading = false;
  bool _isGeneratingStory = false;
  bool _isGeneratingImage = false;
  bool _isGeneratingBlackWhite = false;
  bool _isPlaying = false;
  String? _errorMessage;

  // 🎯 AudioPlayer 인스턴스
  late AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  final List<String> _themes = ['자연', '도전', '가족', '사랑', '우정', '용기'];
  final List<String> _voices = [
    "alloy",
    "echo",
    "fable",
    "onyx",
    "nova",
    "shimmer",
    "ash",
    "coral",
    "sage",
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    // AudioPlayer 초기화
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();
  }

  // 사용자 프로필 로드 (babyId 포함)
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      print('🔍 사용자 프로필 로드 시작');

      final childInfo = await AuthService.checkChildInfo();
      print('🔍 받은 childInfo: $childInfo');

      if (childInfo != null && childInfo['hasChild'] == true) {
        final childData = childInfo['childData'];
        print('🔍 childData: $childData');

        // 🔍 babyId 확인 및 설정
        if (childData.containsKey('id')) {
          _selectedBabyId = childData['id'];
          print('✅ babyId 설정됨: $_selectedBabyId');
          print('🔍 babyId 타입: ${_selectedBabyId.runtimeType}');
        } else {
          print('❌ childData에 id 필드가 없음!');
          print('🔍 childData의 모든 키: ${childData.keys.toList()}');
          _selectedBabyId = null;
        }

        // 🔍 babyName 확인 및 설정
        if (childData.containsKey('name')) {
          // 'babyName' → 'name' 으로 변경
          _nameController.text = childData['name'] ?? '우리 아이';
          print('✅ babyName 설정됨: ${_nameController.text}');
        } else if (childData.containsKey('babyName')) {
          // 호환성을 위해 babyName도 체크
          _nameController.text = childData['babyName'] ?? '우리 아이';
          print('✅ babyName 설정됨 (babyName 필드): ${_nameController.text}');
        } else {
          print('❌ childData에 name 또는 babyName 필드가 없음!');
          print('🔍 사용 가능한 필드들: ${childData.keys.toList()}');
          _nameController.text = '우리 아이';
        }
      } else {
        print('⚠️ 아이 정보가 없음 (hasChild: false 또는 childInfo null)');
        _nameController.text = '우리 아이';
        _selectedBabyId = null;
      }

      print('🔍 최종 설정된 값들:');
      print('  - babyId: $_selectedBabyId');
      print('  - babyName: ${_nameController.text}');
    } catch (e) {
      print('❌ 아이 정보 로드 오류: $e');
      _nameController.text = '우리 아이';
      _selectedBabyId = null;
      _showError('사용자 정보를 불러오는데 실패했습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // AudioPlayer 이벤트 리스너 설정
  void _initAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      setState(() {
        _playerState = state;
        _isPlaying = state == PlayerState.playing;
      });
    });

    _audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        _duration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((Duration position) {
      setState(() {
        _position = position;
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  // 인증된 HTTP 요청을 위한 헤더 가져오기
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    return {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
  }

  // 동화 생성
  Future<void> _generateStory() async {
    // 입력 검증
    if (_selectedTheme == null || _selectedTheme!.isEmpty) {
      _showError('테마를 선택해주세요.');
      return;
    }

    if (_selectedVoice == null || _selectedVoice!.isEmpty) {
      _showError('목소리를 선택해주세요.');
      return;
    }

    setState(() {
      _isGeneratingStory = true;
      _errorMessage = null;
    });

    try {
      // 🔍 현재 상태 확인
      print('🔍 동화 생성 시작');
      print('🔍 현재 선택된 babyId: $_selectedBabyId');
      print('🔍 babyId 타입: ${_selectedBabyId.runtimeType}');
      print('🔍 babyId == null: ${_selectedBabyId == null}');
      print('🔍 선택된 테마: $_selectedTheme');
      print('🔍 선택된 목소리: $_selectedVoice');

      final headers = await _getAuthHeaders();

      // 🔍 전송할 데이터 구성
      final requestData = {
        'theme': _selectedTheme,
        'voice': _selectedVoice,
        'babyId': _selectedBabyId, // null일 수도 있음
      };

      print('🚀 서버로 전송할 데이터:');
      requestData.forEach((key, value) {
        print('  - $key: $value (${value.runtimeType})');
      });
      print('📦 전체 JSON: ${json.encode(requestData)}');

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/fairytale/generate/story'),
        headers: headers,
        body: json.encode(requestData),
      );

      print('🔍 서버 응답:');
      print('  - 상태 코드: ${response.statusCode}');
      print('  - 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ 동화 생성 성공!');

        // 🎯 응답 데이터 처리 (중요한 부분!)
        setState(() {
          _generatedStory =
              responseData['content'] ??
                  responseData['story'] ??
                  '동화 내용을 불러올 수 없습니다.';
          _storyId = responseData['id'];
        });

        print('✅ 화면 업데이트 완료:');
        print('  - storyId: $_storyId');
        print('  - story 길이: ${_generatedStory?.length ?? 0}자');

        // 🎵 음성 자동 생성 시작
        if (_storyId != null) {
          print('🎵 음성 생성 자동 시작...');
          _generateVoice();
        }
      } else if (response.statusCode == 401) {
        print('❌ 인증 실패 (401)');
        _showError('로그인이 만료되었습니다. 다시 로그인해주세요.');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        print('❌ API 오류: ${response.statusCode}');
        final errorMessage =
        response.body.isNotEmpty
            ? json.decode(response.body)['message'] ?? '동화 생성에 실패했습니다.'
            : '동화 생성에 실패했습니다.';
        _showError(errorMessage);
      }
    } catch (e) {
      print('❌ 동화 생성 에러: $e');
      _showError('동화 생성 중 오류가 발생했습니다: ${e.toString()}');
    } finally {
      setState(() {
        _isGeneratingStory = false;
      });
    }
  }

  // 에러 표시 메서드
  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // 🎯 S3 연동 음성 생성 및 재생 (Flutter)

  // 🎯 S3 기반 음성 생성 (속도 파라미터 추가)
  Future<void> _generateVoice() async {
    if (_storyId == null) return;

    try {
      final headers = await _getAuthHeaders();

      // 🎯 중요: speed 파라미터 추가!
      final requestData = {
        'storyId': _storyId,
        'voice': _selectedVoice,
        'speed': _speed, // 🎯 이 줄이 누락되어 있었음!
      };

      print('🔍 음성 생성 요청: ${json.encode(requestData)}');
      print('🔍 요청된 속도: $_speed');

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/fairytale/generate/voice'),
        headers: headers,
        body: json.encode(requestData),
      );

      print('🔍 음성 생성 응답 상태: ${response.statusCode}');
      print('🔍 음성 생성 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // 🎯 S3 URL 또는 HTTP URL 처리
        String? voiceUrl = _extractVoiceUrl(responseData);

        print('🔍 추출된 음성 URL: $voiceUrl');

        if (voiceUrl != null && voiceUrl.isNotEmpty) {
          // 🎯 S3 URL 직접 사용 (다운로드 불필요)
          await _processS3AudioUrl(voiceUrl);
        } else {
          print('❌ 유효한 음성 URL을 받지 못했습니다.');
          _showError('음성 생성에 실패했습니다.');
        }
      }
    } catch (e) {
      print('❌ 음성 생성 에러: $e');
      _showError('음성 생성 중 오류가 발생했습니다.');
    }
  }

  // 🎯 응답에서 음성 URL 추출 (여러 필드명 지원)
  String? _extractVoiceUrl(Map<String, dynamic> responseData) {
    // 가능한 필드명들 (API 응답 구조에 따라)
    List<String> possibleFields = [
      'voiceContent', // Story 엔티티의 필드명
      'voice_content',
      'audioUrl',
      'audio_url',
      'voiceUrl',
      'voice_url',
    ];

    for (String field in possibleFields) {
      if (responseData.containsKey(field)) {
        String? url = responseData[field];
        if (url != null && url.isNotEmpty && url != 'null') {
          return url;
        }
      }
    }

    return null;
  }

  // 🎯 S3 오디오 URL 처리 (직접 사용)
  Future<void> _processS3AudioUrl(String audioUrl) async {
    try {
      print('🔍 오디오 URL 처리 시작: $audioUrl');

      // 🌐 HTTP/HTTPS URL 확인 (S3 또는 CloudFront URL)
      if (audioUrl.startsWith('http://') || audioUrl.startsWith('https://')) {
        print('✅ S3/CloudFront URL 감지: $audioUrl');

        setState(() {
          _audioUrl = audioUrl;
        });

        // 🎵 오디오 플레이어에 URL 설정
        try {
          await _audioPlayer.setSourceUrl(_audioUrl!);
          print('✅ S3 오디오 미리 로드 완료');
        } catch (e) {
          print('⚠️ S3 오디오 미리 로드 실패: $e');
          // 미리 로드 실패해도 재생시 다시 시도
        }
        return;
      }

      // 🔄 레거시: 로컬 파일 경로인 경우 (호환성 유지)
      if (audioUrl.startsWith('/') ||
          audioUrl.contains('/tmp/') ||
          audioUrl.contains('/var/')) {
        print('⚠️ 로컬 파일 경로 감지 (레거시): $audioUrl');
        print('🔄 S3 마이그레이션 권장');

        // 기존 다운로드 API 호출 (임시 지원)
        await _downloadLegacyAudioFile(audioUrl);
        return;
      }

      // 🎯 Presigned URL 처리 (보안이 필요한 경우)
      if (_isPresignedUrl(audioUrl)) {
        print('🔐 Presigned URL 감지: $audioUrl');
        setState(() {
          _audioUrl = audioUrl;
        });

        try {
          await _audioPlayer.setSourceUrl(_audioUrl!);
          print('✅ Presigned URL 오디오 로드 완료');
        } catch (e) {
          print('⚠️ Presigned URL 오디오 로드 실패: $e');
        }
        return;
      }

      // 기타 경우
      print('⚠️ 알 수 없는 오디오 URL 형식: $audioUrl');
      _showError('지원하지 않는 음성 파일 형식입니다.');
    } catch (e) {
      print('❌ S3 오디오 URL 처리 에러: $e');
      _showError('음성 파일 처리 중 오류가 발생했습니다.');
    }
  }

  // 🔐 Presigned URL 여부 확인
  bool _isPresignedUrl(String url) {
    return url.contains('amazonaws.com') &&
        (url.contains('X-Amz-Algorithm') || url.contains('Signature'));
  }

  // 🔄 레거시 로컬 파일 다운로드 (호환성 유지)
  Future<void> _downloadLegacyAudioFile(String serverFilePath) async {
    try {
      print('🔄 [LEGACY] 로컬 파일 다운로드: $serverFilePath');
      print('⚠️ 이 방식은 곧 지원 중단됩니다.');

      final headers = await _getAuthHeaders();
      final requestData = {'filePath': serverFilePath};

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/fairytale/download/audio'),
        headers: headers,
        body: json.encode(requestData),
      );

      print('🔍 레거시 다운로드 API 응답: ${response.statusCode}');

      // S3 리다이렉트 확인
      if (response.statusCode == 301) {
        // Moved Permanently
        String? s3Url = response.headers['x-s3-url'];
        if (s3Url != null) {
          print('🔄 서버에서 S3 URL 리다이렉트: $s3Url');
          await _processS3AudioUrl(s3Url);
          return;
        }
      }

      if (response.statusCode == 200) {
        // 기존 로컬 파일 처리 로직
        final audioBytes = response.bodyBytes;
        print('🔍 받은 오디오 데이터 크기: ${audioBytes.length} bytes');

        if (audioBytes.isEmpty) {
          throw Exception('서버에서 빈 오디오 파일을 받았습니다.');
        }

        // 앱의 임시 디렉토리에 저장
        final appDir = await getTemporaryDirectory();
        final fileName =
            'story_audio_${_storyId}_${DateTime
            .now()
            .millisecondsSinceEpoch}.mp3';
        final localFile = File('${appDir.path}/$fileName');

        await localFile.writeAsBytes(audioBytes);
        print('✅ 로컬 파일 저장 완료: ${localFile.path}');

        setState(() {
          _audioUrl = localFile.path;
        });

        try {
          await _audioPlayer.setSourceDeviceFile(_audioUrl!);
          print('✅ 로컬 오디오 파일 미리 로드 완료');
        } catch (e) {
          print('⚠️ 로컬 오디오 미리 로드 실패: $e');
        }
      } else {
        throw Exception('레거시 다운로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 레거시 오디오 다운로드 실패: $e');
      _showError('음성 파일 다운로드에 실패했습니다.');
    }
  }

  // 🎵 S3 기반 음성 재생 (URL 타입별 처리)
  Future<void> _playPauseAudio() async {
    if (_audioUrl == null) {
      _showError('음성이 생성되지 않았습니다.');
      return;
    }

    try {
      if (_isPlaying) {
        // 일시정지
        print('🎵 음성 일시정지');
        await _audioPlayer.pause();
      } else {
        // 재생
        print('🎵 음성 재생 시작: $_audioUrl');

        if (_position == Duration.zero) {
          // 처음 재생하는 경우
          if (_audioUrl!.startsWith('http')) {
            // 🌐 HTTP/HTTPS URL (S3, CloudFront, Presigned URL 등)
            print('🌐 HTTP URL로 재생: $_audioUrl');
            await _audioPlayer.play(UrlSource(_audioUrl!));
          } else {
            // 📱 로컬 파일 (레거시)
            print('📱 로컬 파일로 재생: $_audioUrl');
            await _audioPlayer.play(DeviceFileSource(_audioUrl!));
          }
        } else {
          // 일시정지된 상태에서 재개
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      print('❌ 음성 재생 에러: $e');

      // 🔄 재시도 로직
      if (e.toString().contains('setSource')) {
        print('🔄 소스 설정 에러, 재시도...');
        try {
          await _audioPlayer.stop();
          await Future.delayed(Duration(milliseconds: 500));

          if (_audioUrl!.startsWith('http')) {
            await _audioPlayer.setSourceUrl(_audioUrl!);
          } else {
            await _audioPlayer.setSourceDeviceFile(_audioUrl!);
          }

          await _audioPlayer.resume();
          print('✅ 재시도 성공');
        } catch (retryError) {
          print('❌ 재시도도 실패: $retryError');
          _showError('음성 재생에 실패했습니다.');
        }
      } else {
        _showError('음성 재생 중 오류가 발생했습니다: ${e.toString()}');
      }
    }
  }

  // 🔗 Presigned URL 요청 (보안이 필요한 경우)
  Future<String?> _requestPresignedUrl(int storyId, {
    int expirationMinutes = 60,
  }) async {
    try {
      print('🔗 Presigned URL 요청: StoryId=$storyId, 만료=$expirationMinutes분');

      final headers = await _getAuthHeaders();
      final requestData = {
        'storyId': storyId,
        'expirationMinutes': expirationMinutes,
      };

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/fairytale/audio/presigned-url'),
        headers: headers,
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        String? presignedUrl = responseData['presigned_url'];

        print('✅ Presigned URL 받음: $presignedUrl');
        return presignedUrl;
      } else {
        print('❌ Presigned URL 요청 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Presigned URL 요청 에러: $e');
      return null;
    }
  }

  // 음성 정지 (기존과 동일)
  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    } catch (e) {
      print('❌ 음성 정지 에러: $e');
    }
  }

  // 재생 시간을 문자열로 변환 (기존과 동일)
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // 컬러 이미지 생성
  Future<void> _generateColorImage() async {
    if (_storyId == null) {
      _showError('동화를 먼저 생성해주세요.');
      return;
    }

    setState(() {
      _isGeneratingImage = true;
      _errorMessage = null;
    });

    try {
      final headers = await _getAuthHeaders();
      final requestData = {'storyId': _storyId};

      print('🔍 컬러 이미지 생성 요청: ${json.encode(requestData)}');

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/fairytale/generate/image'),
        headers: headers,
        body: json.encode(requestData),
      );

      print('🔍 컬러 이미지 생성 응답 상태: ${response.statusCode}');
      print('🔍 컬러 이미지 생성 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        String? imageUrl;

        if (responseData.containsKey('image')) {
          imageUrl = responseData['image'];
        } else if (responseData.containsKey('imageUrl')) {
          imageUrl = responseData['imageUrl'];
        } else if (responseData.containsKey('image_url')) {
          imageUrl = responseData['image_url'];
        } else if (responseData.containsKey('colorImageUrl')) {
          imageUrl = responseData['colorImageUrl'];
        }

        if (imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'null') {
          setState(() {
            _colorImageUrl = imageUrl;
          });
          print('✅ 컬러 이미지 생성 완료: $imageUrl');
        } else {
          throw Exception('응답에서 유효한 이미지 URL을 찾을 수 없습니다.');
        }
      } else {
        throw Exception('컬러 이미지 생성에 실패했습니다. 상태 코드: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 컬러 이미지 생성 에러: $e');
      _showError('컬러 이미지 생성 중 오류가 발생했습니다: ${e.toString()}');
    } finally {
      setState(() => _isGeneratingImage = false);
    }
  }

  // 1. 🎯 _getBlackWhiteImageAndNavigate 메서드 완전 수정 (색칠공부 화면으로 이동)
  // 🎯 흑백 변환 후 템플릿 목록으로 이동하는 방식

  Future<void> _getBlackWhiteImageAndNavigate() async {
    if (_storyId == null) {
      _showError('동화를 먼저 생성해주세요.');
      return;
    }

    if (_colorImageUrl == null ||
        _colorImageUrl!.isEmpty ||
        _colorImageUrl == 'null') {
      _showError('컬러 이미지를 먼저 생성해주세요.');
      return;
    }

    setState(() => _isGeneratingBlackWhite = true);

    try {
      print('🎨 흑백 변환 및 템플릿 생성 시작');
      print('🔍 컬러 이미지 URL: $_colorImageUrl');
      print('🔍 StoryId: $_storyId');

      // 1. 🎯 먼저 흑백 변환 API 호출 (중요!)
      final headers = await _getAuthHeaders();
      final blackWhiteRequest = {
        'text': _colorImageUrl, // 컬러 이미지 URL 전송
      };

      print('🔍 흑백 변환 요청: ${json.encode(blackWhiteRequest)}');

      final bwResponse = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/fairytale/convert/bwimage'),
        headers: headers,
        body: json.encode(blackWhiteRequest),
      );

      print('🔍 흑백 변환 응답 상태: ${bwResponse.statusCode}');
      print('🔍 흑백 변환 응답 본문: ${bwResponse.body}');

      String? blackWhiteImageUrl;

      if (bwResponse.statusCode == 200) {
        final bwResponseData = json.decode(bwResponse.body);
        if (bwResponseData.containsKey('image_url')) {
          blackWhiteImageUrl = bwResponseData['image_url'];
          print('✅ 흑백 변환 성공: $blackWhiteImageUrl');
        } else {
          print('⚠️ 흑백 변환 응답에 image_url 없음, 원본 사용');
          blackWhiteImageUrl = _colorImageUrl; // 폴백
        }
      } else {
        print('⚠️ 흑백 변환 실패, 원본 이미지 사용');
        blackWhiteImageUrl = _colorImageUrl; // 폴백
      }

      // 2. 🎯 색칠공부 템플릿 생성 API 호출
      final createTemplateRequest = {
        'storyId': _storyId.toString(),
        'title': '${_nameController.text}의 $_selectedTheme 색칠공부',
        'originalImageUrl': _colorImageUrl, // 원본 컬러 이미지
        'blackWhiteImageUrl': blackWhiteImageUrl, // 변환된 흑백 이미지
      };

      print('🔍 템플릿 생성 요청: ${json.encode(createTemplateRequest)}');

      final createResponse = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/coloring/create-template'),
        headers: headers,
        body: json.encode(createTemplateRequest),
      );

      print('🔍 템플릿 생성 응답: ${createResponse.statusCode}');
      print('🔍 템플릿 생성 응답 본문: ${createResponse.body}');

      if (createResponse.statusCode == 200) {
        final responseData = json.decode(createResponse.body);
        if (responseData['success'] == true) {
          print('✅ 템플릿 생성 완료');

          // 🎯 성공 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎨 색칠공부 템플릿이 생성되었습니다!'),
              backgroundColor: Colors.green,
            ),
          );

          // 🔍 디버깅을 위해 1초 대기
          await Future.delayed(Duration(seconds: 1));

          // 🎯 색칠공부 화면으로 이동 - 새로 생성된 템플릿 정보 전달
          Navigator.pushNamed(
            context,
            '/coloring',
            arguments: {
              'fromStory': true,
              'newTemplateCreated': true,
              'templateData': {
                'id': responseData['template']?['id'],
                'storyId': _storyId.toString(),
                'title': '${_nameController.text}의 $_selectedTheme 색칠공부',
                'originalImageUrl': _colorImageUrl,
                'blackWhiteImageUrl': blackWhiteImageUrl,
                'imageUrl': blackWhiteImageUrl, // 색칠용으로 흑백 이미지 사용
              },
              // 🎯 즉시 색칠할 수 있도록 이미지 URL 직접 전달
              'imageUrl': blackWhiteImageUrl,
              'isBlackAndWhite': true,
            },
          );
        } else {
          throw Exception('템플릿 생성 API 응답이 실패');
        }
      } else {
        throw Exception('템플릿 생성 실패: ${createResponse.statusCode}');
      }
    } catch (e) {
      print('❌ 색칠공부 템플릿 생성 실패: $e');

      // 🔄 실패해도 기본 색칠공부 화면으로 이동 (폴백)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ 템플릿 생성에 실패했지만 색칠공부는 가능합니다.'),
          backgroundColor: Colors.orange,
        ),
      );

      Navigator.pushNamed(
        context,
        '/coloring',
        arguments: {
          'imageUrl': _colorImageUrl!,
          'isBlackAndWhite': false,
          'fromStory': true,
          'fallbackMode': true,
          'templateData': {
            'storyId': _storyId.toString(),
            'title': '${_nameController.text}의 $_selectedTheme 색칠공부',
            'originalImageUrl': _colorImageUrl,
          },
        },
      );
    } finally {
      setState(() => _isGeneratingBlackWhite = false);
    }
  }

  // 공유 기능 - 확인 다이얼로그 추가 및 에러 처리 개선
  Future<void> _shareStoryVideo() async {
    if (_storyId == null) {
      _showError('동화를 먼저 생성해주세요.');
      return;
    }

    if (_audioUrl == null || _colorImageUrl == null) {
      _showError('음성과 이미지가 모두 생성되어야 공유할 수 있습니다.');
      return;
    }

    // 확인 다이얼로그 표시
    final bool? shouldShare = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.share, color: Color(0xFFF6B756)),
              SizedBox(width: 8),
              Text('동화 공유하기'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '이 동화를 "우리의 기록일지"에 업로드하시겠습니까?',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📖 ${_nameController.text}의 $_selectedTheme 동화',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF6B756),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '동영상이 생성되어 다른 사용자들과 공유됩니다.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF6B756),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('업로드'),
            ),
          ],
        );
      },
    );

    // 사용자가 취소한 경우
    if (shouldShare != true) {
      return;
    }

    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFF6B756),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '동영상 생성 중...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '최대 5분 정도 소요됩니다',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFFF6B756).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.movie_creation,
                          size: 16,
                          color: Color(0xFFF6B756),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '이미지와 음성을 합치는 중',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFF6B756),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      print('🎬 Stories 공유 요청 시작 - StoryId: $_storyId');

      // 1. 서버에 공유 요청 (비디오 생성 포함)
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/share/story/$_storyId'),
        headers: headers,
      );

      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();

      print('🔍 공유 API 응답 상태: ${response.statusCode}');
      print('🔍 공유 API 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final shareData = json.decode(response.body);

        print('✅ 공유 생성 완료: ${shareData}');

        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('동화가 성공적으로 공유되었습니다!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // 2. Share 화면으로 이동
        await Future.delayed(Duration(milliseconds: 500));
        Navigator.pushNamed(context, '/share');
      } else if (response.statusCode == 401) {
        print('❌ 인증 실패 (401)');
        _showError('로그인이 만료되었습니다. 다시 로그인해주세요.');
        Navigator.pushReplacementNamed(context, '/login');
      } else if (response.statusCode == 500) {
        // 서버 내부 오류 - 더 자세한 안내
        print('❌ 서버 내부 오류 (500)');

        // Python 서버 연결 문제일 가능성이 높음
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('동영상 생성 실패'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('동영상 생성 서버에 연결할 수 없습니다.'),
                  SizedBox(height: 8),
                  Text(
                    '잠시 후 다시 시도해주세요.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.orange[800],
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '동영상 생성 기능이 일시적으로 제한될 수 있습니다.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('확인'),
                ),
              ],
            );
          },
        );
      } else {
        print('❌ 공유 생성 실패: ${response.statusCode}');
        final errorMessage =
        response.body.isNotEmpty
            ? json.decode(response.body)['message'] ?? '동영상 생성에 실패했습니다.'
            : '동영상 생성에 실패했습니다.';
        _showError(errorMessage);
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기 (에러 발생시)
      Navigator.of(context).pop();

      print('❌ 공유 에러: $e');
      _showError('공유 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // stories_screen.dart - build 메서드 전체

  // stories_screen.dart - build 메서드 전체 (중복 제거 버전)

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    final primaryColor = Color(0xFFF6B756);

    if (_isLoading) {
      return BaseScaffold(
        child: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        // 🎯 동화세상에서 뒤로가기 누르면 홈으로 이동
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        return false; // 기본 뒤로가기 동작 방지
      },
      child: BaseScaffold(
        background: Image.asset('assets/bg_image.png', fit: BoxFit.cover),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          // 🎯 뒤로가기 버튼도 홈으로 이동
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/home',
                                (route) => false,
                          );
                        },
                      ),
                    ),
                    Image.asset('assets/logo.png', height: screenHeight * 0.25),
                    Positioned(
                      top: 20,
                      right: -18,
                      child: Image.asset(
                        'assets/rabbit.png',
                        width: screenWidth * 0.375,
                        height: screenWidth * 0.375,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: screenHeight * 0.02),

                // 아이 이름
                Row(
                  children: [
                    Text(
                      '아이 이름: ',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.04,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenWidth * 0.02,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _nameController.text,
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: screenHeight * 0.02),

                // 1. 테마 선택
                Text(
                  '1. 테마를 선택해 주세요',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.04,
                  ),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedTheme,
                  items: _themes
                      .map(
                        (theme) =>
                        DropdownMenuItem(
                          value: theme,
                          child: Text(theme),
                        ),
                  )
                      .toList(),
                  hint: Text('테마 선택'),
                  onChanged: (val) => setState(() => _selectedTheme = val),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // 2. 목소리 선택
                Text(
                  '2. 목소리를 선택해 주세요',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.04,
                  ),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedVoice,
                  items: _voices
                      .map(
                        (voice) =>
                        DropdownMenuItem(
                          value: voice,
                          child: Text(voice),
                        ),
                  )
                      .toList(),
                  hint: Text('음성 선택'),
                  onChanged: (val) => setState(() => _selectedVoice = val),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // 3. 속도 선택
                Text(
                  '3. 속도를 선택해 주세요',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.04,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.slow_motion_video, color: primaryColor),
                      Expanded(
                        child: Slider(
                          value: _speed,
                          min: 0.5,
                          max: 2.0,
                          divisions: 15,
                          activeColor: primaryColor,
                          inactiveColor: primaryColor.withOpacity(0.3),
                          label: _speed.toStringAsFixed(1) + 'x',
                          onChanged: (val) => setState(() => _speed = val),
                        ),
                      ),
                      Icon(Icons.fast_forward, color: primaryColor),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),

                // 동화 생성 버튼
                SizedBox(
                  width: double.infinity,
                  height: screenHeight * 0.06,
                  child: ElevatedButton(
                    onPressed: _isGeneratingStory ? null : _generateStory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isGeneratingStory
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('동화 생성 중...'),
                      ],
                    )
                        : Text(
                      '동화 생성',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // 에러 메시지
                if (_errorMessage != null) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],

                // 🎯 생성된 동화 영역 (수정된 부분)
                if (_generatedStory != null) ...[
                  SizedBox(height: screenHeight * 0.03),
                  Text(
                    '생성된 동화',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _generatedStory!,
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // 🎯 음성 재생 컨트롤과 이미지 생성 영역
                  if (_audioUrl != null) ...[
                    // 음성 재생 컨트롤
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 12),

                          // 재생/일시정지 버튼들
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 재생/일시정지 버튼
                              IconButton(
                                iconSize: screenWidth * 0.15,
                                icon: Icon(
                                  _isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  color: primaryColor,
                                ),
                                onPressed: _playPauseAudio,
                              ),
                              SizedBox(width: 20),
                              // 정지 버튼
                              IconButton(
                                iconSize: screenWidth * 0.08,
                                icon: Icon(Icons.stop, color: Colors.grey[600]),
                                onPressed: _isPlaying ||
                                    _position > Duration.zero
                                    ? _stopAudio
                                    : null,
                              ),
                            ],
                          ),

                          // 재생 진행 바
                          if (_duration > Duration.zero) ...[
                            SizedBox(height: 8),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                thumbShape: RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                trackHeight: 4,
                              ),
                              child: Slider(
                                value: _position.inMilliseconds.toDouble(),
                                min: 0.0,
                                max: _duration.inMilliseconds.toDouble(),
                                activeColor: primaryColor,
                                inactiveColor: primaryColor.withOpacity(0.3),
                                onChanged: (value) async {
                                  final newPosition = Duration(
                                    milliseconds: value.toInt(),
                                  );
                                  await _audioPlayer.seek(newPosition);
                                },
                              ),
                            ),

                            // 시간 표시
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(_position),
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.03,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  _formatDuration(_duration),
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.03,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.03),

                    // 🎯 이미지 생성 섹션 (음성 완료 후에만 표시)
                    if (_colorImageUrl == null) ...[
                      SizedBox(
                        width: double.infinity,
                        height: screenHeight * 0.06,
                        child: ElevatedButton(
                          onPressed: _isGeneratingImage
                              ? null
                              : _generateColorImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: _isGeneratingImage
                              ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('이미지 생성 중...'),
                            ],
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 20),
                              SizedBox(width: 8),
                              Text(
                                '이미지 생성',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else
                      ...[
                        // 컬러 이미지가 생성된 후 표시되는 영역
                        Text(
                          '생성된 이미지',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 16),

                        // 컬러 이미지 표시
                        Center(
                          child: Container(
                            width: screenWidth * 0.8,
                            height: screenWidth * 0.8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                _colorImageUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child,
                                    loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: primaryColor,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment
                                            .center,
                                        children: [
                                          Icon(
                                            Icons.image,
                                            size: screenWidth * 0.2,
                                            color: Colors.grey[600],
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            '이미지 로드 실패',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 16),

                        // 버튼들
                        Row(
                          children: [
                            // 🎯 흑백(색칠용) 버튼 - 색칠공부 화면으로 이동
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isGeneratingBlackWhite
                                    ? null
                                    : _getBlackWhiteImageAndNavigate,
                                icon: _isGeneratingBlackWhite
                                    ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                    : Icon(Icons.brush),
                                label: Text(
                                  _isGeneratingBlackWhite ? '처리중...' : '색칠하기',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            // 공유 버튼
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _shareStoryVideo,
                                icon: Icon(Icons.share),
                                label: Text('동화 공유하기'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                  ] else
                    ...[
                      // 음성이 아직 생성되지 않은 경우
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.grey,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '음성 생성 중...',
                                style: TextStyle(color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                ],

                SizedBox(height: screenHeight * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }
}