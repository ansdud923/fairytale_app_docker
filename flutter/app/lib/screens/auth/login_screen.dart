import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import '../../main.dart';
import '../service/api_service.dart';
import '../service/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // ✅ 플랫폼별 카카오 로그인 (macOS는 웹 로그인)
  Future<String?> _loginWithKakao() async {
    try {
      print('🔍 카카오 로그인 시작 - 플랫폼: ${Platform.operatingSystem}');

      // ⭐ macOS에서는 웹 기반 로그인 사용
      if (Platform.isMacOS) {
        print('🔍 macOS 감지 - 웹 기반 카카오 로그인 사용');
        return await _loginWithKakaoWeb();
      }

      // Android/iOS는 기존 SDK 사용
      bool isInstalled = await isKakaoTalkInstalled();
      OAuthToken token;

      if (isInstalled) {
        try {
          print('🔍 카카오톡 앱으로 로그인 시도');
          token = await UserApi.instance.loginWithKakaoTalk();
        } catch (e) {
          print('🔍 카카오톡 로그인 실패, 웹 로그인으로 전환: $e');
          // 카카오톡 로그인 실패 시 웹 로그인으로 fallback
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        print('🔍 카카오 계정으로 로그인');
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      print('✅ 카카오 토큰 획득: ${token.accessToken.substring(0, 20)}...');
      return token.accessToken;
    } catch (e) {
      print('❌ 카카오 로그인 오류: $e');

      // ⭐ SDK 에러인 경우 macOS에서는 웹 로그인으로 fallback
      if (Platform.isMacOS && e.toString().contains('MissingPluginException')) {
        print('🔄 macOS에서 SDK 오류 발생, 웹 로그인으로 전환');
        return await _loginWithKakaoWeb();
      }

      return null;
    }
  }

  // 🆕 macOS용 웹 기반 카카오 로그인 (REST API 키 사용)
  Future<String?> _loginWithKakaoWeb() async {
    try {
      print('🔍 macOS 웹 기반 카카오 로그인 시작');

      // ⭐ 다른 포트 사용 (8080은 백엔드 서버가 사용 중)
      final server = await HttpServer.bind('localhost', 8081);
      print('✅ 로컬 서버 시작: http://localhost:8081');

      // ⭐ 카카오 개발자 콘솔에 등록된 설정 사용
      const clientId = '9b0881fcab5b67f9f17c9dd43b08fb7a'; // JavaScript 키
      const redirectUri =
          'http://localhost:8081/auth/kakao/callback'; // 콘솔에 등록된 URI

      final loginUrl =
          'https://kauth.kakao.com/oauth/authorize?'
          'client_id=$clientId&'
          'redirect_uri=${Uri.encodeComponent(redirectUri)}&'
          'response_type=code';

      print('🔍 카카오 로그인 URL: $loginUrl');
      print('🔍 사용 중인 Client ID: $clientId');

      // 시스템 브라우저로 로그인 URL 열기
      if (Platform.isMacOS) {
        await Process.run('open', [loginUrl]);
      }

      String? accessToken;

      // 서버에서 콜백 대기 (최대 5분)
      await for (HttpRequest request in server.timeout(Duration(minutes: 5))) {
        final response = request.response;

        print('🔍 요청 경로: ${request.uri.path}');
        print('🔍 요청 쿼리: ${request.uri.queryParameters}');

        if (request.uri.path == '/auth/kakao/callback') {
          final authCode = request.uri.queryParameters['code'];
          final error = request.uri.queryParameters['error'];
          final errorDescription =
              request.uri.queryParameters['error_description'];

          if (error != null) {
            print('❌ 카카오 로그인 오류: $error');
            print('❌ 오류 설명: $errorDescription');
            response.headers.contentType = ContentType.html;
            response.write('''
              <html><body>
                <h2>로그인 실패</h2>
                <p>오류: $error</p>
                <p>설명: $errorDescription</p>
                <p>이 창을 닫고 앱으로 돌아가세요.</p>
                <button onclick="window.close()">창 닫기</button>
              </body></html>
            ''');
            await response.close();
            break;
          } else if (authCode != null) {
            print('✅ 인증 코드 획득: ${authCode.substring(0, 10)}...');

            // Access Token 획득
            accessToken = await _getKakaoAccessToken(
              authCode,
              clientId,
              redirectUri,
            );

            response.headers.contentType = ContentType.html;
            if (accessToken != null) {
              response.write('''
                <html>
                <head>
                  <meta charset="UTF-8">
                  <title>로그인 성공</title>
                  <style>
                    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; text-align: center; padding: 50px; }
                    .success { color: #4CAF50; }
                    .button { background: #FEE500; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer; }
                  </style>
                </head>
                <body>
                  <h2 class="success">✅ 로그인 성공!</h2>
                  <p>엄빠, 읽어도! 앱으로 돌아가세요</p>
                  <button class="button" onclick="window.close()">창 닫기</button>
                  <script>
                    // 3초 후 자동으로 창 닫기
                    setTimeout(() => {
                      window.close();
                      // 창이 닫히지 않으면 안내 메시지
                      document.body.innerHTML = '<h2>이 창을 수동으로 닫아주세요</h2><p>앱으로 돌아가시기 바랍니다</p>';
                    }, 3000);
                  </script>
                </body>
                </html>
              ''');
              print('✅ 카카오 웹 로그인 성공');
            } else {
              response.write('''
                <html><body>
                  <h2>토큰 획득 실패</h2>
                  <p>다시 시도해주세요.</p>
                  <button onclick="window.close()">창 닫기</button>
                </body></html>
              ''');
            }
            await response.close();
            break;
          }
        } else {
          // 다른 경로에 대한 기본 응답
          response.headers.contentType = ContentType.html;
          response.write('''
            <html><body>
              <h2>카카오 로그인 대기 중...</h2>
              <p>로그인을 완료해주세요.</p>
              <p>현재 경로: ${request.uri.path}</p>
            </body></html>
          ''');
        }

        await response.close();
      }

      await server.close();
      return accessToken;
    } catch (e) {
      print('❌ 카카오 웹 로그인 오류: $e');
      return null;
    }
  }

  // 🆕 카카오 Access Token 획득
  Future<String?> _getKakaoAccessToken(
    String authCode,
    String clientId,
    String redirectUri,
  ) async {
    try {
      print('🔍 ===== 토큰 요청 시작 =====');
      print('🔍 authCode: $authCode');
      print('🔍 clientId: $clientId');
      print('🔍 redirectUri: $redirectUri');

      final requestData = {
        'grant_type': 'authorization_code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'code': authCode,
      };
      print('🔍 요청 데이터: $requestData');

      final dio = Dio();
      final response = await dio.post(
        'https://kauth.kakao.com/oauth/token',
        data: requestData,
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.statusCode == 200) {
        final tokenData = response.data;
        print('✅ 카카오 토큰 응답: $tokenData');
        return tokenData['access_token'];
      }
      return null;
    } on DioException catch (e) {
      print('❌ ===== DioException 발생 =====');
      print('❌ 타입: ${e.type}');
      print('❌ 메시지: ${e.message}');
      print('❌ 요청 옵션: ${e.requestOptions.uri}');
      print('❌ 요청 데이터: ${e.requestOptions.data}');
      print('❌ 요청 헤더: ${e.requestOptions.headers}');
      print('❌ 카카오 토큰 획득 실패');
      return null;
    } catch (e) {
      print('❌ 카카오 토큰 획득 오류: $e');
      return null;
    }
  }

  // google login accessToken
  Future<String?> _loginWithGoogle() async {
    try {
      print('🔍 구글 로그인 시작');
      print('🔍 현재 플랫폼: ${Platform.operatingSystem}');
      print('🔍 현재 시간: ${DateTime.now()}');

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId:
            Platform.isMacOS
                ? '910828369145-0b44tjdtgl37p23h0k3joul6eue18k6s.apps.googleusercontent.com'
                : null,
      );

      print('🔍 GoogleSignIn 객체 생성 완료');
      print('🔍 Client ID 설정: ${googleSignIn.clientId}');
      print('🔍 Scopes 설정: ${googleSignIn.scopes}');

      // ⭐ 현재 로그인 상태 확인
      GoogleSignInAccount? currentUser = googleSignIn.currentUser;
      print('🔍 현재 로그인된 사용자: ${currentUser?.email ?? "없음"}');

      // ⭐ 기존 로그인이 있다면 로그아웃 후 재시도
      if (currentUser != null) {
        print('🔍 기존 로그인 발견 - 로그아웃 후 재시도');
        await googleSignIn.signOut();
        await googleSignIn.disconnect();
      }

      print('🔍 signIn() 호출 시작...');

      // ⭐ 타임아웃 설정으로 무한 대기 방지
      final GoogleSignInAccount? account = await googleSignIn.signIn().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          print('❌ 구글 로그인 타임아웃 (30초)');
          return null;
        },
      );

      print('🔍 signIn() 결과: ${account?.email ?? "null"}');

      if (account == null) {
        print("❌ 구글 로그인 취소됨 또는 실패");

        // ⭐ 실패 원인 추가 분석
        try {
          bool isSignedIn = await googleSignIn.isSignedIn();
          print('🔍 현재 로그인 상태: $isSignedIn');
        } catch (e) {
          print('❌ 로그인 상태 확인 오류: $e');
        }

        return null;
      }

      print("✅ 구글 계정 정보:");
      print("   - Email: ${account.email}");
      print("   - Display Name: ${account.displayName}");
      print("   - ID: ${account.id}");

      print('🔍 인증 토큰 요청 시작...');
      final GoogleSignInAuthentication auth = await account.authentication;

      final accessToken = auth.accessToken;
      final idToken = auth.idToken;

      print("✅ 토큰 획득 결과:");
      print(
        "   - Access Token: ${accessToken != null ? '${accessToken.substring(0, 20)}...' : 'null'}",
      );
      print(
        "   - ID Token: ${idToken != null ? '${idToken.substring(0, 20)}...' : 'null'}",
      );

      if (accessToken == null && idToken == null) {
        print("❌ 모든 토큰이 null입니다!");
        return null;
      }

      return accessToken ?? idToken;
    } catch (e, stackTrace) {
      print('❌ 구글 로그인 상세 오류:');
      print('   - 오류 타입: ${e.runtimeType}');
      print('   - 오류 메시지: $e');
      print('   - 스택 트레이스: $stackTrace');
      return null;
    }
  }

  // ⭐ 카카오 로그인 처리 (macOS 웹 로그인 고려)
  Future<Map<String, dynamic>?> _handleKakaoLogin(String kakaoToken) async {
    try {
      print('🔍 [LoginScreen] 카카오 로그인 처리 시작');

      // ⭐ macOS 웹 로그인의 경우 사용자 정보를 API로 가져와야 함
      if (Platform.isMacOS) {
        return await _handleKakaoWebLogin(kakaoToken);
      }

      // Android/iOS는 기존 SDK 사용
      User user = await UserApi.instance.me();

      // AuthService를 통한 로그인 처리
      final result = await AuthService.handleKakaoLogin(
        kakaoAccessToken: kakaoToken,
        email: user.kakaoAccount?.email ?? '',
        nickname: user.kakaoAccount?.profile?.nickname ?? '',
      );

      return result;
    } catch (e) {
      print('❌ [LoginScreen] 카카오 로그인 처리 오류: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ⭐ macOS 웹 로그인용 처리 함수
  Future<Map<String, dynamic>?> _handleKakaoWebLogin(String kakaoToken) async {
    try {
      print('🔍 [LoginScreen] macOS 웹 카카오 로그인 처리');

      // 카카오 API로 사용자 정보 가져오기
      final dio = Dio();
      final userResponse = await dio.get(
        'https://kapi.kakao.com/v2/user/me',
        options: Options(headers: {'Authorization': 'Bearer $kakaoToken'}),
      );

      if (userResponse.statusCode == 200) {
        final userData = userResponse.data;
        final email = userData['kakao_account']?['email'] ?? '';
        final nickname =
            userData['kakao_account']?['profile']?['nickname'] ?? '';

        print('✅ 카카오 사용자 정보: email=$email, nickname=$nickname');

        // AuthService를 통한 로그인 처리
        final result = await AuthService.handleKakaoLogin(
          kakaoAccessToken: kakaoToken,
          email: email,
          nickname: nickname,
        );

        return result;
      } else {
        print('❌ 카카오 사용자 정보 조회 실패: ${userResponse.statusCode}');
        return {'success': false, 'error': '사용자 정보 조회 실패'};
      }
    } catch (e) {
      print('❌ [LoginScreen] macOS 웹 카카오 로그인 처리 오류: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ⭐ 구글 로그인 처리 (기존 방식 유지하되 AuthService와 연동)
  Future<Map<String, dynamic>?> _handleGoogleLogin(String googleToken) async {
    try {
      print('🔍 [LoginScreen] 구글 로그인 처리 시작');

      // 기존 방식으로 서버에 토큰 전송
      final result = await ApiService.sendOAuthLogin(
        provider: 'google',
        accessToken: googleToken,
      );

      if (result != null && result['success'] == true) {
        final data = result['data'];

        // AuthService에 토큰 저장
        await AuthService.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          userId: data['userId'],
          userEmail: data['userEmail'] ?? 'google@',
        );

        return {'success': true, 'data': data};
      }

      return result;
    } catch (e) {
      print('❌ [LoginScreen] 구글 로그인 처리 오류: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ⭐ 로그인 성공 후 네비게이션 (AuthService.getNextRoute 사용)
  Future<void> _navigateAfterLogin(BuildContext context) async {
    try {
      print('🔍 [LoginScreen] 로그인 성공 후 네비게이션 시작');

      // AuthService를 통해 다음 라우트 결정
      final nextRoute = await AuthService.getNextRoute();

      print('✅ [LoginScreen] 다음 화면으로 이동: $nextRoute');

      // 모든 이전 화면 제거하고 이동
      Navigator.pushNamedAndRemoveUntil(context, nextRoute, (route) => false);
    } catch (e) {
      print('❌ [LoginScreen] 네비게이션 오류: $e');
      // 오류 시 아이 정보 입력 화면으로 (안전장치)
      Navigator.pushReplacementNamed(context, '/child-info');
    }
  }

  // 에러 다이얼로그
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('로그인 오류'),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BaseScaffold(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 상단 헤더 (다른 화면들과 일관된 스타일)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF8B5A6B),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      '로그인',
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

              // 중앙 콘텐츠 영역
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 메인 이미지
                    Image.asset(
                      'assets/book_bear.png',
                      width: screenWidth * 0.6,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // 환영 메시지
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5A6B),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),

                    // 카카오 로그인 버튼
                    GestureDetector(
                      onTap: () async {
                        print('🔍 카카오 로그인 버튼 클릭');

                        // 로딩 다이얼로그 표시
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder:
                              (context) => Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF8B5A6B),
                                  ),
                                ),
                              ),
                        );

                        try {
                          final kakaoToken = await _loginWithKakao();

                          if (kakaoToken != null) {
                            final result = await _handleKakaoLogin(kakaoToken);

                            // 로딩 다이얼로그 닫기
                            Navigator.pop(context);

                            if (result != null && result['success'] == true) {
                              print('✅ 카카오 로그인 성공!');
                              await _navigateAfterLogin(context);
                            } else {
                              print('❌ 카카오 로그인 실패: ${result?['error']}');
                              _showErrorDialog(context, '카카오 로그인에 실패했습니다.');
                            }
                          } else {
                            Navigator.pop(context); // 로딩 다이얼로그 닫기
                            print('❌ 카카오 토큰 획득 실패');
                          }
                        } catch (e) {
                          Navigator.pop(context); // 로딩 다이얼로그 닫기
                          print('❌ 카카오 로그인 오류: $e');
                          _showErrorDialog(context, '카카오 로그인 중 오류가 발생했습니다.');
                        }
                      },
                      child: Container(
                        width: screenWidth * 0.8,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: AssetImage('assets/kakao_login.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),

                    // 구글 로그인 버튼
                    GestureDetector(
                      onTap: () async {
                        print('🔍 구글 로그인 버튼 클릭');

                        // 로딩 다이얼로그 표시
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder:
                              (context) => Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF8B5A6B),
                                  ),
                                ),
                              ),
                        );

                        try {
                          final googleToken = await _loginWithGoogle();

                          if (googleToken != null) {
                            final result = await _handleGoogleLogin(
                              googleToken,
                            );

                            // 로딩 다이얼로그 닫기
                            Navigator.pop(context);

                            if (result != null && result['success'] == true) {
                              print('✅ 구글 로그인 성공!');
                              await _navigateAfterLogin(context);
                            } else {
                              print('❌ 구글 로그인 실패: ${result?['error']}');
                              _showErrorDialog(context, '구글 로그인에 실패했습니다.');
                            }
                          } else {
                            Navigator.pop(context); // 로딩 다이얼로그 닫기
                            print('❌ 구글 토큰 획득 실패');
                          }
                        } catch (e) {
                          Navigator.pop(context); // 로딩 다이얼로그 닫기
                          print('❌ 구글 로그인 오류: $e');
                          _showErrorDialog(context, '구글 로그인 중 오류가 발생했습니다.');
                        }
                      },
                      child: Container(
                        width: screenWidth * 0.83,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: AssetImage('assets/google_login.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.04),

                    // 플랫폼 정보
                    Text(
                      Platform.isAndroid
                          ? '🤖 Android - 서버: ${ApiService.baseUrl}'
                          : Platform.isIOS
                          ? '📱 iOS - 서버: ${ApiService.baseUrl}'
                          : '💻 macOS - 서버: ${ApiService.baseUrl}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
