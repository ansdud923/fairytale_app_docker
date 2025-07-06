// lib/screens/profile/profile_screen.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../main.dart';
import '../service/auth_service.dart';
import '../service/api_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isUploading = false; // 이미지 업로드 중 상태
  String _profileImagePath = 'assets/myphoto.png';
  String? _profileImageUrl; // 서버에서 받은 프로필 이미지 URL
  String _userName = '로딩 중...';
  String _userEmail = '로딩 중...';
  int? _userId;
  Map<String, dynamic>? _childData;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ⭐ 실제 DB에서 사용자 데이터 불러오기
  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 1. AuthService에서 기본 정보 가져오기
      final accessToken = await AuthService.getAccessToken();
      final userId = await AuthService.getUserId();
      final userEmail = await AuthService.getUserEmail();

      if (accessToken == null || userId == null) {
        print('❌ [ProfileScreen] 로그인 정보 없음');
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      setState(() {
        _userId = userId;
        _userEmail = userEmail ?? 'Unknown';
      });

      print('🔍 [ProfileScreen] 사용자 정보 로드: userId=$userId, email=$userEmail');

      // 2. 서버에서 상세 사용자 정보 가져오기 (선택사항)
      await _fetchUserProfileFromServer(accessToken, userId);

      // 3. 아이 정보도 함께 로드
      await _loadChildInfo();

    } catch (e) {
      print('❌ [ProfileScreen] 사용자 데이터 로드 오류: $e');
      // 기본값 설정
      setState(() {
        _userName = '사용자';
        _userEmail = _userEmail ?? 'Unknown';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// ⭐ 서버에서 사용자 프로필 정보 가져오기 (실제 DB 연동)
  Future<void> _fetchUserProfileFromServer(String accessToken, int userId) async {
    try {
      final dio = ApiService.dio;

      // ✅ 실제 사용자 프로필 API 호출
      final response = await dio.get(
        '/api/user/profile/$userId',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          final userData = responseData['user'];

          setState(() {
            _userName = userData['username'] ?? userData['email']?.split('@')[0] ?? '사용자';
            _userEmail = userData['email'] ?? _userEmail;
            _profileImageUrl = userData['profileImageUrl']; // ✅ 서버에서 프로필 이미지 URL 복원
          });

          print('✅ [ProfileScreen] 서버에서 프로필 정보 로드 성공');
          print('✅ [ProfileScreen] 프로필 이미지 URL: $_profileImageUrl');

          return;
        }
      }

      // API 호출 실패 시 기본값 설정
      if (_userEmail.isNotEmpty && _userEmail != 'Unknown') {
        final emailParts = _userEmail.split('@');
        setState(() {
          _userName = emailParts.isNotEmpty ? emailParts[0] : '사용자';
        });
      } else {
        setState(() {
          _userName = '사용자 #$userId';
        });
      }

    } catch (e) {
      print('❌ [ProfileScreen] 서버 프로필 조회 오류: $e');

      // 에러 시 기본값 설정
      setState(() {
        _userName = '사용자 #$userId';
      });
    }
  }


  // ⭐ 아이 정보 로드
  Future<void> _loadChildInfo() async {
    try {
      final childInfo = await AuthService.checkChildInfo();
      if (childInfo != null && childInfo['hasChild'] == true) {
        setState(() {
          _childData = childInfo['childData'];
        });
        print('✅ [ProfileScreen] 아이 정보 로드: ${_childData?['name']}');
      }
    } catch (e) {
      print('❌ [ProfileScreen] 아이 정보 로드 오류: $e');
    }
  }

// ⭐ 이미지 선택 및 업로드 (카메라) - 플랫폼 체크 추가
  Future<void> _pickImageFromCamera() async {
    try {
      // macOS에서는 카메라 기능 제한
      if (Platform.isMacOS) {
        _showErrorSnackBar('macOS에서는 카메라 기능이 지원되지 않습니다. 갤러리를 이용해주세요.');
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadProfileImage(File(image.path));
      }
    } catch (e) {
      print('❌ [ProfileScreen] 카메라 이미지 선택 오류: $e');
      if (e.toString().contains('cameraDelegate')) {
        _showErrorSnackBar('이 플랫폼에서는 카메라 기능이 지원되지 않습니다. 갤러리를 이용해주세요.');
      } else {
        _showErrorSnackBar('카메라에서 이미지를 가져오는데 실패했습니다.');
      }
    }
  }

// ⭐ 이미지 선택 및 업로드 (갤러리)
  Future<void> _pickImageFromGallery() async {
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      // 데스크톱 파일 선택 창 열기
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        await _uploadProfileImage(file);
      }
    } else {
      // 모바일(기존 image_picker 사용)
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        await _uploadProfileImage(File(image.path));
      }
    }
  }
