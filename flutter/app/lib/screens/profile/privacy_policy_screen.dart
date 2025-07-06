// lib/screens/profile/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../main.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  @override
  _PrivacyPolicyScreenState createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadHtmlString(_getPrivacyPolicyHtml());
  }

  String _getPrivacyPolicyHtml() {
    return '''
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>개인정보 처리방침</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 20px;
            line-height: 1.6;
            color: #333;
            background-color: #f8f9fa;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background-color: white;
            border-radius: 12px;
            padding: 24px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #8B5A6B;
            text-align: center;
            margin-bottom: 30px;
            font-size: 24px;
        }
        h2 {
            color: #8B5A6B;
            margin-top: 30px;
            margin-bottom: 15px;
            font-size: 18px;
            border-bottom: 2px solid #FFE7B0;
            padding-bottom: 8px;
        }
        h3 {
            color: #6B4E57;
            margin-top: 20px;
            margin-bottom: 10px;
            font-size: 16px;
        }
        p {
            margin-bottom: 12px;
            font-size: 14px;
        }
        ul, ol {
            margin: 10px 0;
            padding-left: 20px;
        }
        li {
            margin-bottom: 8px;
            font-size: 14px;
        }
        a {
            color: #8B5A6B;
            text-decoration: none;
            border-bottom: 1px solid #8B5A6B;
        }
        a:hover {
            background-color: #FFE7B0;
        }
        
        /* 🆕 링크 버튼 스타일 */
        .reference-links {
            display: flex;
            flex-direction: column;
            gap: 12px;
            margin: 20px 0;
        }
        
        .link-button {
            display: flex;
            align-items: center;
            padding: 16px;
            background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
            border: 2px solid #dee2e6;
            border-radius: 12px;
            text-decoration: none;
            color: inherit;
            transition: all 0.3s ease;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .link-button:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            background: linear-gradient(135deg, #FFE7B0 0%, #FFDB8B 100%);
            border-color: #8B5A6B;
        }
        
        .link-button.kakao:hover {
            background: linear-gradient(135deg, #FEE500 0%, #FFEB3B 100%);
            border-color: #FBC02D;
        }
        
        .link-button.google:hover {
            background: linear-gradient(135deg, #E3F2FD 0%, #BBDEFB 100%);
            border-color: #1976D2;
        }
        
        .link-icon {
            font-size: 24px;
            margin-right: 16px;
            min-width: 40px;
            text-align: center;
        }
        
        .link-content {
            flex: 1;
        }
        
        .link-title {
            font-size: 16px;
            font-weight: 600;
            color: #333;
            margin-bottom: 4px;
        }
        
        .link-desc {
            font-size: 13px;
            color: #666;
            line-height: 1.4;
        }
        .highlight {
            background-color: #FFE7B0;
            padding: 15px;
            border-radius: 8px;
            margin: 15px 0;
            border-left: 4px solid #8B5A6B;
        }
        .contact-info {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
        }
        .effective-date {
            text-align: center;
            font-style: italic;
            color: #666;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>개인정보 처리방침</h1>
        
        <div class="highlight">
            <strong>엄빠, 읽어도!</strong>는 사용자의 개인정보 보호를 위해 최선을 다하고 있으며, 
            개인정보보호법에 따라 다음과 같이 개인정보 처리방침을 공개합니다.
        </div>

        <h2>1. 개인정보의 처리 목적</h2>
        <p>당사는 다음의 목적을 위하여 개인정보를 처리합니다:</p>
        <ul>
            <li><strong>회원 가입 및 관리:</strong> 회원 식별, 서비스 이용 의사 확인</li>
            <li><strong>서비스 제공:</strong> 맞춤형 동화 생성, 색칠공부 템플릿 제공</li>
            <li><strong>고객 지원:</strong> 문의 응답, 서비스 개선을 위한 피드백 수집</li>
            <li><strong>마케팅 및 광고:</strong> 이벤트 정보 제공 (동의 시에만)</li>
        </ul>

        <h2>2. 처리하는 개인정보 항목</h2>
        <h3>2-1. 필수 정보</h3>
        <ul>
            <li>소셜 로그인 정보 (카카오, 구글)</li>
            <li>이메일 주소, 닉네임</li>
            <li>아이 정보 (이름, 생년월일) - 서비스 이용을 위해 필요</li>
        </ul>
        
        <h3>2-2. 자동 수집 정보</h3>
        <ul>
            <li>IP 주소, 기기 정보</li>
            <li>서비스 이용 기록, 접속 로그</li>
            <li>쿠키, 세션 정보</li>
        </ul>

        <h2>3. 개인정보의 처리 및 보유 기간</h2>
        <ul>
            <li><strong>회원 정보:</strong> 회원 탈퇴 시까지</li>
            <li><strong>생성된 콘텐츠:</strong> 회원 탈퇴 후 30일까지 (복구 요청 대비)</li>
            <li><strong>접속 로그:</strong> 3개월</li>
            <li><strong>고객 지원 기록:</strong> 3년</li>
        </ul>

        <h2>4. 개인정보의 제3자 제공</h2>
        <p>당사는 원칙적으로 이용자의 개인정보를 외부에 제공하지 않습니다. 
        다만, 다음의 경우에는 예외로 합니다:</p>
        <ul>
            <li>이용자가 사전에 동의한 경우</li>
            <li>법령의 규정에 의거하거나, 수사 목적으로 법령에 정해진 절차와 방법에 따라 
                수사기관의 요구가 있는 경우</li>
        </ul>

        <h2>5. 개인정보 처리의 위탁</h2>
        <p>서비스 향상을 위해 다음과 같이 개인정보 처리를 위탁하고 있습니다:</p>
        <ul>
            <li><strong>AWS (Amazon Web Services):</strong> 서버 호스팅, 데이터 저장</li>
            <li><strong>OpenAI:</strong> 동화 생성 서비스</li>
            <li><strong>Google Analytics:</strong> 서비스 이용 통계 분석</li>
        </ul>

        <h2>6. 이용자의 권리·의무 및 행사방법</h2>
        <p>이용자는 개인정보주체로서 다음과 같은 권리를 행사할 수 있습니다:</p>
        <ul>
            <li>개인정보 처리정지 요구권</li>
            <li>개인정보 열람요구권</li>
            <li>개인정보 정정·삭제요구권</li>
            <li>개인정보 처리정지 요구권</li>
        </ul>

        <h2>7. 개인정보의 안전성 확보 조치</h2>
        <ul>
            <li><strong>관리적 조치:</strong> 개인정보 취급 직원의 최소화 및 교육</li>
            <li><strong>기술적 조치:</strong> 개인정보 암호화, 접근통제시스템 설치</li>
            <li><strong>물리적 조치:</strong> 전산실, 자료보관실 등의 접근통제</li>
        </ul>

        <h2>8. 개인정보보호책임자</h2>
        <div class="contact-info">
            <p><strong>개인정보보호책임자:</strong> 1조 팀장</p>
            <p><strong>연락처:</strong> privacy@fairytale-app.com</p>
            <p><strong>전화:</strong> 02-1234-5678</p>
            <p>개인정보 처리에 관한 문의사항이 있으시면 언제든지 연락주시기 바랍니다.</p>
        </div>

        <h2>9. 참고 링크</h2>
        <div class="reference-links">
            <a href="https://cs.kakao.com/helps?category=29&service=8" target="_blank" class="link-button kakao">
                <div class="link-icon">🔗</div>
                <div class="link-content">
                    <div class="link-title">카카오 개인정보처리방침</div>
                    <div class="link-desc">카카오 공식 개인정보 정책</div>
                </div>
            </a>
            
            <a href="https://developers.kakao.com/docs/latest/ko/kakaologin/rest-api#req-user-info" target="_blank" class="link-button kakao">
                <div class="link-icon">📋</div>
                <div class="link-content">
                    <div class="link-title">카카오 개발자 API 문서</div>
                    <div class="link-desc">사용자 정보 API 가이드</div>
                </div>
            </a>
            
            <a href="https://policies.google.com/privacy?hl=ko" target="_blank" class="link-button google">
                <div class="link-icon">🔗</div>
                <div class="link-content">
                    <div class="link-title">구글 개인정보처리방침</div>
                    <div class="link-desc">구글 공식 개인정보 정책</div>
                </div>
            </a>
            
            <a href="https://developers.google.com/identity/protocols/oauth2" target="_blank" class="link-button google">
                <div class="link-icon">📋</div>
                <div class="link-content">
                    <div class="link-title">구글 OAuth 문서</div>
                    <div class="link-desc">OAuth 2.0 가이드</div>
                </div>
            </a>
        </div>

        <div class="effective-date">
            <p>본 개인정보 처리방침은 2024년 6월 17일부터 적용됩니다.</p>
        </div>
    </div>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return BaseScaffold(
      child: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF8B5A6B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      '개인정보 처리방침',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5A6B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // 균형 맞추기
                ],
              ),
            ),

            // 웹뷰 영역
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoading)
                    Container(
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5A6B)),
                            ),
                            SizedBox(height: 16),
                            Text(
                              '개인정보 처리방침을 불러오는 중...',
                              style: TextStyle(
                                color: Color(0xFF8B5A6B),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}