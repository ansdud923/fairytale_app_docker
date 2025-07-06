// lib/screens/profile/support_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';

class SupportScreen extends StatelessWidget {
  // ⭐ 지원 이메일 주소
  static const String supportEmail = 'team1@donggeul.com';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BaseScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 앱바
                Container(
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
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
                          'Support',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.06),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // ⭐ 도움이 필요하신가요? 섹션
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Color(0xFF8E97FD).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.support_agent,
                            color: Color(0xFF8E97FD),
                            size: screenWidth * 0.08,
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '도움이 필요하신가요?',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '언제든지 문의해주세요!\n빠른 시간 내에 답변드리겠습니다.',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.035,
                                    color: Colors.black54,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // ⭐ 이메일 주소 표시 및 복사 기능
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xFF8E97FD).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.email,
                              color: Color(0xFF8E97FD),
                              size: screenWidth * 0.05,
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '문의 이메일',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.032,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    supportEmail,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.038,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF8E97FD),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _copyEmailToClipboard(context),
                              child: Container(
                                padding: EdgeInsets.all(screenWidth * 0.02),
                                decoration: BoxDecoration(
                                  color: Color(0xFF8E97FD),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.copy,
                                  color: Colors.white,
                                  size: screenWidth * 0.04,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.04),

                // ⭐ 자주 묻는 질문 섹션
                Text(
                  '자주 묻는 질문',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B5A6B),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                _buildFAQItem(
                  context,
                  question: '동화는 어떻게 만들어지나요?',
                  answer: 'AI 기술을 활용하여 아이의 나이와 관심사에 맞는 개인화된 동화를 생성합니다. 부모님이 입력한 정보를 바탕으로 아이만의 특별한 이야기가 만들어집니다.',
                ),

                SizedBox(height: screenHeight * 0.015),

                _buildFAQItem(
                  context,
                  question: '색칠공부는 어떻게 이용하나요?',
                  answer: '동화에 등장하는 캐릭터와 장면들을 색칠할 수 있습니다. 완성된 작품은 갤러리에 저장되며, 가족과 공유할 수 있습니다.',
                ),

                SizedBox(height: screenHeight * 0.015),

                _buildFAQItem(
                  context,
                  question: '자장가 기능은 무엇인가요?',
                  answer: '아이가 편안히 잠들 수 있도록 도와주는 수면 음악과 자장가를 제공합니다. 타이머 기능으로 일정 시간 후 자동으로 종료됩니다.',
                ),

                SizedBox(height: screenHeight * 0.015),

                _buildFAQItem(
                  context,
                  question: '기록일지는 어떤 기능인가요?',
                  answer: '아이와 함께한 동화 읽기 경험과 추억을 기록하고 공유할 수 있는 기능입니다. 사진과 함께 특별한 순간들을 저장하세요.',
                ),

                SizedBox(height: screenHeight * 0.015),

                _buildFAQItem(
                  context,
                  question: '아이 정보를 수정하려면 어떻게 하나요?',
                  answer: '프로필 화면에서 "Profile details"를 선택하시면 아이의 이름, 성별, 생년월일 정보를 수정할 수 있습니다.',
                ),

                SizedBox(height: screenHeight * 0.015),

                _buildFAQItem(
                  context,
                  question: '로그인 정보를 잊어버렸어요.',
                  answer: '소셜 로그인(카카오, 구글)을 사용하시기 때문에 해당 계정으로 다시 로그인하시면 됩니다. 문제가 지속되면 고객센터로 문의해주세요.',
                ),

                SizedBox(height: screenHeight * 0.04),

                // ⭐ 추가 문의 안내
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5E6A3).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.help_center,
                        color: Color(0xFF8B5A6B),
                        size: screenWidth * 0.08,
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Text(
                        '더 궁금한 점이 있으신가요?',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        '위 이메일로 언제든지 문의해주세요.\n자세한 답변을 드리겠습니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.black54,
                          height: 1.3,
                        ),
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
    );
  }

  Widget _buildFAQItem(BuildContext context, {
    required String question,
    required String answer,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Color(0xFFF5E6A3).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.help,
                  color: Color(0xFF8E97FD),
                  size: screenWidth * 0.05,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          Padding(
            padding: EdgeInsets.only(left: screenWidth * 0.08),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ⭐ 이메일 주소 클립보드 복사
  void _copyEmailToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: supportEmail));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('이메일 주소가 복사되었습니다!'),
          ],
        ),
        backgroundColor: Color(0xFF8E97FD),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}