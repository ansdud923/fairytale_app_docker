// lib/screens/profile/profile_details_screen.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../main.dart';
import '../service/auth_service.dart';
import '../service/api_service.dart';

class ProfileDetailsScreen extends StatefulWidget {
  @override
  _ProfileDetailsScreenState createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // 사용자 정보 (읽기 전용)
  String _userEmail = '';
  int? _userId;

  // 아이 정보 (수정 가능)
  final _childNameController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedGender = 'male';

  int? _childId;
  bool _hasChild = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ⭐ 사용자 정보와 아이 정보 불러오기
  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 1. 사용자 기본 정보
      final accessToken = await AuthService.getAccessToken();
      final userId = await AuthService.getUserId();
      final userEmail = await AuthService.getUserEmail();

      if (accessToken == null || userId == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      setState(() {
        _userId = userId;
        _userEmail = userEmail ?? 'Unknown';
      });

      // 2. 아이 정보 불러오기
      await _loadChildInfo();
    } catch (e) {
      print('❌ [ProfileDetails] 데이터 로드 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ⭐ 아이 정보 불러오기
  Future<void> _loadChildInfo() async {
    try {
      final childInfo = await AuthService.checkChildInfo();

      if (childInfo != null && childInfo['hasChild'] == true) {
        final childData = childInfo['childData'];

        setState(() {
          _hasChild = true;
          _childId = childData['id'];
          _childNameController.text = childData['name'] ?? '';

          // 날짜 파싱
          String birthDateString = childData['birthDate'] ??
              childData['baby_birth_date'] ?? '';
          if (birthDateString.isNotEmpty) {
            try {
              _selectedDate = DateTime.parse(birthDateString);
            } catch (e) {
              print('날짜 파싱 오류: $e');
            }
          }

          _selectedGender =
              childData['gender'] ?? childData['baby_gender'] ?? 'male';
        });

        print('✅ [ProfileDetails] 아이 정보 로드: ${childData['name']}');
      } else {
        setState(() {
          _hasChild = false;
          _selectedGender = 'male';
        });
        print('🔍 [ProfileDetails] 등록된 아이 정보 없음');
      }
    } catch (e) {
      print('❌ [ProfileDetails] 아이 정보 로드 오류: $e');
    }
  }

  // ⭐ 날짜 선택
  Future<void> _pickDate() async {
    DateTime initialDate = DateTime.now();

    if (_selectedDate != null) {
      initialDate = _selectedDate!;
    } else {
      initialDate = DateTime.now().subtract(Duration(days: 365)); // 1년 전
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      // 1년 후까지
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF8B5A6B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ⭐ 아이 정보 저장/업데이트
  Future<void> _saveChildInfo() async {
    if (_isSaving) return;

    // 입력 검증
    if (_childNameController.text
        .trim()
        .isEmpty) {
      _showErrorDialog('아이 이름을 입력해주세요.');
      return;
    }

    if (_selectedDate == null) {
      _showErrorDialog('아이 생년월일을 선택해주세요.');
      return;
    }

    try {
      setState(() {
        _isSaving = true;
      });

      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || _userId == null) {
        _showErrorDialog('로그인 정보가 없습니다.');
        return;
      }

      final childData = {
        'userId': _userId,
        'name': _childNameController.text.trim(),
        'gender': _selectedGender,
        'birthDate': '${_selectedDate!.year}-${_selectedDate!
            .month
            .toString()
            .padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
      };

      print('🔍 [ProfileDetails] 아이 정보 저장 요청: $childData');

      final dio = ApiService.dio;
      Response response;

      if (_hasChild && _childId != null) {
        // 기존 아이 정보 업데이트
        response = await dio.put(
          '/api/baby/$_childId',
          data: childData,
          options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
        );
        print('🔄 [ProfileDetails] 아이 정보 업데이트 API 호출');
      } else {
        // 새로운 아이 정보 생성
        response = await dio.post(
          '/api/baby',
          data: childData,
          options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
        );
        print('🆕 [ProfileDetails] 새 아이 정보 생성 API 호출');
      }

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          // 성공 시 로컬 상태 업데이트
          if (!_hasChild) {
            setState(() {
              _hasChild = true;
              _childId = responseData['data']['id'];
            });
          }

          print('✅ [ProfileDetails] 아이 정보 저장 성공');
          _showSuccessDialog();
        } else {
          _showErrorDialog(responseData['message'] ?? '저장에 실패했습니다.');
        }
      } else {
        _showErrorDialog('서버 오류가 발생했습니다.');
      }
    } catch (e) {
      print('❌ [ProfileDetails] 아이 정보 저장 오류: $e');

      if (e is DioException) {
        if (e.response?.statusCode == 403) {
          _showErrorDialog('로그인이 만료되었습니다. 다시 로그인해주세요.');
          await AuthService.logout();
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
          return;
        } else if (e.response?.statusCode == 400) {
          _showErrorDialog('입력 정보를 확인해주세요.');
        } else {
          _showErrorDialog('네트워크 오류가 발생했습니다.');
        }
      } else {
        _showErrorDialog('저장 중 오류가 발생했습니다.');
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // ⭐ 성공 다이얼로그
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('저장 완료'),
          content: Text('아이 정보가 성공적으로 저장되었습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 다이얼로그 닫기
                Navigator.pop(context, true); // 프로필 화면으로 돌아가기
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  // ⭐ 에러 다이얼로그
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('오류'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _childNameController.dispose();
    super.dispose();
  }

  // 🎯 단일 build 메서드 (배경 이미지 포함)
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
    final keyboardHeight = MediaQuery
        .of(context)
        .viewInsets
        .bottom;

    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/bg_image.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF8B5A6B)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '정보를 불러오는 중...',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 고정 배경 이미지
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/bg_image.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // 메인 컨텐츠
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: keyboardHeight),
                child: Column(
                  children: [
                    // 헤더
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.02,
                        vertical: screenHeight * 0.01,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                                Icons.arrow_back, color: Color(0xFF8B5A6B)),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              _hasChild ? '아이 정보 수정' : '아이 정보 등록',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8B5A6B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),

                    // 스크롤 컨텐츠
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.06),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: screenHeight * 0.02),

                            // 사용자 정보
                            Container(
                              padding: EdgeInsets.all(screenWidth * 0.03),
                              decoration: BoxDecoration(
                                color: Color(0xFFFFE7B0).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Color(0xFFECA666), width: 1),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: Color(0xFF8B5A6B),
                                    size: screenWidth * 0.05,
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start,
                                    children: [
                                      Text(
                                        '부모님 정보',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.035,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF8B5A6B),
                                        ),
                                      ),
                                      Text(
                                        _userEmail,
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.035,
                                          color: Color(0xFF8B5A6B).withOpacity(
                                              0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.03),

                            // 안내 텍스트
                            Container(
                              padding: EdgeInsets.all(screenWidth * 0.03),
                              decoration: BoxDecoration(
                                color: Color(0xFFFFE7B0).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Color(0xFFECA666), width: 1),
                              ),
                              child: Text(
                                _hasChild
                                    ? '우리 아이의 정보를 수정해보세요! ✏️✨'
                                    : '우리 아이만을 위한 특별한 동화를 만들어드려요! 📚✨\n아이의 정보를 입력해주세요.',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  color: Color(0xFF8B5A6B),
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.03),

                            // 이름 입력
                            Text(
                              '아이 이름 (태명)',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8B5A6B),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            TextField(
                              controller: _childNameController,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.done,
                              maxLength: 20,
                              buildCounter: (context,
                                  {required currentLength, required isFocused, maxLength}) {
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: '아이의 이름(태명)을 입력해 주세요',
                                hintStyle: TextStyle(color: Colors.grey[600]),
                                fillColor: Color(0xFFFFE7B0),
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                      color: Color(0xFF8B5A6B), width: 2),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                  vertical: screenHeight * 0.015,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: Colors.black87,
                              ),
                              cursorColor: Color(0xFF8B5A6B),
                            ),

                            SizedBox(height: screenHeight * 0.025),

                            // 성별 선택
                            Text(
                              '성별',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8B5A6B),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() =>
                                        _selectedGender = 'male'),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: screenHeight * 0.015),
                                      decoration: BoxDecoration(
                                        color: _selectedGender == 'male'
                                            ? Color(0xFF8B5A6B)
                                            : Color(0xFFFFE7B0),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _selectedGender == 'male'
                                              ? Color(0xFF8B5A6B)
                                              : Color(0xFFECA666),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .center,
                                        children: [
                                          Text(
                                            '👦',
                                            style: TextStyle(
                                                fontSize: screenWidth * 0.05),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            '남아',
                                            style: TextStyle(
                                              color: _selectedGender == 'male'
                                                  ? Colors.white
                                                  : Color(0xFF8B5A6B),
                                              fontWeight: FontWeight.w500,
                                              fontSize: screenWidth * 0.035,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() =>
                                        _selectedGender = 'female'),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: screenHeight * 0.015),
                                      decoration: BoxDecoration(
                                        color: _selectedGender == 'female'
                                            ? Color(0xFF8B5A6B)
                                            : Color(0xFFFFE7B0),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _selectedGender == 'female'
                                              ? Color(0xFF8B5A6B)
                                              : Color(0xFFECA666),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .center,
                                        children: [
                                          Text(
                                            '👧',
                                            style: TextStyle(
                                                fontSize: screenWidth * 0.05),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            '여아',
                                            style: TextStyle(
                                              color: _selectedGender == 'female'
                                                  ? Colors.white
                                                  : Color(0xFF8B5A6B),
                                              fontWeight: FontWeight.w500,
                                              fontSize: screenWidth * 0.035,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: screenHeight * 0.025),

                            // 생일 선택
                            Text(
                              '생일 (출산 예정일)',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8B5A6B),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                height: screenHeight * 0.06,
                                padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.04),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFFE7B0),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Color(0xFFECA666), width: 1),
                                ),
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: Color(0xFF8B5A6B),
                                      size: screenWidth * 0.05,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _selectedDate != null
                                            ? '${_selectedDate!
                                            .year}-${_selectedDate!.month
                                            .toString().padLeft(
                                            2, '0')}-${_selectedDate!.day
                                            .toString().padLeft(2, '0')}'
                                            : '아이의 생일(출산 예정일)을 입력해 주세요',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.035,
                                          color: _selectedDate != null ? Color(
                                              0xFF3B2D2C) : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 키보드 공간
                            SizedBox(
                                height: keyboardHeight > 0 ? keyboardHeight +
                                    100 : screenHeight * 0.05),
                          ],
                        ),
                      ),
                    ),

                    // 저장 버튼
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.06),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveChildInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF8B5A6B),
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity,
                              screenHeight * 0.06),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          textStyle: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: _isSaving
                            ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        )
                            : Text(_hasChild ? '정보 수정하기' : '정보 등록하기'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}