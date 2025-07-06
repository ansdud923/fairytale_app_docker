// lib/widgets/auth_guard.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/service/auth_service.dart';
import '../main.dart'; // BaseScaffold 사용

/// 🛡️ 인증 가드 위젯
/// 페이지 접근 전에 로그인 상태와 아이 정보를 확인합니다.
class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        // 🔄 로딩 중
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen('인증 확인 중...');
        }

        // ✅ 로그인됨 - 아이 정보도 확인
        if (snapshot.data == true) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: AuthService.checkChildInfo(),
            builder: (context, childSnapshot) {
              // 🔄 아이 정보 확인 중
              if (childSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen('정보 확인 중...');
              }

              final childInfo = childSnapshot.data;

              // ❌ 토큰 문제 발생 (서버 오류 등)
              if (childInfo == null) {
                _redirectToLogin(context);
                return _buildEmptyScreen();
              }

              // ❌ 아이 정보 없음
              if (!childInfo['hasChild']) {
                _redirectToChildInfo(context);
                return _buildEmptyScreen();
              }

              // ✅ 모든 조건 만족 - 페이지 표시
              return child;
            },
          );
        }

        // ❌ 로그인되지 않음
        _redirectToLogin(context);
        return _buildEmptyScreen();
      },
    );
  }

  /// 🔄 로딩 화면 생성
  Widget _buildLoadingScreen(String message) {
    return BaseScaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/bear.png',
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.child_care,
                  size: 120,
                  color: Color(0xFFF6B756),
                );
              },
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF6B756)),
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.hiMelody(
                fontSize: 16,
                color: Color(0xFF754D19),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📭 빈 화면 (리다이렉트 대기 중)
  Widget _buildEmptyScreen() {
    return BaseScaffold(
      child: Container(),
    );
  }

  /// 🔄 로그인 페이지로 리다이렉트
  void _redirectToLogin(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false, // 모든 이전 라우트 제거
      );
    });
  }

  /// 🔄 아이 정보 입력 페이지로 리다이렉트
  void _redirectToChildInfo(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/child-info',
            (route) => false, // 모든 이전 라우트 제거
      );
    });
  }
}

/// 🛡️ 간단한 인증 가드 (로그인만 체크)
/// 아이 정보는 체크하지 않고 로그인 상태만 확인합니다.
class SimpleAuthGuard extends StatelessWidget {
  final Widget child;

  const SimpleAuthGuard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        // 🔄 로딩 중
        if (snapshot.connectionState == ConnectionState.waiting) {
          return BaseScaffold(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF6B756)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '로그인 확인 중...',
                    style: GoogleFonts.hiMelody(
                      fontSize: 16,
                      color: Color(0xFF754D19),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ✅ 로그인됨 - 페이지 표시
        if (snapshot.data == true) {
          return child;
        }

        // ❌ 로그인되지 않음 - 로그인 페이지로 리다이렉트
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
                (route) => false,
          );
        });

        return BaseScaffold(child: Container());
      },
    );
  }
}

/// 🛡️ 프로필 전용 가드 (로그인만 체크, 아이 정보 불필요)
/// 프로필 관련 페이지에서 사용 (설정, 연락처, 지원 등)
class ProfileAuthGuard extends StatelessWidget {
  final Widget child;

  const ProfileAuthGuard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return BaseScaffold(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF6B756)),
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          return child;
        }

        // 로그인되지 않음 - 로그인 페이지로 리다이렉트
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
                (route) => false,
          );
        });

        return BaseScaffold(child: Container());
      },
    );
  }
}