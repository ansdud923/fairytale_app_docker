// lib/service/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:io';

// ⭐ 기존 ApiService import
import 'api_service.dart';

class AuthService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  // ⭐ ApiService의 baseUrl과 dio 사용
  static String get _baseUrl => ApiService.baseUrl;
  static Dio get _dio => ApiService.dio;

  // 토큰 저장
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int userId,
    required String userEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_userEmailKey, userEmail);

    // ⭐ ApiService에도 토큰 저장 (JWT 토큰 관리 통합)
    await ApiService.saveAccessToken(accessToken);

    print('✅ [AuthService] 토큰 저장 완료');
  }

  // Access Token 가져오기
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  // Refresh Token 가져오기
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // 사용자 ID 가져오기
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  // 사용자 이메일 가져오기
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  // ⭐ 아이 정보 확인 (ApiService의 dio 사용)
  static Future<Map<String, dynamic>?> checkChildInfo() async {
    try {
      final accessToken = await getAccessToken();
      final userId = await getUserId();

      if (accessToken == null || userId == null) {
        print('🔍 [AuthService] 토큰 또는 사용자 ID 없음');
        return {'hasChild': false, 'childData': null};
      }

      print('🔍 [AuthService] 아이 정보 확인 요청: userId=$userId, URL: $_baseUrl');

      try {
        final response = await _dio.get(
          '/api/baby',
          queryParameters: {'userId': userId},
          options: Options(
            headers: {'Authorization': 'Bearer $accessToken'},
          ),
        );

        print('✅ [AuthService] 아이 정보 확인 응답: ${response.data}');

        if (response.statusCode == 200 && response.data['success'] == true) {
          return {
            'hasChild': response.data['hasChild'] ?? false,
            'childData': response.data['data'],
          };
        }

        return {'hasChild': false, 'childData': null};

      } catch (e) {
        if (e is DioException) {
          print('🔍 [AuthService] DioException 발생: ${e.type}, 상태코드: ${e.response?.statusCode}');
          print('🔍 [AuthService] 에러 메시지: ${e.message}');

          if (e.response?.statusCode == 403) {
            print('🔄 [AuthService] 토큰 만료, 갱신 시도...');

            final refreshSuccess = await refreshAccessToken();

            if (refreshSuccess) {
              print('✅ [AuthService] 토큰 갱신 성공, 재시도...');
              final newAccessToken = await getAccessToken();
              final retryResponse = await _dio.get(
                '/api/baby',
                queryParameters: {'userId': userId},
                options: Options(
                  headers: {'Authorization': 'Bearer $newAccessToken'},
                ),
              );

              print('✅ [AuthService] 재시도 응답: ${retryResponse.data}');

              if (retryResponse.statusCode == 200 && retryResponse.data['success'] == true) {
                return {
                  'hasChild': retryResponse.data['hasChild'] ?? false,
                  'childData': retryResponse.data['data'],
                };
              }

              return {'hasChild': false, 'childData': null};
            } else {
              print('❌ [AuthService] 토큰 갱신 실패, 로그아웃 처리');
              await logout();
              return null;
            }
          } else {
            print('❌ [AuthService] 네트워크 오류 또는 기타 DioException');
            return {'hasChild': false, 'childData': null};
          }
        } else {
          print('❌ [AuthService] 기타 에러: $e');
          return {'hasChild': false, 'childData': null};
        }
      }

    } catch (e) {
      print('❌ [AuthService] 아이 정보 확인 오류: $e');
      return {'hasChild': false, 'childData': null};
    }
  }

  // ⭐ 로그인 후 적절한 화면으로 이동하는 라우팅 로직
  static Future<String> getNextRoute() async {
    try {
      print('🔍 [AuthService] 라우팅 결정 시작');

      // 1. 로그인 상태 확인
      final isAuthenticated = await isLoggedIn();
      if (!isAuthenticated) {
        print('🔍 [AuthService] 로그인되지 않음 → /login');
        return '/login';
      }

      // 2. 아이 정보 확인
      final childInfo = await checkChildInfo();

      if (childInfo == null) {
        print('🔍 [AuthService] 토큰 문제 발생 → /login');
        return '/login';
      }

      if (!childInfo['hasChild']) {
        print('🔍 [AuthService] 아이 정보 없음 → /child-info');
        return '/child-info';
      }

      print('✅ [AuthService] 모든 정보 완료 → /home');
      return '/home';

    } catch (e) {
      print('❌ [AuthService] 라우팅 결정 오류: $e');
      return '/onboarding';
    }
  }

  // 로그아웃
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);

    // ⭐ ApiService에서도 토큰 삭제
    await ApiService.removeAccessToken();

    print('✅ [AuthService] 로그아웃 완료');
  }

  // ⭐ 토큰 갱신 (ApiService의 dio 사용)
  static Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        print('❌ [AuthService] Refresh Token이 없음');
        return false;
      }

      print('🔄 [AuthService] 토큰 갱신 요청...');

      final response = await _dio.post(
        '/oauth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['accessToken'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accessTokenKey, newAccessToken);

        // ⭐ ApiService에도 새 토큰 저장
        await ApiService.saveAccessToken(newAccessToken);

        print('✅ [AuthService] 토큰 갱신 성공');
        return true;
      }

      print('❌ [AuthService] 토큰 갱신 실패: ${response.statusCode}');
      return false;

    } catch (e) {
      print('❌ [AuthService] 토큰 갱신 오류: $e');
      return false;
    }
  }

  // ⭐ 서버 연결 테스트 (ApiService 활용)
  static Future<bool> testConnection() async {
    try {
      print('🔍 [AuthService] 서버 연결 테스트: $_baseUrl');

      final serverStatus = await ApiService.checkServerStatus();
      final isConnected = serverStatus['connected'] == true;

      print('${isConnected ? "✅" : "❌"} [AuthService] 서버 연결 ${isConnected ? "성공" : "실패"}: ${serverStatus['message']}');

      return isConnected;
    } catch (e) {
      print('❌ [AuthService] 서버 연결 테스트 오류: $e');
      return false;
    }
  }

  // ⭐ 카카오 로그인 처리 (ApiService 활용)
  static Future<Map<String, dynamic>?> handleKakaoLogin({
    required String kakaoAccessToken,
    required String email,
    required String nickname,
  }) async {
    try {
      print('🔍 [AuthService] 카카오 로그인 처리 시작');

      final result = await ApiService.sendOAuthLogin(
        provider: 'kakao',
        accessToken: kakaoAccessToken,
      );

      if (result != null && result['success'] == true) {
        final data = result['data'];

        // JWT 토큰과 사용자 정보 저장
        await saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          userId: data['userId'],
          userEmail: email,
        );

        print('✅ [AuthService] 카카오 로그인 성공');
        return {'success': true, 'data': data};
      } else {
        print('❌ [AuthService] 카카오 로그인 실패: ${result?['error']}');
        return result;
      }
    } catch (e) {
      print('❌ [AuthService] 카카오 로그인 오류: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}