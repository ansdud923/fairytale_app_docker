import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // 🚀 플랫폼에 따라 자동으로 서버 주소 선택
  static String get baseUrl {
    return 'http://3.36.41.71:8080'; // EC2 서버 IP
    // if (Platform.isAndroid) {
    //   return 'http://10.0.2.2:8080'; // Android 에뮬레이터
    // } else if (Platform.isIOS) {
    //   return 'http://localhost:8080'; // iOS 시뮬레이터
    // } else if (Platform.isMacOS) {
    //   return 'http://localhost:8080'; // macOS
    // } else {
    //   return 'http://localhost:8080'; // 기본값
    // }
  }

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // 🔧 OAuth 로그인 요청 (하나만 남김)
  static Future<Map<String, dynamic>?> sendOAuthLogin({
    required String provider,
    required String accessToken,
  }) async {
    try {
      print('🔍 서버로 토큰 전송 시작 - Provider: $provider');
      print('🔍 서버 주소: $baseUrl');

      final response = await _dio.post(
        '/oauth/login',
        data: {'provider': provider, 'accessToken': accessToken},
      );

      print('✅ 서버 응답 성공 - 상태코드: ${response.statusCode}');
      print('✅ 서버 응답 데이터: ${response.data}');

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      print('❌ 네트워크 오류: ${e.type}');
      print('❌ 오류 메시지: ${e.message}');

      if (e.response != null) {
        print('❌ 서버 응답 코드: ${e.response?.statusCode}');
        print('❌ 서버 응답 데이터: ${e.response?.data}');
      }

      return {'success': false, 'error': e.message, 'type': e.type.toString()};
    } catch (e) {
      print('❌ 서버 전송 오류: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ApiService.dart에 추가할 메서드

  // 🎨 색칠공부 템플릿 생성 (새로 추가)
  static Future<Map<String, dynamic>?> createColoringTemplate({
    required String storyId,
    required String title,
    required String originalImageUrl,
    String? blackWhiteImageUrl,
  }) async {
    try {
      print('🎨 [ApiService] 색칠공부 템플릿 생성 요청');
      print('🎨 [ApiService] StoryId: $storyId');
      print('🎨 [ApiService] Title: $title');
      print('🎨 [ApiService] 원본 이미지: $originalImageUrl');
      print('🎨 [ApiService] 흑백 이미지: $blackWhiteImageUrl');

      // JWT 토큰 가져오기
      String? accessToken = await getStoredAccessToken();

      if (accessToken == null) {
        print('❌ [ApiService] JWT 토큰이 없습니다.');
        return {'success': false, 'error': '로그인이 필요합니다', 'needLogin': true};
      }

      final requestData = {
        'storyId': storyId,
        'title': title,
        'originalImageUrl': originalImageUrl,
        if (blackWhiteImageUrl != null && blackWhiteImageUrl.isNotEmpty)
          'blackWhiteImageUrl': blackWhiteImageUrl,
      };

      print('🎨 [ApiService] 요청 데이터: ${json.encode(requestData)}');

      final response = await _dio.post(
        '/api/coloring/create-template',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      print('🎨 [ApiService] 템플릿 생성 응답 상태: ${response.statusCode}');
      print('🎨 [ApiService] 응답 본문: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map && responseData['success'] == true) {
          print('✅ [ApiService] 색칠공부 템플릿 생성 성공');
          return Map<String, dynamic>.from(responseData);
        } else {
          print('❌ [ApiService] 서버에서 실패 응답: ${responseData['error']}');
          return Map<String, dynamic>.from(responseData);
        }
      } else {
        print('❌ [ApiService] 색칠공부 템플릿 생성 실패: ${response.statusCode}');
        return {'success': false, 'error': '서버 오류: ${response.statusCode}'};
      }
    } on DioException catch (e) {
      print('❌ [ApiService] 색칠공부 템플릿 생성 네트워크 오류:');
      print('  - 오류 타입: ${e.type}');
      print('  - 오류 메시지: ${e.message}');

      if (e.response != null) {
        print('  - 서버 응답 코드: ${e.response?.statusCode}');
        print('  - 서버 응답 데이터: ${e.response?.data}');

        // 401 Unauthorized 에러 처리
        if (e.response?.statusCode == 401) {
          await removeAccessToken();
          return {
            'success': false,
            'error': '인증이 만료되었습니다. 다시 로그인해주세요.',
            'needLogin': true,
          };
        }
      }

      return {'success': false, 'error': e.message ?? '네트워크 오류'};
    } catch (e) {
      print('❌ [ApiService] 색칠공부 템플릿 생성 오류: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // 🗑️ 색칠공부 템플릿 삭제 (새로 추가)
  static Future<bool> deleteColoringTemplate(int templateId) async {
    try {
      print('🗑️ [ApiService] 색칠공부 템플릿 삭제 요청 - ID: $templateId');

      // JWT 토큰 가져오기
      String? accessToken = await getStoredAccessToken();

      if (accessToken == null) {
        print('❌ [ApiService] JWT 토큰이 없습니다.');
        return false;
      }

      final response = await _dio.delete(
        '/api/coloring/templates/$templateId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      print('🗑️ [ApiService] 템플릿 삭제 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          print('✅ [ApiService] 색칠공부 템플릿 삭제 성공');
          return true;
        }
      }

      print('❌ [ApiService] 색칠공부 템플릿 삭제 실패');
      return false;
    } on DioException catch (e) {
      print('❌ [ApiService] 색칠공부 템플릿 삭제 오류: ${e.message}');

      if (e.response?.statusCode == 401) {
        await removeAccessToken();
      }

      return false;
    } catch (e) {
      print('❌ [ApiService] 색칠공부 템플릿 삭제 오류: $e');
      return false;
    }
  }

  // 🎨 색칠공부 템플릿 목록 조회 (JWT 토큰 추가)
  static Future<List<Map<String, dynamic>>?> getColoringTemplates({
    int page = 0,
    int size = 20,
  }) async {
    try {
      print('🔍 색칠공부 템플릿 조회 시작');
      print('🔍 서버 주소: $baseUrl');
      print('🔍 전체 URL: $baseUrl/api/coloring/templates?page=$page&size=$size');

      // 🔥 JWT 토큰 가져오기 (핵심 추가!)
      String? accessToken = await getStoredAccessToken();

      if (accessToken == null) {
        print('❌ [ApiService] JWT 토큰이 없습니다. 로그인이 필요합니다.');
        return null; // 또는 빈 리스트 반환
      }

      print('🔐 [ApiService] JWT 토큰으로 인증된 요청 전송');

      final response = await _dio.get(
        '/api/coloring/templates',
        queryParameters: {'page': page, 'size': size},
        // 🔥 JWT 토큰을 헤더에 포함 (핵심!)
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      print('✅ 응답 상태코드: ${response.statusCode}');
      print('✅ 응답 헤더: ${response.headers}');
      print('✅ 응답 데이터 타입: ${response.data.runtimeType}');
      print('✅ 응답 데이터: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // 🎯 응답 구조 확인
        if (responseData is Map && responseData['success'] == true) {
          final List<dynamic> templatesJson = responseData['templates'] ?? [];

          final templates =
              templatesJson
                  .map((json) => Map<String, dynamic>.from(json))
                  .toList();

          print('✅ 색칠공부 템플릿 ${templates.length}개 조회 성공');
          return templates;
        } else {
          print('❌ 예상과 다른 응답 구조: $responseData');

          // 🎯 만약 응답이 배열이라면 직접 반환
          if (responseData is List) {
            final templates =
                responseData
                    .map((json) => Map<String, dynamic>.from(json))
                    .toList();
            print('✅ 직접 배열로 받은 템플릿 ${templates.length}개');
            return templates;
          }
        }
      } else if (response.statusCode == 401) {
        print('❌ 인증 실패: JWT 토큰이 만료되었거나 유효하지 않음');
        await removeAccessToken(); // 만료된 토큰 삭제
        return null;
      } else {
        print('❌ HTTP 오류: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ 네트워크 오류 상세:');
      print('  - 오류 타입: ${e.type}');
      print('  - 오류 메시지: ${e.message}');

      if (e.response != null) {
        print('  - 서버 응답 코드: ${e.response?.statusCode}');
        print('  - 서버 응답 데이터: ${e.response?.data}');
        print('  - 서버 응답 헤더: ${e.response?.headers}');

        // 🔥 401 에러 처리
        if (e.response?.statusCode == 401) {
          print('❌ 인증 실패: 로그인이 필요합니다');
          await removeAccessToken();
          return null;
        }
      } else {
        print('  - 네트워크 연결 오류 (서버가 꺼져있거나 주소가 잘못됨)');
      }
    } catch (e) {
      print('❌ 기타 오류: $e');
    }
    return null;
  }

  // ApiService.dart에 디버깅 메서드 추가
  static Future<void> debugColoringTemplates() async {
    final token = await getStoredAccessToken();
    print('🔐 저장된 JWT 토큰: ${token?.substring(0, 20)}...');

    final templates = await getColoringTemplates();
    print('📋 조회된 템플릿 개수: ${templates?.length ?? 0}');
  }

  // 🎨 색칠 완성작 저장
  static Future<Map<String, dynamic>?> saveColoredImage({
    required Map<String, dynamic> coloringData,
  }) async {
    try {
      print('🔍 색칠 완성작 저장 요청');
      print('🔍 요청 URL: $baseUrl/api/coloring/save');
      print('🔍 요청 데이터: $coloringData');

      final response = await _dio.post(
        '/api/coloring/save',
        data: coloringData,
      );

      print('✅ 저장 응답 상태코드: ${response.statusCode}');
      print('✅ 저장 응답 데이터: ${response.data}');

      if (response.statusCode == 200) {
        print('✅ 색칠 완성작 저장 성공');
        return {'success': true, 'data': response.data};
      }
    } on DioException catch (e) {
      print('❌ 저장 네트워크 오류:');
      print('  - 오류 타입: ${e.type}');
      print('  - 오류 메시지: ${e.message}');

      if (e.response != null) {
        print('  - 서버 응답 코드: ${e.response?.statusCode}');
        print('  - 서버 응답 데이터: ${e.response?.data}');
      }

      return {'success': false, 'error': e.message};
    } catch (e) {
      print('❌ 색칠 완성작 저장 실패: $e');
      return {'success': false, 'error': e.toString()};
    }
    return null;
  }

  // 🔍 서버 연결 테스트 (새로 추가)
  static Future<bool> testConnection() async {
    try {
      print('🔍 서버 연결 테스트 시작: $baseUrl');

      final response = await _dio
          .get('/actuator/health')
          .timeout(Duration(seconds: 5));

      print('✅ 서버 연결 성공: ${response.statusCode}');
      return true;
    } catch (e) {
      print('❌ 서버 연결 실패: $e');
      return false;
    }
  }

  // 🎯 색칠 완성작 저장 (Base64 이미지 포함) - 새로 추가
  static Future<Map<String, dynamic>?> saveColoredImageWithCapture({
    required Map<String, dynamic> coloringData,
  }) async {
    try {
      print('🎨 [ApiService] 색칠 완성작 저장 시작 (캡처 방식)');
      print('🎨 [ApiService] 원본 이미지: ${coloringData['originalImageUrl']}');
      print(
        '🎨 [ApiService] Base64 길이: ${coloringData['completedImageBase64']?.length ?? 0}',
      );

      final response = await _dio.post(
        '/api/coloring/save',
        data: coloringData,
      );

      print('🎨 [ApiService] 색칠 완성작 저장 응답 상태: ${response.statusCode}');
      print('🎨 [ApiService] 응답 본문: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // 🎯 응답을 Map으로 안전하게 변환
        Map<String, dynamic> resultMap;
        if (responseData is Map<String, dynamic>) {
          resultMap = responseData;
        } else if (responseData is Map) {
          // Map이지만 타입이 다른 경우 변환
          resultMap = Map<String, dynamic>.from(responseData);
        } else {
          // Map이 아닌 경우 기본 성공 응답 생성
          print('⚠️ [ApiService] 응답이 Map이 아님: ${responseData.runtimeType}');
          print('⚠️ [ApiService] 응답 내용: $responseData');
          resultMap = {
            'success': true,
            'message': '색칠 완성작이 저장되었습니다.',
            'data': responseData,
          };
        }

        // 🎯 success 필드 확인 및 처리
        if (resultMap['success'] == true || !resultMap.containsKey('success')) {
          // success가 true이거나 success 필드가 없는 경우 성공으로 처리
          if (!resultMap.containsKey('success')) {
            resultMap['success'] = true;
          }
          print('✅ [ApiService] 색칠 완성작 저장 성공');
          return resultMap;
        } else {
          print(
            '❌ [ApiService] 서버에서 실패 응답: ${resultMap['error'] ?? '알 수 없는 오류'}',
          );
          return resultMap;
        }
      } else {
        print('❌ [ApiService] 색칠 완성작 저장 실패: ${response.statusCode}');
        return {'success': false, 'error': '서버 오류: ${response.statusCode}'};
      }
    } on DioException catch (e) {
      print('❌ [ApiService] 색칠 완성작 저장 네트워크 오류:');
      print('  - 오류 타입: ${e.type}');
      print('  - 오류 메시지: ${e.message}');

      if (e.response != null) {
        print('  - 서버 응답 코드: ${e.response?.statusCode}');
        print('  - 서버 응답 데이터: ${e.response?.data}');
      }

      return {'success': false, 'error': e.message ?? '네트워크 오류'};
    } catch (e) {
      print('❌ [ApiService] 색칠 완성작 저장 오류: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // 🎨 색칠공부 템플릿 검색 - 새로 추가
  static Future<List<Map<String, dynamic>>?> searchColoringTemplates({
    required String keyword,
    int page = 0,
    int size = 20,
  }) async {
    try {
      print('🎨 [ApiService] 색칠공부 템플릿 검색 시작 - 키워드: $keyword');

      final response = await _dio.get(
        '/api/coloring/templates/search',
        queryParameters: {'keyword': keyword, 'page': page, 'size': size},
      );

      print('🎨 [ApiService] 색칠공부 템플릿 검색 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map && responseData['success'] == true) {
          final List<dynamic> templatesJson = responseData['templates'] ?? [];

          final templates =
              templatesJson
                  .map((json) => Map<String, dynamic>.from(json))
                  .toList();

          print('✅ [ApiService] 색칠공부 템플릿 검색 결과 ${templates.length}개');
          return templates;
        } else {
          print('❌ [ApiService] 예상과 다른 검색 응답 구조: $responseData');
        }
      } else {
        print('❌ [ApiService] 색칠공부 템플릿 검색 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [ApiService] 색칠공부 템플릿 검색 오류: ${e.message}');
    } catch (e) {
      print('❌ [ApiService] 색칠공부 템플릿 검색 오류: $e');
    }
    return null;
  }

  // 🎯 특정 템플릿 상세 조회 - 새로 추가
  static Future<Map<String, dynamic>?> getColoringTemplateDetail(
    int templateId,
  ) async {
    try {
      print('🎨 [ApiService] 색칠공부 템플릿 상세 조회 - ID: $templateId');

      final response = await _dio.get('/api/coloring/templates/$templateId');

      print('🎨 [ApiService] 템플릿 상세 조회 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map && responseData['success'] == true) {
          print('✅ [ApiService] 템플릿 상세 조회 성공');
          return responseData['template'];
        }
      }
    } on DioException catch (e) {
      print('❌ [ApiService] 템플릿 상세 조회 오류: ${e.message}');
    } catch (e) {
      print('❌ [ApiService] 템플릿 상세 조회 오류: $e');
    }
    return null;
  }

  // 🎯 동화 ID로 색칠공부 템플릿 조회 - 새로 추가
  static Future<Map<String, dynamic>?> getColoringTemplateByStoryId(
    String storyId,
  ) async {
    try {
      print('🎨 [ApiService] 동화별 색칠공부 템플릿 조회 - StoryId: $storyId');

      final response = await _dio.get('/api/coloring/templates/story/$storyId');

      print('🎨 [ApiService] 동화별 템플릿 조회 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map && responseData['success'] == true) {
          print('✅ [ApiService] 동화별 템플릿 조회 성공');
          return responseData['template'];
        }
      } else if (response.statusCode == 404) {
        print('⚠️ [ApiService] 해당 동화의 색칠공부 템플릿이 없음');
        return null;
      }
    } on DioException catch (e) {
      print('❌ [ApiService] 동화별 템플릿 조회 오류: ${e.message}');
    } catch (e) {
      print('❌ [ApiService] 동화별 템플릿 조회 오류: $e');
    }
    return null;
  }

  // 🎯 서버 연결 상태 확인 - 새로 추가
  static Future<Map<String, dynamic>> checkServerStatus() async {
    try {
      print('🔍 [ApiService] 서버 상태 확인 시작: $baseUrl');

      final response = await _dio
          .get('/actuator/health')
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('✅ [ApiService] 서버 연결 성공');
        return {
          'connected': true,
          'status': 'UP',
          'message': '서버가 정상적으로 작동 중입니다.',
        };
      } else {
        return {
          'connected': false,
          'status': 'ERROR',
          'message': '서버 응답 오류: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      print('❌ [ApiService] 서버 연결 실패: ${e.message}');

      String errorMessage;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = '서버 연결 시간 초과';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = '서버에 연결할 수 없습니다';
      } else {
        errorMessage = '네트워크 오류: ${e.message}';
      }

      return {'connected': false, 'status': 'DOWN', 'message': errorMessage};
    } catch (e) {
      print('❌ [ApiService] 서버 상태 확인 오류: $e');
      return {
        'connected': false,
        'status': 'UNKNOWN',
        'message': '알 수 없는 오류: $e',
      };
    }
  }

  // 사용자 프로필 조회
  static Future<Map<String, dynamic>?> getUserProfile({
    required int userId,
  }) async {
    try {
      print('🔍 [ApiService] 사용자 프로필 조회: userId=$userId');

      // JWT 토큰 가져오기
      String? accessToken = await getStoredAccessToken();

      if (accessToken == null) {
        print('❌ [ApiService] JWT 토큰이 없습니다.');
        return {'success': false, 'error': '로그인이 필요합니다', 'needLogin': true};
      }

      final response = await _dio.get(
        '/api/user/profile/$userId',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      print('✅ [ApiService] 사용자 프로필 조회 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          print('✅ [ApiService] 사용자 프로필 조회 성공');
          return responseData;
        } else {
          print('❌ [ApiService] 사용자 프로필 조회 실패: ${responseData['error']}');
          return responseData;
        }
      }
    } on DioException catch (e) {
      print('❌ [ApiService] 사용자 프로필 조회 오류: ${e.message}');
      if (e.response != null) {
        print('❌ [ApiService] 서버 응답 코드: ${e.response?.statusCode}');

        // 401/403 에러 처리
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          await removeAccessToken();
          return {
            'success': false,
            'error': '인증이 만료되었습니다. 다시 로그인해주세요.',
            'needLogin': true,
          };
        }
      }

      return {'success': false, 'error': e.message};
    } catch (e) {
      print('❌ [ApiService] 사용자 프로필 조회 실패: $e');
      return {'success': false, 'error': e.toString()};
    }
    return null;
  }
  // 🔐 JWT 토큰 관련 메서드들 추가

  // JWT 토큰 저장
  static Future<void> saveAccessToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      print('✅ [ApiService] JWT 토큰 저장 완료');
    } catch (e) {
      print('❌ [ApiService] JWT 토큰 저장 실패: $e');
    }
  }

  // JWT 토큰 가져오기
  static Future<String?> getStoredAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      print('🔍 [ApiService] 저장된 JWT 토큰: ${token != null ? '있음' : '없음'}');
      return token;
    } catch (e) {
      print('❌ [ApiService] JWT 토큰 조회 실패: $e');
      return null;
    }
  }

  // JWT 토큰 삭제
  static Future<void> removeAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      print('✅ [ApiService] JWT 토큰 삭제 완료');
    } catch (e) {
      print('❌ [ApiService] JWT 토큰 삭제 실패: $e');
    }
  }

  // JWT 토큰 포함 색칠 완성작 저장 (인증 필요)
  static Future<Map<String, dynamic>?> saveColoredImageWithAuth({
    required Map<String, dynamic> coloringData,
  }) async {
    try {
      print('🎨 [ApiService] 인증된 색칠 완성작 저장 시작');

      // JWT 토큰 가져오기
      String? accessToken = await getStoredAccessToken();

      if (accessToken == null) {
        print('❌ [ApiService] JWT 토큰이 없습니다. 로그인이 필요합니다.');
        return {'success': false, 'error': '로그인이 필요합니다', 'needLogin': true};
      }

      // 🔍 JWT 토큰 디버깅 정보 추가
      print(
        '🔐 [ApiService] JWT 토큰 첫 20자: ${accessToken.substring(0, math.min(20, accessToken.length))}...',
      );
      print('🔐 [ApiService] JWT 토큰 전체 길이: ${accessToken.length}');

      print('🎨 [ApiService] 원본 이미지: ${coloringData['originalImageUrl']}');
      print(
        '🎨 [ApiService] Base64 길이: ${coloringData['completedImageBase64']?.length ?? 0}',
      );

      // 🔍 요청 헤더 디버깅
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      print('🔍 [ApiService] 요청 헤더: $headers');
      print('🔍 [ApiService] 요청 URL: $baseUrl/api/coloring/save');

      final response = await _dio.post(
        '/api/coloring/save',
        data: coloringData,
        options: Options(headers: headers),
      );

      print('🎨 [ApiService] 색칠 완성작 저장 응답 상태: ${response.statusCode}');
      print('🎨 [ApiService] 응답 본문: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // 🎯 응답을 Map으로 안전하게 변환
        Map<String, dynamic> resultMap;
        if (responseData is Map<String, dynamic>) {
          resultMap = responseData;
        } else if (responseData is Map) {
          resultMap = Map<String, dynamic>.from(responseData);
        } else {
          print('⚠️ [ApiService] 응답이 Map이 아님: ${responseData.runtimeType}');
          resultMap = {
            'success': true,
            'message': '색칠 완성작이 저장되었습니다.',
            'data': responseData,
          };
        }

        // success 필드 확인 및 처리
        if (resultMap['success'] == true || !resultMap.containsKey('success')) {
          if (!resultMap.containsKey('success')) {
            resultMap['success'] = true;
          }
          print('✅ [ApiService] 인증된 색칠 완성작 저장 성공');
          return resultMap;
        } else {
          print('❌ [ApiService] 서버에서 실패 응답: ${resultMap['error']}');
          return resultMap;
        }
      } else {
        print('❌ [ApiService] 색칠 완성작 저장 실패: ${response.statusCode}');
        return {'success': false, 'error': '서버 오류: ${response.statusCode}'};
      }
    } on DioException catch (e) {
      print('❌ [ApiService] 인증된 색칠 완성작 저장 네트워크 오류:');
      print('  - 오류 타입: ${e.type}');
      print('  - 오류 메시지: ${e.message}');

      if (e.response != null) {
        print('  - 서버 응답 코드: ${e.response?.statusCode}');
        print('  - 서버 응답 데이터: ${e.response?.data}');

        // 401 Unauthorized 에러 처리
        if (e.response?.statusCode == 401) {
          print('🔐 [ApiService] 인증 토큰이 만료되었거나 유효하지 않습니다.');
          await removeAccessToken(); // 만료된 토큰 삭제
          return {
            'success': false,
            'error': '인증이 만료되었습니다. 다시 로그인해주세요.',
            'needLogin': true,
          };
        }
      }

      return {'success': false, 'error': e.message ?? '네트워크 오류'};
    } catch (e) {
      print('❌ [ApiService] 인증된 색칠 완성작 저장 오류: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    final token = await getStoredAccessToken();
    return token != null;
  }

  // 토큰 유효성 검사 (옵션)
  static Future<bool> isTokenValid() async {
    try {
      final token = await getStoredAccessToken();
      if (token == null) return false;

      // 간단한 토큰 검증 API 호출 (실제 구현 시 서버에 검증 엔드포인트 필요)
      final response = await _dio.get(
        '/api/auth/validate',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ [ApiService] 토큰 유효성 검사 실패: $e');
      return false;
    }
  }

  // 🔍 JWT 토큰 디버깅 메서드 추가
  static Future<void> debugJwtToken() async {
    try {
      final token = await getStoredAccessToken();
      if (token == null) {
        print('🔍 [JWT Debug] 토큰 없음');
        return;
      }

      print('🔍 [JWT Debug] 토큰 길이: ${token.length}');
      print(
        '🔍 [JWT Debug] 토큰 시작: ${token.substring(0, math.min(50, token.length))}...',
      );

      // JWT 토큰 구조 확인 (header.payload.signature)
      final parts = token.split('.');
      print('🔍 [JWT Debug] 토큰 부분 개수: ${parts.length} (정상: 3개)');

      if (parts.length == 3) {
        print('🔍 [JWT Debug] Header 길이: ${parts[0].length}');
        print('🔍 [JWT Debug] Payload 길이: ${parts[1].length}');
        print('🔍 [JWT Debug] Signature 길이: ${parts[2].length}');
      }
    } catch (e) {
      print('❌ [JWT Debug] 디버깅 실패: $e');
    }
  }

  // 📷 S3 프로필 이미지 업로드 관련 메서드들

  // Presigned URL 생성 요청 (JWT 토큰 포함)
  static Future<Map<String, dynamic>?> getPresignedUrl({
    required int userId,
    required String fileType,
  }) async {
    try {
      print(
        '🔍 [ApiService] Presigned URL 요청 - userId: $userId, fileType: $fileType',
      );

      // JWT 토큰 가져오기
      String? accessToken = await getStoredAccessToken();

      if (accessToken == null) {
        print('❌ [ApiService] JWT 토큰이 없습니다. 로그인이 필요합니다.');
        return {'success': false, 'error': '로그인이 필요합니다', 'needLogin': true};
      }

      print('🔐 [ApiService] JWT 토큰으로 인증된 요청 전송');

      final response = await _dio.post(
        '/api/upload/profile-image/presigned-url',
        data: {'userId': userId, 'fileType': fileType},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      print('✅ [ApiService] Presigned URL 응답: ${response.statusCode}');
      print('✅ [ApiService] 응답 데이터: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          return responseData;
        } else {
          print('❌ [ApiService] Presigned URL 생성 실패: ${responseData['error']}');
          return {'success': false, 'error': responseData['error']};
        }
      }
    } on DioException catch (e) {
      print('❌ [ApiService] Presigned URL 요청 오류: ${e.message}');
      if (e.response != null) {
        print('❌ [ApiService] 서버 응답 코드: ${e.response?.statusCode}');
        print('❌ [ApiService] 서버 응답 데이터: ${e.response?.data}');

        // 401/403 에러 처리
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          print('🔐 [ApiService] 인증 오류: 토큰이 만료되었거나 권한이 없습니다.');
          await removeAccessToken(); // 만료된 토큰 삭제
          return {
            'success': false,
            'error': '인증이 만료되었습니다. 다시 로그인해주세요.',
            'needLogin': true,
          };
        }
      }
      return {'success': false, 'error': e.message};
    } catch (e) {
      print('❌ [ApiService] Presigned URL 요청 실패: $e');
      return {'success': false, 'error': e.toString()};
    }
    return null;
  }

  // S3에 직접 파일 업로드 (Presigned URL 사용)
  static Future<bool> uploadFileToS3({
    required String presignedUrl,
    required Map<String, String> fields,
    required File file,
    required String contentType,
  }) async {
    try {
      print('🔍 [ApiService] S3 파일 업로드 시작');
      print('🔍 [ApiService] Presigned URL: $presignedUrl');
      print('🔍 [ApiService] 파일 크기: ${await file.length()} bytes');

      // FormData 생성
      final formData = FormData();

      // Presigned POST의 필수 필드들 추가
      fields.forEach((key, value) {
        formData.fields.add(MapEntry(key, value));
      });

      // 파일 추가 (반드시 마지막에 추가)
      formData.files.add(
        MapEntry(
          'file',
          await MultipartFile.fromFile(
            file.path,
            contentType: MediaType.parse(contentType),
          ),
        ),
      );

      // S3에 직접 업로드
      final response = await _dio.post(
        presignedUrl,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          followRedirects: false,
          validateStatus: (status) => status! < 400,
        ),
      );

      print('✅ [ApiService] S3 업로드 성공: ${response.statusCode}');
      return true;
    } on DioException catch (e) {
      print('❌ [ApiService] S3 업로드 실패: ${e.message}');
      if (e.response != null) {
        print('❌ [ApiService] S3 응답 코드: ${e.response?.statusCode}');
        print('❌ [ApiService] S3 응답 데이터: ${e.response?.data}');
      }
      return false;
    } catch (e) {
      print('❌ [ApiService] S3 업로드 오류: $e');
      return false;
    }
  }

  // 프로필 이미지 URL 업데이트 (JWT 토큰 포함)
  static Future<Map<String, dynamic>?> updateProfileImageUrl({
    required int userId,
    required String profileImageKey,
  }) async {
    try {
      print('🔍 [ApiService] 프로필 이미지 URL 업데이트 - userId: $userId');

      // JWT 토큰 가져오기
      String? accessToken = await getStoredAccessToken();

      if (accessToken == null) {
        print('❌ [ApiService] JWT 토큰이 없습니다. 로그인이 필요합니다.');
        return {'success': false, 'error': '로그인이 필요합니다', 'needLogin': true};
      }

      final response = await _dio.put(
        '/api/user/profile-image',
        data: {'userId': userId, 'profileImageKey': profileImageKey},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      print('✅ [ApiService] 프로필 이미지 URL 업데이트 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          print('✅ [ApiService] 프로필 이미지 URL 업데이트 성공');
          return responseData;
        }
      }
    } on DioException catch (e) {
      print('❌ [ApiService] 프로필 이미지 URL 업데이트 오류: ${e.message}');

      if (e.response != null) {
        print('❌ [ApiService] 서버 응답 코드: ${e.response?.statusCode}');

        // 401/403 에러 처리
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          await removeAccessToken();
          return {
            'success': false,
            'error': '인증이 만료되었습니다. 다시 로그인해주세요.',
            'needLogin': true,
          };
        }
      }

      return {'success': false, 'error': e.message};
    } catch (e) {
      print('❌ [ApiService] 프로필 이미지 URL 업데이트 실패: $e');
      return {'success': false, 'error': e.toString()};
    }
    return null;
  }

  // ApiService.dart의 uploadProfileImage 메서드를 이것으로 교체하세요

  // ApiService.dart의 uploadProfileImage 메서드를 이것으로 교체하세요

  // 전체 프로필 이미지 업로드 프로세스 (편의 메서드) - 수정된 버전
  static Future<Map<String, dynamic>?> uploadProfileImage({
    required int userId,
    required File imageFile,
  }) async {
    try {
      print('🎯 [ApiService] 프로필 이미지 업로드 프로세스 시작');

      // 1. 파일 타입 확인
      String contentType = 'image/jpeg';
      String filePath = imageFile.path.toLowerCase();
      if (filePath.endsWith('.png')) {
        contentType = 'image/png';
      } else if (filePath.endsWith('.jpg') || filePath.endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      }

      print('🎯 [ApiService] 파일 타입: $contentType');

      // 2. Presigned URL 요청
      final presignedResult = await getPresignedUrl(
        userId: userId,
        fileType: contentType,
      );

      if (presignedResult == null || presignedResult['success'] != true) {
        print('❌ [ApiService] Presigned URL 생성 실패');
        return presignedResult;
      }

      print('🎯 [ApiService] Presigned URL 응답 구조 확인:');
      print('🎯 [ApiService] Keys: ${presignedResult.keys.toList()}');

      // 🔍 서버 응답 구조 확인 (변수명 변경)
      final presignedUrl = presignedResult['presignedUrl'] as String?;
      final publicUrl = presignedResult['publicUrl'] as String?;
      final serverFileName = presignedResult['fileName'] as String?; // 변수명 변경

      if (presignedUrl == null) {
        print('❌ [ApiService] Presigned URL이 응답에 없습니다');
        return {'success': false, 'error': 'Presigned URL을 받지 못했습니다'};
      }

      print('🎯 [ApiService] Presigned URL 생성 성공');
      print('🎯 [ApiService] Public URL: $publicUrl');
      print('🎯 [ApiService] Server File Name: $serverFileName');

      // 3. S3에 직접 PUT 요청으로 파일 업로드 (Presigned URL 방식)
      final uploadSuccess = await uploadFileToS3Direct(
        presignedUrl: presignedUrl,
        file: imageFile,
        contentType: contentType,
      );

      if (!uploadSuccess) {
        print('❌ [ApiService] S3 파일 업로드 실패');
        return {'success': false, 'error': 'S3 업로드 실패'};
      }

      print('🎯 [ApiService] S3 업로드 성공');

      // 4. 서버에 프로필 이미지 URL 업데이트 (serverFileName 사용)
      if (serverFileName != null) {
        final updateResult = await updateProfileImageUrl(
          userId: userId,
          profileImageKey: serverFileName,
        );

        if (updateResult == null || updateResult['success'] != true) {
          print('❌ [ApiService] 프로필 이미지 URL 업데이트 실패');
          return updateResult;
        }

        print('✅ [ApiService] 프로필 이미지 업로드 프로세스 완료');

        // publicUrl을 결과에 포함
        return {
          'success': true,
          'profileImageUrl': publicUrl,
          'fileName': serverFileName,
          'message': '프로필 이미지가 성공적으로 업데이트되었습니다.',
        };
      } else {
        print('❌ [ApiService] fileName이 응답에 없습니다');
        return {'success': false, 'error': 'fileName을 받지 못했습니다'};
      }
    } catch (e) {
      print('❌ [ApiService] 프로필 이미지 업로드 프로세스 오류: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // S3에 직접 파일 업로드 (PUT 방식)
  static Future<bool> uploadFileToS3Direct({
    required String presignedUrl,
    required File file,
    required String contentType,
  }) async {
    try {
      print('🔍 [ApiService] S3 직접 업로드 시작');
      print('🔍 [ApiService] Presigned URL: $presignedUrl');
      print('🔍 [ApiService] 파일 크기: ${await file.length()} bytes');

      // 파일을 바이트로 읽기
      final fileBytes = await file.readAsBytes();

      // PUT 요청으로 S3에 직접 업로드
      final response = await _dio.put(
        presignedUrl,
        data: fileBytes,
        options: Options(
          headers: {'Content-Type': contentType},
          validateStatus: (status) => status! < 400,
        ),
      );

      print('✅ [ApiService] S3 업로드 성공: ${response.statusCode}');
      return true;
    } on DioException catch (e) {
      print('❌ [ApiService] S3 업로드 실패: ${e.message}');
      if (e.response != null) {
        print('❌ [ApiService] S3 응답 코드: ${e.response?.statusCode}');
        print('❌ [ApiService] S3 응답 데이터: ${e.response?.data}');
      }
      return false;
    } catch (e) {
      print('❌ [ApiService] S3 업로드 오류: $e');
      return false;
    }
  }

  static Dio get dio => _dio;
}