// ⭐ 프로필 이미지 업로드 프로세스 (인증 오류 처리 포함)
// ProfileScreen에서 기존 _uploadProfileImage 메서드를 이것으로 교체하세요

  Future<void> _uploadProfileImage(File imageFile) async {
    if (_userId == null) {
      _showErrorSnackBar('사용자 정보를 찾을 수 없습니다.');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      print('🎯 [ProfileScreen] 프로필 이미지 업로드 시작');

      // 업로드 진행 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E97FD)),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Text('프로필 이미지를 업로드하는 중...'),
              ),
            ],
          ),
        ),
      );

      // ApiService를 통해 업로드
      final result = await ApiService.uploadProfileImage(
        userId: _userId!,
        imageFile: imageFile,
      );

      // 다이얼로그 닫기
      Navigator.of(context).pop();

      if (result?['success'] == true) {
        // 업로드 성공
        setState(() {
          _profileImageUrl = result?['profileImageUrl'];
        });

        print('✅ [ProfileScreen] 프로필 이미지 업로드 성공: $_profileImageUrl');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 이미지가 성공적으로 업데이트되었습니다!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // 프로필 데이터 새로고침
        await _refreshData();

      } else {
        // 업로드 실패 - 인증 오류 확인
        final errorMessage = result?['error'] ?? '알 수 없는 오류가 발생했습니다.';
        final needLogin = result?['needLogin'] ?? false;

        print('❌ [ProfileScreen] 프로필 이미지 업로드 실패: $errorMessage');

        if (needLogin) {
          // 인증 만료 - 로그인 화면으로 이동
          _showAuthExpiredDialog();
        } else {
          _showErrorSnackBar('업로드 실패: $errorMessage');
        }
      }

    } catch (e) {
      // 다이얼로그가 열려있다면 닫기
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('❌ [ProfileScreen] 프로필 이미지 업로드 오류: $e');
      _showErrorSnackBar('이미지 업로드 중 오류가 발생했습니다.');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

// ⭐ 인증 만료 다이얼로그 (ProfileScreen에 추가)
  void _showAuthExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('인증 만료'),
          content: Text('로그인이 만료되었습니다. 다시 로그인해주세요.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 로그인 화면으로 이동
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                      (route) => false,
                );
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  // ⭐ 에러 스낵바 표시
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // ⭐ AuthService를 사용한 로그아웃 함수
  Future<void> _logout() async {
    try {
      // 로그아웃 확인 다이얼로그
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('로그아웃'),
            content: Text('정말 로그아웃 하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('로그아웃'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          );
        },
      );

      if (shouldLogout != true) return;

      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E97FD)),
          ),
        ),
      );

      // 1. 서버에 로그아웃 요청 (선택사항)
      final accessToken = await AuthService.getAccessToken();
      if (accessToken != null) {
        try {
          final dio = ApiService.dio;
          await dio.post(
            '/oauth/logout',
            options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
          );
          print('✅ [ProfileScreen] 서버 로그아웃 성공');
        } catch (e) {
          print('⚠️ [ProfileScreen] 서버 로그아웃 실패 (계속 진행): $e');
        }
      }

      // 2. 로컬 토큰 삭제
      await AuthService.logout();

      // 로딩 다이얼로그 닫기
      Navigator.pop(context);

      // 3. 로그인 화면으로 이동
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false,
      );

    } catch (e) {
      print('❌ [ProfileScreen] 로그아웃 오류: $e');

      // 로딩 다이얼로그가 열려있다면 닫기
      Navigator.of(context, rootNavigator: true).pop();

      // 오류가 발생해도 로컬 토큰은 삭제하고 로그인 화면으로 이동
      await AuthService.logout();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false,
      );
    }
  }

  // ⭐ 새로고침 기능
  Future<void> _refreshData() async {
    await _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return BaseScaffold(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E97FD)),
                ),
                SizedBox(height: 16),
                Text(
                  '프로필 정보를 불러오는 중...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return BaseScaffold(
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: Color(0xFF8E97FD),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                children: [
                  // 상단 앱바
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: screenHeight * 0.02
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
                            'Profile',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _refreshData,
                          child: Icon(
                            Icons.refresh,
                            color: Colors.black54,
                            size: screenWidth * 0.06,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // 프로필 이미지와 정보
                  Column(
                    children: [
                      // 프로필 이미지
                      Stack(
                        children: [
                          Container(
                            width: screenWidth * 0.3,
                            height: screenWidth * 0.3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Color(0xFFECA666),
                                width: 2.0,
                              ),
                            ),
                            child: ClipOval(
                              child: Container(
                                width: screenWidth * 0.3,
                                height: screenWidth * 0.3,
                                child: _profileImageUrl != null
                                    ? Image.network(
                                  _profileImageUrl!,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                            : null,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E97FD)),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    print('❌ [ProfileScreen] 프로필 이미지 로드 실패: $error');
                                    return Image.asset(
                                      _profileImagePath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Color(0xFFFDB5A6),
                                          child: Center(
                                            child: Text(
                                              '👤',
                                              style: TextStyle(fontSize: screenWidth * 0.1),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                )
                                    : Image.asset(
                                  _profileImagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Color(0xFFFDB5A6),
                                      child: Center(
                                        child: Text(
                                          '👤',
                                          style: TextStyle(fontSize: screenWidth * 0.1),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _isUploading ? null : () {
                                _showImagePickerDialog(context);
                              },
                              child: Container(
                                width: screenWidth * 0.09,
                                height: screenWidth * 0.09,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isUploading
                                      ? Colors.grey
                                      : Color(0xFF8B5A6B),
                                ),
                                child: _isUploading
                                    ? Padding(
                                  padding: EdgeInsets.all(screenWidth * 0.015),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                                    : Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: screenWidth * 0.045,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.025),

                      // 사용자 정보
                      Column(
                        children: [
                          // ⭐ 아이 이름 우선 표시, 없으면 사용자 이름
                          Text(
                            _childData != null ? _childData!['name'] : _userName,
                            style: TextStyle(
                              fontSize: screenWidth * 0.06,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.01),

                          // ⭐ 아이가 있으면 부모님 표시, 없으면 이메일 표시
                          if (_childData != null) ...[
                            Text(
                              '${_childData!['name']}의 부모님',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color: Colors.black54,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            Text(
                              _userEmail,
                              style: TextStyle(
                                fontSize: screenWidth * 0.032,
                                color: Colors.black38,
                              ),
                            ),
                          ] else ...[
                            Text(
                              _userEmail,
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: Colors.black54,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                                vertical: screenHeight * 0.008,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '아이 정보를 등록해주세요',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.032,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // 메뉴 리스트
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          context,
                          icon: Icons.person,
                          title: _childData != null ? '아이 정보 수정' : '아이 정보 등록',
                          subtitle: _childData != null
                              ? '${_childData!['name']} 정보 수정'
                              : '아이 정보를 등록해주세요',
                          onTap: () async {
                            final result = await Navigator.pushNamed(context, '/profile-details');
                            if (result == true) {
                              _refreshData();
                            }
                          },
                        ),

                        SizedBox(height: screenHeight * 0.015),

                        _buildMenuItem(
                          context,
                          icon: Icons.settings,
                          title: 'Settings',
                          onTap: () {
                            Navigator.pushNamed(context, '/settings');
                          },
                        ),

                        SizedBox(height: screenHeight * 0.015),

                        _buildMenuItem(
                          context,
                          icon: Icons.contact_support,
                          title: 'Contacts',
                          onTap: () {
                            Navigator.pushNamed(context, '/contacts');
                          },
                        ),

                        SizedBox(height: screenHeight * 0.015),

                        _buildMenuItem(
                          context,
                          icon: Icons.help_outline,
                          title: 'Support',
                          onTap: () {
                            Navigator.pushNamed(context, '/support');
                          },
                        ),

                        SizedBox(height: screenHeight * 0.015),

                        _buildMenuItem(
                          context,
                          icon: Icons.logout,
                          title: 'Logout',
                          onTap: _logout,
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        String? subtitle,
        required VoidCallback onTap,
        bool isDestructive = false,
      }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.02
        ),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.1)
              : Color(0xFFF5E6A3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: screenWidth * 0.1,
              height: screenWidth * 0.1,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.7),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : Color(0xFF8B5A6B),
                size: screenWidth * 0.05,
              ),
            ),

            SizedBox(width: screenWidth * 0.04),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red : Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        color: isDestructive ? Colors.red.shade300 : Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              color: isDestructive ? Colors.red : Colors.black38,
              size: screenWidth * 0.04,
            ),
          ],
        ),
      ),
    );
  }

// ⭐ 이미지 선택 다이얼로그 (플랫폼별 옵션 조정)
  void _showImagePickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('프로필 사진 변경'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 카메라 옵션 (모바일에서만 표시)
              if (!Platform.isMacOS) ...[
                ListTile(
                  leading: Icon(Icons.camera_alt, color: Color(0xFF8E97FD)),
                  title: Text('카메라로 촬영'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera();
                  },
                ),
              ],
              // 갤러리 옵션 (모든 플랫폼)
              ListTile(
                leading: Icon(Icons.photo_library, color: Color(0xFF8E97FD)),
                title: Text(Platform.isMacOS ? '파일에서 선택' : '갤러리에서 선택'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              // 프로필 사진 삭제 옵션
              if (_profileImageUrl != null) ...[
                Divider(),
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('프로필 사진 삭제'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfileImage();
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '취소',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  // ⭐ 프로필 이미지 삭제 (선택사항)
  Future<void> _removeProfileImage() async {
    try {
      final shouldRemove = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('프로필 사진 삭제'),
            content: Text('프로필 사진을 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  '삭제',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );

      if (shouldRemove == true) {
        setState(() {
          _profileImageUrl = null;
        });

        // TODO: 서버에서도 프로필 이미지 삭제 API 호출
        // await ApiService.removeProfileImage(userId: _userId!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 사진이 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ [ProfileScreen] 프로필 이미지 삭제 오류: $e');
      _showErrorSnackBar('프로필 사진 삭제 중 오류가 발생했습니다.');
    }
  }
}