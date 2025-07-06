// lib/gallery/gallery_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../service/api_service.dart';
import '../../main.dart';

class GalleryScreen extends StatefulWidget {
  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<GalleryItem> _galleryItems = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedTab = 'all'; // 'all', 'color', 'coloring'

  @override
  void initState() {
    super.initState();

    // 🎯 전달받은 arguments에서 선택할 탭과 성공 메시지 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args != null) {
        // 탭 설정
        if (args['selectedTab'] != null) {
          setState(() {
            _selectedTab = args['selectedTab'] as String;
          });
          print('🎯 갤러리 초기 탭 설정: $_selectedTab');
        }

        // 🎯 성공 메시지 표시
        if (args['showSuccessMessage'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎨 멋진 작품이 갤러리에 저장되었습니다!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    });

    _loadGalleryData();
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

  // 갤러리 데이터 로드
  Future<void> _loadGalleryData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final headers = await _getAuthHeaders();

      print('🔍 갤러리 데이터 요청 시작');

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/gallery/images'),
        headers: headers,
      );

      print('🔍 갤러리 응답 상태: ${response.statusCode}');
      print('🔍 갤러리 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        setState(() {
          _galleryItems =
              responseData.map((item) => GalleryItem.fromJson(item)).toList();
        });

        print('✅ 갤러리 데이터 로드 완료: ${_galleryItems.length}개 아이템');
      } else {
        throw Exception('갤러리 데이터 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 갤러리 데이터 로드 에러: $e');
      setState(() {
        _errorMessage = '갤러리 데이터를 불러오는데 실패했습니다.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 필터링된 갤러리 아이템 가져오기 (수정됨)
  List<GalleryItem> get _filteredItems {
    switch (_selectedTab) {
      case 'color':
      // 🎯 순수 컬러 이미지만 (색칠 완성작 제외)
        return _galleryItems
            .where((item) =>
        item.colorImageUrl != null &&
            !(item.isColoringWork ?? false) &&
            item.type != 'coloring')
            .toList();
      case 'coloring':
      // 🎯 색칠 완성작만
        return _galleryItems
            .where((item) =>
        (item.isColoringWork ?? false) ||
            item.type == 'coloring' ||
            item.coloringImageUrl != null)
            .toList();
      default:
        return _galleryItems;
    }
  }


// GalleryScreen.dart - _showImageDetail 메서드 수정

// 🎯 이미지 상세보기 모달 (색칠 완성작만 표시)
  void _showImageDetail(GalleryItem item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: Container(
                margin: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 헤더
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.storyTitle ?? '동화 이미지',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),

                    // 🎯 색칠된 이미지만 표시 (조건부 렌더링)
                    Flexible(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              // 🎯 색칠 완성작이 있으면 색칠된 이미지만 표시
                              if (item.coloringImageUrl != null) ...[
                                Text(
                                  '🎨 색칠 완성작',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                                SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    item.coloringImageUrl!,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 300,
                                        child: Center(child: CircularProgressIndicator()),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 300,
                                        color: Colors.grey[300],
                                        child: Center(child: Icon(Icons.error)),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(height: 16),
                              ]
                              // 🎯 색칠 완성작이 없고 컬러 이미지만 있는 경우
                              else if (item.colorImageUrl != null) ...[
                                Text(
                                  '🖼️ 컬러 이미지',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2196F3),
                                  ),
                                ),
                                SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    item.colorImageUrl!,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 300,
                                        child: Center(child: CircularProgressIndicator()),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 300,
                                        color: Colors.grey[300],
                                        child: Center(child: Icon(Icons.error)),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(height: 16),
                              ]
                              // 🎯 이미지가 없는 경우
                              else ...[
                                  Container(
                                    height: 200,
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                                          SizedBox(height: 8),
                                          Text('이미지를 찾을 수 없습니다', style: TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 버튼들 (기존과 동일)
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // 공유 버튼
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                if (item.coloringImageUrl != null) {
                                  _shareColoringWork(item);
                                } else {
                                  _shareFromGallery(item);
                                }
                              },
                              icon: Icon(Icons.share),
                              label: Text('기록일지에 공유하기'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFF6B756),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          // 삭제 버튼
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.pop(context);
                                await _deleteGalleryItem(item);
                              },
                              icon: Icon(Icons.delete),
                              label: Text('삭제하기'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 수정된 삭제 함수 - 로직 개선
  Future<void> _deleteGalleryItem(GalleryItem item) async {
    final headers = await _getAuthHeaders();

    // 🎯 type 필드를 우선으로 하여 타입 결정
    final isColoringWork = item.type == 'coloring' || (item.isColoringWork ?? false);
    final itemType = item.type == 'coloring' ? 'coloring' : 'story';
    final itemId = isColoringWork ? (item.coloringWorkId ?? item.storyId) : item.storyId;

    print('🔍 삭제 요청 상세 정보:');
    print('   - storyId: ${item.storyId}');
    print('   - isColoringWork: ${item.isColoringWork}');
    print('   - type: ${item.type}');
    print('   - coloringWorkId: ${item.coloringWorkId}');
    print('   - 계산된 itemId: $itemId');
    print('   - 계산된 itemType: $itemType');

    // API 경로 수정 - 새로운 엔드포인트 사용
    final url = Uri.parse('${ApiService.baseUrl}/api/gallery/$itemId?type=$itemType');

    // 삭제 확인 다이얼로그
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('이미지 삭제'),
        content: Text('정말로 이 이미지를 삭제하시겠습니까?\n삭제된 이미지는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('삭제'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    // 로딩 다이얼로그
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      print('🔍 삭제 API 호출: $url');
      final response = await http.delete(url, headers: headers);
      Navigator.pop(context); // 로딩 다이얼로그 닫기

      print('🔍 삭제 응답: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        // 삭제 성공!
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지가 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        // 갤러리 다시 불러오기
        _loadGalleryData();
      } else {
        final errorData = json.decode(response.body);
        throw Exception('삭제 실패: ${errorData['error'] ?? response.statusCode}');
      }
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      print('❌ 삭제 에러: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('삭제 중 오류 발생: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🎯 색칠 완성작 전용 공유 기능 (새로 추가)
  Future<void> _shareColoringWork(GalleryItem item) async {
    print('🎨 색칠 완성작 공유 시작 - ColoringWorkId: ${item.coloringWorkId}');

    // 공유 확인 다이얼로그
    bool? shouldShare = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('색칠 완성작 공유하기'),
        content: Text('이 색칠 작품을 기록일지에 공유하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFF6B756),
            ),
            child: Text('공유하기'),
          ),
        ],
      ),
    );

    if (shouldShare != true) return;

    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFF6B756)),
              SizedBox(height: 16),
              Text(
                '색칠 작품을 공유하는 중...',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                '잠시만 기다려주세요.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final headers = await _getAuthHeaders();

      // 🎯 색칠 완성작 ID 사용 (storyId 대신 coloringWorkId 사용)
      final shareId = item.coloringWorkId ?? item.storyId;
      print('🎨 색칠 완성작 공유 요청 - ID: $shareId');

      // 색칠 완성작 전용 공유 API 엔드포인트
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/share/coloring-work/$shareId'),
        headers: headers,
      );

      // 로딩 다이얼로그 닫기
      Navigator.pop(context);

      print('🎨 색칠 완성작 공유 응답: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        // 성공 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 색칠 작품이 성공적으로 공유되었습니다!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // 공유 화면으로 이동
        Navigator.pushNamed(context, '/share');

      } else {
        throw Exception('공유 실패: ${response.statusCode}');
      }

    } catch (e) {
      // 로딩 다이얼로그가 열려있다면 닫기
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('❌ 색칠 완성작 공유 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('공유 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 갤러리에서 공유 기능 (기존)
  Future<void> _shareFromGallery(GalleryItem item) async {
    // 공유 가능한 이미지가 있는지 확인
    if (item.colorImageUrl == null && item.coloringImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('공유할 이미지가 없습니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 공유 확인 다이얼로그
    bool? shouldShare = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('갤러리에서 공유하기'),
        content: Text('이 작품을 기록일지에 공유하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFF6B756),
            ),
            child: Text('공유하기'),
          ),
        ],
      ),
    );

    if (shouldShare != true) return;

    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFF6B756)),
              SizedBox(height: 16),
              Text(
                '작품을 비디오로 변환하는 중...',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                '잠시만 기다려주세요.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final headers = await _getAuthHeaders();

      print('🎬 Gallery에서 공유 요청 시작 - StoryId: ${item.storyId}');

      // Gallery ID로 공유 (실제로는 storyId를 사용하지만 갤러리 엔드포인트 사용)
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/share/gallery/${item.storyId}'),
        headers: headers,
      );

      // 로딩 다이얼로그 닫기
      Navigator.pop(context);

      print('🎬 Gallery 공유 응답 상태: ${response.statusCode}');
      print('🎬 Gallery 공유 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        // 성공 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 작품이 성공적으로 공유되었습니다!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // 공유 화면으로 이동
        Navigator.pushNamed(context, '/share');

      } else {
        throw Exception('공유 실패: ${response.statusCode}');
      }

    } catch (e) {
      // 로딩 다이얼로그가 열려있다면 닫기
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('❌ Gallery 공유 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('공유 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final primaryColor = Color(0xFFF6B756);

    return BaseScaffold(
      background: Image.asset('assets/bg_image.png', fit: BoxFit.cover),
      child: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      '갤러리',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.white),
                    onPressed: _loadGalleryData,
                  ),
                ],
              ),
            ),

            // 탭 버튼들
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _buildTabButton('전체', 'all')),
                  SizedBox(width: 8),
                  Expanded(child: _buildTabButton('컬러', 'color')),
                  SizedBox(width: 8),
                  Expanded(child: _buildTabButton('색칠', 'coloring')),
                ],
              ),
            ),

            SizedBox(height: 16),

            // 컨텐츠 영역
            Expanded(
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
                  : _errorMessage != null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadGalleryData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                      child: Text('다시 시도'),
                    ),
                  ],
                ),
              )
                  : _filteredItems.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 64,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '아직 이미지가 없어요',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '동화를 만들고 이미지를 생성해보세요!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
                  : Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    return _buildGalleryCard(_filteredItems[index]);
                  },
                ),
              ),
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // 탭 버튼 위젯
  Widget _buildTabButton(String title, String tabKey) {
    final isSelected = _selectedTab == tabKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tabKey;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFF6B756) : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
            isSelected ? Color(0xFFF6B756) : Colors.white.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // 갤러리 카드 위젯
  Widget _buildGalleryCard(GalleryItem item) {
    // 표시할 이미지 결정 (우선순위: 색칠한 이미지 > 컬러 이미지)
    String? displayImageUrl = item.coloringImageUrl ?? item.colorImageUrl;

    return GestureDetector(
      onTap: () => _showImageDetail(item),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // 메인 이미지
              if (displayImageUrl != null)
                Image.network(
                  displayImageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFF6B756),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey[600],
                          size: 40,
                        ),
                      ),
                    );
                  },
                )
              else
                Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: Icon(Icons.image, color: Colors.grey[600], size: 40),
                  ),
                ),

              // 오버레이 정보
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(8),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.storyTitle != null)
                        Text(
                          item.storyTitle!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (item.createdAt != null)
                        Text(
                          _formatDate(item.createdAt!),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 타입 인디케이터
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTypeColor(item),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getTypeText(item),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
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

  // 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  // 타입별 색상 (기존 필드 지원)
  Color _getTypeColor(GalleryItem item) {
    final isColoringWork = item.isColoringWork ?? (item.type == 'coloring');

    if (item.coloringImageUrl != null && item.colorImageUrl != null) {
      return Color(0xFF9C27B0); // 보라색 (둘 다)
    } else if (item.coloringImageUrl != null || isColoringWork) {
      return Color(0xFF4CAF50); // 녹색 (색칠)
    } else {
      return Color(0xFF2196F3); // 파란색 (컬러)
    }
  }

  // 타입별 텍스트 (기존 필드 지원)
  String _getTypeText(GalleryItem item) {
    final isColoringWork = item.isColoringWork ?? (item.type == 'coloring');

    if (item.coloringImageUrl != null && item.colorImageUrl != null) {
      return '완성';
    } else if (item.coloringImageUrl != null || isColoringWork) {
      return '색칠';
    } else {
      return '컬러';
    }
  }
}

// 🎯 수정된 갤러리 아이템 모델 (기존 구조 유지)
class GalleryItem {
  final int storyId;
  final String? storyTitle;
  final String? colorImageUrl;
  final String? coloringImageUrl;
  final DateTime? createdAt;
  final bool? isColoringWork;   // 🎯 기존 필드 유지
  final String? type;           // 🎯 새로 추가 (호환성)
  final int? coloringWorkId;    // 🎯 새로 추가

  GalleryItem({
    required this.storyId,
    this.storyTitle,
    this.colorImageUrl,
    this.coloringImageUrl,
    this.createdAt,
    this.isColoringWork,
    this.type,
    this.coloringWorkId,
  });

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    return GalleryItem(
      storyId: json['storyId'] ?? json['story_id'] ?? 0,
      storyTitle: json['storyTitle'] ?? json['story_title'],
      colorImageUrl: json['colorImageUrl'] ?? json['color_image_url'],
      coloringImageUrl: json['coloringImageUrl'] ?? json['coloring_image_url'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ??
          DateTime.tryParse(json['created_at'])
          : null,
      isColoringWork: json['isColoringWork'] ?? json['is_coloring_work'] ?? false, // 🎯 기존 필드
      type: json['type'] ?? (json['isColoringWork'] == true ? 'coloring' : 'story'), // 🎯 호환성 처리
      coloringWorkId: json['coloringWorkId'] ?? json['coloring_work_id'], // 🎯 새로 추가
    );
  }
}