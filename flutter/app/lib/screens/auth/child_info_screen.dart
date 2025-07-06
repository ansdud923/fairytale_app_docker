// lib/screens/auth/child_info_screen.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../main.dart';
import '../service/auth_service.dart';
import '../service/api_service.dart';


class ChildInfoScreen extends StatefulWidget {
  @override
  _ChildInfoScreenState createState() => _ChildInfoScreenState();
}

class _ChildInfoScreenState extends State<ChildInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedGender = 'unknown';
  bool _isLoading = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1), // 출산 예정일도 고려
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

  // ✅ 아이 정보를 서버에 저장
  Future<bool> _saveChildInfo() async {
    if (_nameController.text.trim().isEmpty || _selectedDate == null) {
      _showErrorDialog('아이의 이름과 생일을 모두 입력해주세요.');
      return false;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final accessToken = await AuthService.getAccessToken();
      final userId = await AuthService.getUserId();

      if (accessToken == null || userId == null) {
        _showErrorDialog('로그인 정보가 없습니다. 다시 로그인해주세요.');
        return false;
      }

      final response = await ApiService.dio.post(
        '/api/baby',
        data: {
          'userId': userId,
          'name': _nameController.text.trim(),
          'gender': _selectedGender,
          'birthDate': '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      print('아이 정보 저장 응답: ${response.data}');

      if (response.data['success'] == true) {
        print('아이 정보 저장 성공!');

        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('아이 정보가 저장되었습니다! 🎉'),
            backgroundColor: Color(0xFF8B5A6B),
          ),
        );

        return true;
      }
      return false;
    } catch (e) {
      print('아이 정보 저장 오류: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          _showErrorDialog('로그인이 만료되었습니다. 다시 로그인해주세요.');
          // 로그인 화면으로 이동
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          return false;
        }
      }
      _showErrorDialog('아이 정보 저장에 실패했습니다. 다시 시도해주세요.');
      return false;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('알림'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showBackDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('뒤로 가기'),
        content: const Text('아이 정보를 입력하지 않고 나가시겠습니까?\n로그아웃됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Text('나가기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BaseScaffold(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 헤더
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF8B5A6B)),
                    onPressed: () {
                      // 뒤로가기 시 로그아웃 후 로그인 화면으로
                      _showBackDialog();
                    },
                  ),
                  Expanded(
                    child: Text(
                      '아이 정보 입력',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5A6B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // 균형 맞추기
                ],
              ),

              SizedBox(height: screenHeight * 0.04),

              // 안내 텍스트
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Color(0xFFFFE7B0).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFECA666), width: 1),
                ),
                child: Text(
                  '우리 아이만을 위한 특별한 동화를 만들어드려요! 📚✨\n아이의 정보를 입력해주세요.',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Color(0xFF8B5A6B),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: screenHeight * 0.04),

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
                controller: _nameController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                maxLength: 20, // 최대 글자 수 제한
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                  return null; // 글자 수 카운터 숨김
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
                    borderSide: BorderSide(color: Color(0xFF8B5A6B), width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.02,
                  ),
                ),
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: Colors.black87,
                ),
                cursorColor: Color(0xFF8B5A6B),
              ),

              SizedBox(height: screenHeight * 0.03),

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
                      onTap: () => setState(() => _selectedGender = 'male'),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '👦',
                              style: TextStyle(fontSize: screenWidth * 0.05),
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
                      onTap: () => setState(() => _selectedGender = 'female'),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '👧',
                              style: TextStyle(fontSize: screenWidth * 0.05),
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
                  SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedGender = 'unknown'),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                        decoration: BoxDecoration(
                          color: _selectedGender == 'unknown'
                              ? Color(0xFF8B5A6B)
                              : Color(0xFFFFE7B0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedGender == 'unknown'
                                ? Color(0xFF8B5A6B)
                                : Color(0xFFECA666),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '👶',
                              style: TextStyle(fontSize: screenWidth * 0.05),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '모름',
                              style: TextStyle(
                                color: _selectedGender == 'unknown'
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

              SizedBox(height: screenHeight * 0.03),

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
                  height: screenHeight * 0.07,
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFE7B0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFECA666), width: 1),
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
                              ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                              : '아이의 생일(출산 예정일)을 입력해 주세요',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: _selectedDate != null ? Color(0xFF3B2D2C) : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Spacer(),

              // 저장 버튼
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                  final success = await _saveChildInfo();
                  if (success) {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8B5A6B),
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, screenHeight * 0.06),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  textStyle: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text('저장하고 시작하기'),
              ),

              SizedBox(height: screenHeight * 0.015),

              // 건너뛰기 버튼
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: Text(
                  '나중에 입력하기',
                  style: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: screenWidth * 0.035,
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