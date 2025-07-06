// lib/screens/coloring/coloring_screen.dart - 완전히 수정된 버전

import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;

import '../../main.dart';
import '../gallery/GalleryScreen.dart';
import '../service/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColoringScreen extends StatefulWidget {
  @override
  _ColoringScreenState createState() => _ColoringScreenState();
}

class _ColoringScreenState extends State<ColoringScreen> {
  final GlobalKey _canvasKey = GlobalKey();

  // 기본 상태 변수들
  List<ColoringTemplate> _templates = [];
  String? _selectedImageUrl;
  Color _selectedColor = Colors.red;
  double _brushSize = 5.0;
  double _brushOpacity = 1.0;
  bool _isLoading = false;
  bool _isProcessing = false;
  bool _showColorPalette = false;
  bool _isBlackAndWhite = false;
  bool _isPanMode = false;

  // 🎨 템플릿 정보 변수 추가
  Map<String, dynamic>? _templateData;
  int? _templateId;
  bool _fromStory = false;
  bool _fallbackMode = false;

  // 확대/축소 관련
  double _currentScale = 1.0;
  final double _minScale = 0.5;
  final double _maxScale = 3.0;
  final TransformationController _transformationController = TransformationController();

  // 그리기 관련
  List<DrawingPoint> _drawingPoints = [];

  // 색상 팔레트
  final List<Color> _colorPalette = [
    Colors.red, Colors.pink, Colors.orange, Colors.yellow,
    Colors.green, Colors.lightGreen, Colors.blue, Colors.lightBlue,
    Colors.purple, Colors.deepPurple, Colors.brown, Colors.grey,
    Colors.black, Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    // 🎯 템플릿 로드를 didChangeDependencies 이후로 연기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedImageUrl == null) {
        _loadColoringTemplates();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 🔍 전달받은 arguments 처리
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (arguments != null) {
      print('🔍 색칠공부 화면 arguments: $arguments');

      // 🎨 템플릿 정보 확인
      if (arguments.containsKey('templateId')) {
        _templateId = arguments['templateId'];
        print('✅ templateId 받음: $_templateId');
      }

      if (arguments.containsKey('templateData')) {
        _templateData = arguments['templateData'];
        print('✅ templateData 받음: $_templateData');
      }

      // 🔍 동화에서 왔는지 확인
      _fromStory = arguments['fromStory'] ?? false;
      _fallbackMode = arguments['fallbackMode'] ?? false;
      bool newTemplateCreated = arguments['newTemplateCreated'] ?? false;

      print('🔍 fromStory: $_fromStory, fallbackMode: $_fallbackMode, newTemplateCreated: $newTemplateCreated');

      // 🖼️ 이미지 URL 설정 (우선순위 정리)
      String? imageUrl;

      // 1. arguments에서 직접 전달된 imageUrl (최우선)
      if (arguments.containsKey('imageUrl')) {
        imageUrl = arguments['imageUrl'];
        print('✅ arguments에서 imageUrl 받음: $imageUrl');
      }

      // 2. 템플릿 데이터에서 흑백 이미지 URL 추출
      if (imageUrl == null && _templateData != null) {
        imageUrl = _templateData!['blackWhiteImageUrl'] ??
            _templateData!['imageUrl'];
        print('✅ 템플릿에서 imageUrl 추출: $imageUrl');
      }

      if (imageUrl != null && imageUrl.isNotEmpty) {
        setState(() {
          _selectedImageUrl = imageUrl;
          _isBlackAndWhite = arguments['isBlackAndWhite'] ?? true;
        });
        print('✅ 최종 선택된 imageUrl: $_selectedImageUrl');
      }

      // 🎯 새 템플릿이 생성된 경우 템플릿 목록 새로고침
      if (newTemplateCreated) {
        print('🔄 새 템플릿 생성으로 인한 목록 새로고침');
        Future.delayed(Duration(milliseconds: 500), () {
          _loadColoringTemplates();
        });
      }
    }
  }
  // 🎯 화면 초기화 (한 번만 실행)
  Future<void> _initializeScreen() async {
    if (_selectedImageUrl == null) {
      // 이미지가 선택되지 않은 경우에만 템플릿 로드
      await _loadColoringTemplates();
    }
  }

