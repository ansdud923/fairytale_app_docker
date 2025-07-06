// lib/contacts_screen.dart
import 'package:flutter/material.dart';

import '../../main.dart';


class ContactsScreen extends StatelessWidget {
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
                          'Contacts',
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

                // 연락처 안내
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Color(0xFF8E97FD).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF8E97FD).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Color(0xFF8E97FD),
                        size: screenWidth * 0.06,
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: Text(
                          '문의사항이 있으시면 언제든지 연락주세요!\n빠른 시간 내에 답변드리겠습니다.',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.04),

                // 연락처 목록
                _buildContactCard(
                  context,
                  icon: Icons.email,
                  title: '이메일',
                  subtitle: 'team1@donggeul.com',
                  description: '일반 문의 및 건의사항',
                  onTap: () {
                    // TODO: 이메일 앱 열기 기능 구현
                    _showContactDialog(context, '이메일', 'team1@donggeul.com');
                  },
                ),

                SizedBox(height: screenHeight * 0.02),

                _buildContactCard(
                  context,
                  icon: Icons.phone,
                  title: '전화번호',
                  subtitle: '02-1234-5678',
                  description: '긴급 문의 (평일 9시-18시)',
                  onTap: () {
                    // TODO: 전화 앱 열기 기능 구현
                    _showContactDialog(context, '전화', '02-1234-5678');
                  },
                ),

                SizedBox(height: screenHeight * 0.02),

                _buildContactCard(
                  context,
                  icon: Icons.chat,
                  title: '카카오톡',
                  subtitle: '@donggeul_official',
                  description: '실시간 채팅 상담',
                  onTap: () {
                    // TODO: 카카오톡 연결 기능 구현
                    _showContactDialog(context, '카카오톡', '@donggeul_official');
                  },
                ),

                SizedBox(height: screenHeight * 0.02),

                _buildContactCard(
                  context,
                  icon: Icons.language,
                  title: '웹사이트',
                  subtitle: 'www.donggeul.com',
                  description: 'FAQ 및 도움말',
                  onTap: () {
                    // TODO: 웹브라우저 열기 기능 구현
                    _showContactDialog(context, '웹사이트', 'www.donggeul.com');
                  },
                ),

                SizedBox(height: screenHeight * 0.04),

                // 운영시간
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5E6A3).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Color(0xFF8B5A6B),
                            size: screenWidth * 0.05,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            '운영시간',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Text(
                        '평일: 오전 9시 - 오후 6시\n주말 및 공휴일: 휴무\n\n이메일 문의는 24시간 접수 가능',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.black54,
                          height: 1.4,
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

  Widget _buildContactCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required String description,
        required VoidCallback onTap,
      }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Color(0xFFF5E6A3).withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: screenWidth * 0.12,
              height: screenWidth * 0.12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Color(0xFF8B5A6B),
                size: screenWidth * 0.06,
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
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: screenWidth * 0.038,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8E97FD),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: screenWidth * 0.032,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.black38,
              size: screenWidth * 0.04,
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context, String type, String contact) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$type 연결'),
          content: Text('$contact로 연결하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: 실제 연결 기능 구현 (url_launcher 패키지 사용)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$type 연결 기능을 준비 중입니다.'),
                    backgroundColor: Color(0xFF8E97FD),
                  ),
                );
              },
              child: Text('연결'),
            ),
          ],
        );
      },
    );
  }
}