  // 🎯 새 템플릿 생성 후 목록 새로고침
  Future<void> _refreshTemplatesAfterDelay() async {
    // 잠시 대기 후 템플릿 목록 새로고침 (서버 처리 시간 고려)
    await Future.delayed(Duration(milliseconds: 500));
    await _loadColoringTemplates();
  }

  // 🎯 템플릿 삭제 기능
  Future<void> _deleteTemplate(ColoringTemplate template) async {
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('템플릿 삭제'),
        content: Text('정말로 이 색칠공부 템플릿을 삭제하시겠습니까?\n삭제된 템플릿은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('삭제'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('${ApiService.baseUrl}/api/coloring/templates/${template.id}');

      print('🗑️ 템플릿 삭제 API 호출: $url');
      final response = await http.delete(url, headers: headers);

      Navigator.pop(context); // 로딩 다이얼로그 닫기

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('템플릿이 삭제되었습니다.'), backgroundColor: Colors.green),
        );
        _loadColoringTemplates();
      } else {
        throw Exception('삭제 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      print('❌ 템플릿 삭제 에러: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 중 오류 발생: $e'), backgroundColor: Colors.red),
      );
    }
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

  // 확대/축소 기능들
  void _zoomIn() {
    final newScale = (_currentScale * 1.3).clamp(_minScale, _maxScale);
    _transformationController.value = Matrix4.identity()..scale(newScale);
    setState(() => _currentScale = newScale);
  }

  void _zoomOut() {
    final newScale = (_currentScale / 1.3).clamp(_minScale, _maxScale);
    _transformationController.value = Matrix4.identity()..scale(newScale);
    setState(() => _currentScale = newScale);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() => _currentScale = 1.0);
  }

  // 템플릿 로드 (개선된 버전)
  Future<void> _loadColoringTemplates() async {
    setState(() => _isLoading = true);

    try {
      print('🔍 색칠공부 템플릿 로드 시작');

      final templatesData = await ApiService.getColoringTemplates(page: 0, size: 20);

      if (templatesData != null && templatesData.isNotEmpty) {
        final templates = templatesData.map((json) => ColoringTemplate.fromJson(json)).toList();

        setState(() {
          _templates = templates;
        });

        print('✅ 색칠공부 템플릿 ${templates.length}개 로드 성공');

        // 🔍 템플릿 정보 디버깅
        for (var template in templates) {
          print('📋 템플릿: ${template.title}');
          print('   - imageUrl: ${template.imageUrl}');
          print('   - blackWhiteImageUrl: ${template.blackWhiteImageUrl}');
          print('   - originalImageUrl: ${template.originalImageUrl}');
        }
      } else {
        setState(() {
          _templates = [];
        });
        print('⚠️ 로드된 색칠공부 템플릿이 없음');
      }
    } catch (e) {
      print('❌ 템플릿 로드 실패: $e');
      setState(() {
        _templates = [];
      });

      // 🔍 오류 상세 정보 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('템플릿 로드 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

// 🎯 개선된 템플릿 선택 처리
  void _selectTemplate(ColoringTemplate template) {
    print('🎨 템플릿 선택: ${template.title}');
    print('🔍 선택된 이미지 URL: ${template.imageUrl}');

    setState(() {
      // 🎯 흑백 이미지를 우선적으로 사용
      _selectedImageUrl = template.blackWhiteImageUrl ?? template.imageUrl;
      _templateData = {
        'id': template.id,
        'storyId': template.storyId,
        'title': template.title,
        'originalImageUrl': template.originalImageUrl,
        'blackWhiteImageUrl': template.blackWhiteImageUrl,
        'imageUrl': template.imageUrl,
      };
      _drawingPoints.clear();
      _isBlackAndWhite = true; // 색칠용은 항상 흑백
    });

    print('✅ 템플릿 선택 완료 - 최종 URL: $_selectedImageUrl');
  }


// 🎨 색칠 완성작 저장 메서드 (완전히 새로운 버전)
  Future<void> _saveColoredImage() async {
    if (_selectedImageUrl == null || _drawingPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('색칠한 내용이 없습니다.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      print('🎨 색칠 완성작 저장 시작');
      print('🔍 선택된 이미지 URL: $_selectedImageUrl');
      print('🔍 템플릿 데이터: $_templateData');
      print('🔍 fromStory: $_fromStory');

      // 1. Canvas를 이미지로 변환
      RenderRepaintBoundary boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        // 2. storyId 추출 - 개선된 방식
        String? storyId = _extractStoryIdFromUrl(_selectedImageUrl!);

        if (storyId == null) {
          // 🔄 폴백: 템플릿 데이터에서 추출 시도
          if (_templateData != null) {
            storyId = _templateData!['storyId']?.toString() ??
                _templateData!['id']?.toString();
          }
        }

        if (storyId == null) {
          // 🔄 최종 폴백: 임시 ID 생성
          storyId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
          print('⚠️ storyId를 찾을 수 없어 임시 ID 사용: $storyId');
        }

        print('✅ 최종 결정된 storyId: $storyId');

        // 3. 서버에 저장 요청
        final result = await _saveColoringWorkToServer(
          byteData.buffer.asUint8List(),
          storyId,
        );

        if (result?['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎨 색칠 작품이 갤러리에 저장되었습니다!'),
              backgroundColor: Colors.green,
            ),
          );

          // 갤러리로 이동하면서 성공 메시지 표시
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GalleryScreen(),
              settings: RouteSettings(
                arguments: {
                  'selectedTab': 'coloring', // 색칠 탭으로 이동
                  'showSuccessMessage': true,
                },
              ),
            ),
          );
        } else {
          throw Exception(result?['error'] ?? '저장 실패');
        }
      }
    } catch (e) {
      print('❌ 색칠 완성작 저장 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }


// 🎯 URL에서 storyId 추출 (개선된 패턴 매칭)
  String? _extractStoryIdFromUrl(String imageUrl) {
    print('🔍 URL에서 storyId 추출 시도: $imageUrl');

    // S3 URL 패턴들
    final patterns = [
      // 1. 파일명에서 story ID 추출 (가장 일반적)
      RegExp(r'image-([a-f0-9]{8})\.'),
      RegExp(r'story[_-](\d+)'),
      RegExp(r'stories/(\d+)'),
      RegExp(r'/(\d+)/'),
      // 2. 해시 기반 ID 패턴
      RegExp(r'([a-f0-9]{8,})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(imageUrl);
      if (match != null) {
        final extractedId = match.group(1);
        print('✅ URL에서 storyId 추출 성공: $extractedId');
        return extractedId;
      }
    }

    print('❌ URL에서 storyId 추출 실패');
    return null;
  }

  // 🎯 저장용 storyId 결정 메서드 (여러 방법 시도)
  String? _getStoryIdForSaving() {
    print('🔍 저장용 storyId 결정 시작');

    // 1. 템플릿 데이터에서 storyId 추출
    if (_templateData != null) {
      if (_templateData!.containsKey('storyId')) {
        final storyId = _templateData!['storyId']?.toString();
        if (storyId != null && storyId.isNotEmpty) {
          print('✅ 템플릿 데이터에서 storyId 발견: $storyId');
          return storyId;
        }
      }

      if (_templateData!.containsKey('id')) {
        final id = _templateData!['id']?.toString();
        if (id != null && id.isNotEmpty) {
          print('✅ 템플릿 데이터에서 id 발견: $id');
          return id;
        }
      }
    }

    // 2. 기존 템플릿 목록에서 찾기
    final templateStoryId = _getCurrentTemplateStoryId();
    if (templateStoryId != null) {
      print('✅ 기존 템플릿에서 storyId 발견: $templateStoryId');
      return templateStoryId;
    }

    // 3. URL에서 추출 시도
    if (_selectedImageUrl != null) {
      // S3 URL에서 story ID 패턴 추출 시도
      final urlPatterns = [
        RegExp(r'story[_-](\d+)'),
        RegExp(r'stories/(\d+)'),
        RegExp(r'/(\d+)/'),
      ];

      for (final pattern in urlPatterns) {
        final match = pattern.firstMatch(_selectedImageUrl!);
        if (match != null) {
          final extractedId = match.group(1);
          print('✅ URL에서 storyId 추출: $extractedId');
          return extractedId;
        }
      }
    }

    print('❌ 모든 방법으로 storyId를 찾을 수 없음');
    return null;
  }


// 📋 서버에 색칠 완성작 저장 (개선된 버전)
  Future<Map<String, dynamic>?> _saveColoringWorkToServer(
      Uint8List imageData,
      String storyId,
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // MultipartRequest 생성
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/api/coloring/save-coloring-work'),
      );

      // 헤더 설정
      request.headers['Authorization'] = 'Bearer $accessToken';

      // 파라미터 추가
      request.fields['storyId'] = storyId;

      // 🎯 추가 메타데이터 포함
      if (_templateData != null) {
        if (_templateData!.containsKey('title')) {
          request.fields['storyTitle'] = _templateData!['title'].toString();
        }
        if (_templateData!.containsKey('category')) {
          request.fields['category'] = _templateData!['category'].toString();
        }
      }

      // 원본 이미지 URL 추가 (템플릿 연결용)
      if (_selectedImageUrl != null) {
        // 흑백 이미지 URL을 컬러 이미지 URL로 변환
        String originalImageUrl = _selectedImageUrl!
            .replaceAll('/bw-images/', '/story-images/')
            .replaceAll('/black-white/', '/color/');
        request.fields['originalImageUrl'] = originalImageUrl;
      }

      // 이미지 파일 추가
      request.files.add(
        http.MultipartFile.fromBytes(
          'coloredImage',
          imageData,
          filename: 'coloring_work_${DateTime.now().millisecondsSinceEpoch}.png',
        ),
      );

      print('🎨 색칠 완성작 저장 요청 - StoryId: $storyId');

      // 요청 전송
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('🎨 색칠 완성작 저장 응답: ${response.statusCode}');
      print('🎨 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('서버 오류: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ 색칠 완성작 저장 실패: $e');
      throw e;
    }
  }

  // 기존 템플릿에서 storyId 찾기 (기존 로직 유지)
  String? _getCurrentTemplateStoryId() {
    try {
      print('🔍 템플릿 찾기 시작 - 선택된 URL: $_selectedImageUrl');
      print('🔍 전체 템플릿 개수: ${_templates.length}');

      if (_templates.isEmpty) {
        print('❌ 사용할 수 있는 템플릿이 없음');
        return null;
      }

      // 선택된 이미지 URL과 일치하는 템플릿 찾기
      ColoringTemplate? template;

      // 1. 정확히 일치하는 템플릿 찾기
      try {
        template = _templates.firstWhere(
              (t) => t.imageUrl == _selectedImageUrl || t.blackWhiteImageUrl == _selectedImageUrl,
        );
        print('✅ 정확히 일치하는 템플릿 발견: ${template.title}');
      } catch (e) {
        print('⚠️ 정확히 일치하는 템플릿 없음, 대안 방법 시도');

        // 2. URL 일부분 매칭 시도
        template = _templates.cast<ColoringTemplate?>().firstWhere(
              (t) => t != null && ((_selectedImageUrl?.contains(t.id) == true) ||
              (t.imageUrl.isNotEmpty && _selectedImageUrl?.contains('image-') == true) ||
              (t.storyId != null && _selectedImageUrl?.contains(t.storyId!) == true)),
          orElse: () => null,
        );

        if (template != null) {
          print('✅ 부분 매칭으로 템플릿 발견: ${template.title}');
        }
      }

      // 3. 템플릿을 찾지 못한 경우, 첫 번째 템플릿 사용
      if (template == null && _templates.isNotEmpty) {
        template = _templates.first;
        print('⚠️ 매칭 실패, 첫 번째 템플릿 사용: ${template.title}');
      }

      if (template != null) {
        final storyId = template.storyId ?? template.id;
        print('✅ 최종 StoryId: $storyId');
        return storyId;
      }

      print('❌ 사용할 수 있는 템플릿이 없음');
      return null;
    } catch (e) {
      print('❌ 템플릿 찾기 실패: $e');
      return null;
    }
  }

  void _clearCanvas() => setState(() => _drawingPoints.clear());

  void _undoLastStroke() {
    if (_drawingPoints.isNotEmpty) {
      setState(() {
        while (_drawingPoints.isNotEmpty && _drawingPoints.last.color != null) {
          _drawingPoints.removeLast();
        }
        if (_drawingPoints.isNotEmpty) _drawingPoints.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BaseScaffold(
      child: SafeArea(
        child: Column(
          children: [
            // 상단 앱바
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.02,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.black54,
                      size: screenWidth * 0.06,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '색칠공부',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.06),
                ],
              ),
            ),

            if (_isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFFFD3A8)),
                ),
              )
            else if (_selectedImageUrl != null)
              Expanded(child: _buildColoringCanvas(screenWidth, screenHeight))
            else
              Expanded(child: _buildTemplateGrid(screenWidth, screenHeight)),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateGrid(double screenWidth, double screenHeight) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Color(0xFFFFD3A8).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.palette,
                  color: Color(0xFFFFD3A8),
                  size: screenWidth * 0.06,
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Text(
                    '저장된 동화 이미지를 선택해서 색칠해보세요!',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.03),

          // 🎯 템플릿이 없을 때 안내 메시지
          if (_templates.isEmpty)
            Container(
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: Column(
                children: [
                  Icon(
                    Icons.palette_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 20),
                  Text(
                    '아직 색칠공부 템플릿이 없어요',
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    '동화를 만들고 이미지를 생성하면\n색칠공부 템플릿이 자동으로 만들어져요!',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.grey[500],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/stories');
                    },
                    icon: Icon(Icons.auto_stories),
                    label: Text('동화 만들러 가기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFFD3A8),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
          // 🎯 기존 GridView (템플릿이 있을 때만 표시)
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: screenWidth * 0.04,
                mainAxisSpacing: screenWidth * 0.04,
                childAspectRatio: 0.8,
              ),
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final template = _templates[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImageUrl = template.imageUrl;
                      _drawingPoints.clear();
                      _isBlackAndWhite = false;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 3,
                              child: ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: Image.network(
                                  template.imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFFFFD3A8),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => Center(
                                    child: Icon(Icons.error, color: Colors.red),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: EdgeInsets.all(screenWidth * 0.03),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      template.title,
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      template.storyTitle,
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.03,
                                        color: Colors.black54,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // 🎯 삭제 버튼 추가
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _deleteTemplate(template),
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildColoringCanvas(double screenWidth, double screenHeight) {
    return Column(
      children: [
        // 상단 컨트롤
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: 8,
          ),
          child: Row(
            children: [
              // 이동 모드 버튼
              GestureDetector(
                onTap: () => setState(() => _isPanMode = !_isPanMode),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isPanMode ? Color(0xFFFFD3A8) : Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isPanMode ? '📍 이동' : '🖌️ 색칠',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: _isPanMode ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              // 색상 버튼
              GestureDetector(
                onTap: () => setState(() => _showColorPalette = !_showColorPalette),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _showColorPalette ? Color(0xFFFFD3A8) : Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        '색상',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: _showColorPalette ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 색상 팔레트
        if (_showColorPalette)
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _colorPalette.length,
              itemBuilder: (context, index) {
                final color = _colorPalette[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color ? Colors.black : Colors.grey,
                        width: _selectedColor == color ? 3 : 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // 브러시 컨트롤
        Container(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Column(
            children: [
              // 브러시 크기
              Row(
                children: [
                  Text(
                    '크기: ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Slider(
                      value: _brushSize,
                      min: 2.0,
                      max: 25.0,
                      activeColor: Color(0xFFFFD3A8),
                      onChanged: (value) => setState(() => _brushSize = value),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _selectedColor.withOpacity(_brushOpacity),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey, width: 1),
                    ),
                  ),
                ],
              ),
              // 투명도
              Row(
                children: [
                  Text(
                    '투명도: ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Slider(
                      value: _brushOpacity,
                      min: 0.1,
                      max: 1.0,
                      activeColor: Color(0xFFFFD3A8),
                      onChanged: (value) => setState(() => _brushOpacity = value),
                    ),
                  ),
                  Text(
                    '${(_brushOpacity * 100).round()}%',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 메인 캔버스
        Expanded(
          child: Container(
            margin: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
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
              child: Stack(
                children: [
                  // 캔버스
                  RepaintBoundary(
                    key: _canvasKey,
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: _minScale,
                      maxScale: _maxScale,
                      panEnabled: false,
                      scaleEnabled: false,
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: Stack(
                          children: [
                            // 배경 이미지
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(_selectedImageUrl!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            // 터치 레이어
                            Positioned.fill(
                              child: GestureDetector(
                                onPanStart: _isPanMode ? null : (details) {
                                  setState(() {
                                    _drawingPoints.add(
                                      DrawingPoint(
                                        offset: details.localPosition,
                                        color: _selectedColor.withOpacity(_brushOpacity),
                                        strokeWidth: _brushSize,
                                      ),
                                    );
                                  });
                                },
                                onPanUpdate: _isPanMode ? (details) {
                                  final transform = _transformationController.value;
                                  final newTransform = Matrix4.copy(transform);
                                  newTransform.translate(details.delta.dx, details.delta.dy);
                                  _transformationController.value = newTransform;
                                } : (details) {
                                  setState(() {
                                    _drawingPoints.add(
                                      DrawingPoint(
                                        offset: details.localPosition,
                                        color: _selectedColor.withOpacity(_brushOpacity),
                                        strokeWidth: _brushSize,
                                      ),
                                    );
                                  });
                                },
                                onPanEnd: _isPanMode ? null : (details) {
                                  setState(() => _drawingPoints.add(DrawingPoint()));
                                },
                                child: CustomPaint(
                                  painter: ColoringPainter(_drawingPoints),
                                  size: Size.infinite,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 상단 버튼들 (확대/축소만)
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 축소
                        _buildZoomButton(Icons.remove, _currentScale > _minScale, _zoomOut),
                        SizedBox(width: 12),
                        // 홈/배율
                        GestureDetector(
                          onTap: _resetZoom,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              '${(_currentScale * 100).round()}%',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        // 확대
                        _buildZoomButton(Icons.add, _currentScale < _maxScale, _zoomIn),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 하단 버튼들
        Container(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _drawingPoints.isNotEmpty ? _undoLastStroke : null,
                  child: Text('실행취소'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _drawingPoints.isNotEmpty ? _clearCanvas : null,
                  child: Text('전체삭제'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _saveColoredImage,
                  child: _isProcessing
                      ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text('저장'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFD3A8),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildZoomButton(IconData icon, bool enabled, VoidCallback? onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: enabled ? Color(0xFFFFD3A8) : Colors.grey,
          size: 20,
        ),
      ),
    );
  }
}

// 드로잉 포인트 클래스
class DrawingPoint {
  final Offset? offset;
  final Color? color;
  final double? strokeWidth;

  DrawingPoint({this.offset, this.color, this.strokeWidth});
}

// 페인터 클래스
class ColoringPainter extends CustomPainter {
  final List<DrawingPoint> drawingPoints;

  ColoringPainter(this.drawingPoints);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < drawingPoints.length; i++) {
      final point = drawingPoints[i];

      if (point.offset != null && point.color != null) {
        paint.color = point.color!;
        paint.strokeWidth = point.strokeWidth ?? 5.0;

        if (i > 0 &&
            drawingPoints[i - 1].offset != null &&
            drawingPoints[i - 1].color != null) {
          canvas.drawLine(drawingPoints[i - 1].offset!, point.offset!, paint);
        } else {
          canvas.drawCircle(point.offset!, paint.strokeWidth / 2, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ColoringTemplate 모델
class ColoringTemplate {
  final String id;
  final String title;
  final String imageUrl;
  final String? blackWhiteImageUrl;
  final String? originalImageUrl;  // 원본 이미지 URL 추가
  final String createdAt;
  final String storyTitle;
  final String? storyId;

  ColoringTemplate({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.blackWhiteImageUrl,
    this.originalImageUrl,
    required this.createdAt,
    required this.storyTitle,
    this.storyId,
  });

  factory ColoringTemplate.fromJson(Map<String, dynamic> json) {
    print('🔍 [ColoringTemplate] JSON 파싱: ${json.keys.toList()}');
    print('🔍 [ColoringTemplate] imageUrl: ${json['imageUrl']}');
    print('🔍 [ColoringTemplate] originalImageUrl: ${json['originalImageUrl']}');
    print('🔍 [ColoringTemplate] blackWhiteImageUrl: ${json['blackWhiteImageUrl']}');

    return ColoringTemplate(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '제목 없음',
      // 🎯 핵심 수정: 흑백 이미지를 메인 imageUrl로 사용
      imageUrl: json['imageUrl'] ?? json['blackWhiteImageUrl'] ?? json['originalImageUrl'] ?? '',
      blackWhiteImageUrl: json['blackWhiteImageUrl'],
      originalImageUrl: json['originalImageUrl'],  // 원본 이미지 별도 저장
      createdAt: json['createdAt'] ?? '',
      storyTitle: json['title'] ?? '동화 제목 없음',
      storyId: json['storyId']?.toString(),
    );
  }
}