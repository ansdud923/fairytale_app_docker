import 'package:flutter/material.dart';
import '../profile/profile_screen.dart';
import '../service/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String _ddayText = 'D-day';
  Map<String, dynamic>? _childData;

  @override
  void initState() {
    super.initState();
    _initializeHomeScreen();
  }

  // ⭐ 홈화면 초기화 (인증 확인 + 아이 정보 로드)
  Future<void> _initializeHomeScreen() async {
    try {
      // 1. 로그인 확인
      final isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      // 2. 아이 정보 확인
      final childInfo = await AuthService.checkChildInfo();
      if (childInfo != null && childInfo['hasChild'] == true) {
        setState(() {
          _childData = childInfo['childData'];
          _ddayText = _calculateDDay(_childData);
        });
      } else {
        // 아이 정보가 없으면 아이 정보 입력 화면으로
        Navigator.pushReplacementNamed(context, '/child-info');
        return;
      }
    } catch (e) {
      print('❌ [HomeScreen] 초기화 오류: $e');
      // 오류 시 기본 텍스트 유지
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ⭐ D-day 계산 함수
  String _calculateDDay(Map<String, dynamic>? childData) {
    if (childData == null) return 'D-day';

    try {
      final babyName = childData['name'] ?? '아이';
      final birthDateStr = childData['birthDate'] ?? childData['baby_birth_date'];

      if (birthDateStr == null) {
        print('❌ [HomeScreen] 생년월일 정보 없음');
        return 'D-day';
      }

      print('🔍 [HomeScreen] 아이 정보: 이름=$babyName, 생년월일=$birthDateStr');

      // 날짜 파싱
      DateTime birthDate;
      if (birthDateStr is String) {
        birthDate = DateTime.parse(birthDateStr);
      } else {
        birthDate = birthDateStr as DateTime;
      }

      // 오늘 날짜
      final today = DateTime.now();
      final todayWithoutTime = DateTime(today.year, today.month, today.day);
      final birthDateWithoutTime = DateTime(birthDate.year, birthDate.month, birthDate.day);

      // 날짜 차이 계산
      final difference = birthDateWithoutTime.difference(todayWithoutTime).inDays;

      if (difference > 0) {
        // 미래 = 아직 태어나지 않음
        return '$babyName -${difference}日';
      } else if (difference < 0) {
        // 과거 = 이미 태어남
        return '$babyName +${difference.abs()}日';
      } else {
        // 오늘 = 생일
        return '$babyName 생일! 🎉';
      }
    } catch (e) {
      print('❌ [HomeScreen] D-day 계산 오류: $e');
      return 'D-day';
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  // ⭐ 새로고침 함수 (pull to refresh용)
  Future<void> _refreshData() async {
    await _initializeHomeScreen();
  }

  // home_screen.dart - build 메서드 수정 (오버플로우 해결)

// home_screen.dart - build 메서드 수정 (오버플로우 해결)

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/bg_image.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF6B756)),
                ),
                SizedBox(height: 16),
                Text(
                  '로딩 중...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF3B2D2C),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 🎯 원래 크기로 복원 + 안전한 오버플로우 처리
    final cardHeight = screenHeight * 0.20; // 0.18 → 0.20으로 복원
    final iconSizeLarge = screenWidth * 0.24; // 0.22 → 0.24로 복원
    final iconSizeSmall = screenWidth * 0.21; // 0.20 → 0.21로 복원
    final topLogoHeight = screenHeight * 0.26; // 0.24 → 0.26으로 복원
    final cloudIconSize = screenWidth * 0.19; // 0.18 → 0.19로 복원
    final cloudIconRightOffset = screenWidth * 0.13; // 0.12 → 0.13으로 복원
    final mediumCardHeight = screenHeight * 0.11; // 0.09 → 0.11로 복원


    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_image.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: const Color(0xFFF6B756),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                // 🎯 최소 높이 보장으로 오버플로우 방지
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      60, // 하단 네비게이션 바 높이
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 10), // 80 → 20으로 축소
                    child: Column(
                      children: [
                        // 상단 로고 (크기 축소)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.01, // 0.00 → 0.01로 증가
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(width: screenWidth * 0.06),
                              Flexible(
                                child: Image.asset(
                                  'assets/logo.png',
                                  height: topLogoHeight,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              PopupMenuButton(
                                icon: Image.asset(
                                  'assets/profile_icon.png',
                                  width: screenWidth * 0.06,
                                  height: screenWidth * 0.06,
                                ),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    child: const Row(
                                      children: [
                                        Icon(Icons.person, size: 20),
                                        SizedBox(width: 8),
                                        Text('프로필'),
                                      ],
                                    ),
                                    onTap: () {
                                      Future.delayed(Duration.zero, () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ProfileScreen(),
                                          ),
                                        );
                                      });
                                    },
                                  ),
                                  PopupMenuItem(
                                    child: const Row(
                                      children: [
                                        Icon(Icons.refresh, size: 20),
                                        SizedBox(width: 8),
                                        Text('새로고침'),
                                      ],
                                    ),
                                    onTap: () {
                                      Future.delayed(Duration.zero, () {
                                        _refreshData();
                                      });
                                    },
                                  ),
                                  PopupMenuItem(
                                    child: const Row(
                                      children: [
                                        Icon(Icons.logout, size: 20),
                                        SizedBox(width: 8),
                                        Text('로그아웃'),
                                      ],
                                    ),
                                    onTap: () {
                                      Future.delayed(Duration.zero, () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text('로그아웃'),
                                            content: const Text(
                                              '정말 로그아웃하시겠습니까?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('취소'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _logout();
                                                },
                                                child: const Text('로그아웃'),
                                              ),
                                            ],
                                          ),
                                        );
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // D-day 텍스트
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.005,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Text(
                                  _ddayText,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.035,
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFF3B2D2C),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.015), // 0.02 → 0.015로 축소

                        // 메인 카드들 (동화세상, 색칠공부)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: cardHeight,
                                  child: SquareCard(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF8E97FD), Color(0xFF6B73FF)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    iconPath: 'assets/rabbit.png',
                                    iconSize: iconSizeLarge,
                                    iconTopOffset: -iconSizeLarge / 3,
                                    title: '동화세상',
                                    subtitle: '마음을 담은, \n나만의 동화',
                                    onPressed: () => Navigator.pushNamed(context, '/stories'),
                                    buttonAlignment: Alignment.centerRight,
                                  ),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Expanded(
                                child: SizedBox(
                                  height: cardHeight,
                                  child: SquareCard(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFD3A8), Color(0xFFFFB84D)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    iconPath: 'assets/coloring_bear.png',
                                    iconSize: iconSizeSmall,
                                    iconTopOffset: -iconSizeSmall / 3,
                                    title: '색칠공부',
                                    subtitle: '색칠하며 펼쳐지는 \n상상의 세계',
                                    onPressed: () => Navigator.pushNamed(context, '/coloring'),
                                    buttonAlignment: Alignment.centerRight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.015), // 0.02 → 0.015로 축소

                        // 🎯 중간 카드들 (우리의 기록일지 + 갤러리) - 크기 복원
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                          ),
                          child: SizedBox(
                            height: mediumCardHeight, // 복원된 크기 사용
                            child: Row(
                              children: [
                                Expanded(
                                  child: MediumCard(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFF9F8D), Color(0xFFFF6B9D)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    iconPath: 'assets/love.png',
                                    title: '우리의 기록일지',
                                    subtitle: '사랑스러운 동화\n함께 나눠요',
                                    onPressed: () => Navigator.pushNamed(context, '/share'),
                                    iconSize: screenWidth * 0.10, // 0.08 → 0.10으로 복원
                                    iconTopOffset: -(screenWidth * 0.10) / 3,
                                    iconRightOffset: screenWidth * 0.02,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.03),
                                Expanded(
                                  child: MediumCard(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF81C784), Color(0xFF4CAF50)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    iconPath: '',
                                    title: '갤러리',
                                    subtitle: '아름다운 순간들을\n모아보세요',
                                    onPressed: () => Navigator.pushNamed(context, '/gallery'),
                                    iconSize: screenWidth * 0.10, // 0.08 → 0.10으로 복원
                                    iconTopOffset: -(screenWidth * 0.10) / 3,
                                    iconRightOffset: screenWidth * 0.02,
                                    useIconWidget: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.015), // 0.02 → 0.015로 축소

                        // Sleep Music 배너 (크기 복원)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                          ),
                          child: SizedBox(
                            height: mediumCardHeight, // 복원된 크기 사용
                            child: DarkCard(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF555B6E), Color(0xFF3A4160)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              iconPath: 'assets/cloud.png',
                              title: 'Sleep Music',
                              subtitle: '마음을 편안하게 해주는 수면 음악',
                              onPressed: () => Navigator.pushNamed(context, '/lullaby'),
                              iconSize: cloudIconSize,
                              iconTopOffset: -cloudIconSize / 3,
                              iconRightOffset: cloudIconRightOffset,
                              showButton: true,
                            ),
                          ),
                        ),

                        // 🎯 유연한 공간 추가
                        Flexible(
                          child: SizedBox(height: screenHeight * 0.02),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: const Color(0xFFF6B756),
        unselectedItemColor: const Color(0xFF9E9E9E),
        onTap: (index) {
          final routes = [
            '/home',
            '/stories',
            '/coloring',
            '/share',
            '/lullaby',
            '/gallery',
          ];
          final currentRoute = ModalRoute.of(context)?.settings.name;
          if (currentRoute != routes[index]) {
            if (index != 0) {
              Navigator.pushNamed(context, routes[index]);
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                    (route) => false,
              );
            }
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Stories'),
          BottomNavigationBarItem(icon: Icon(Icons.brush), label: 'Coloring'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Share'),
          BottomNavigationBarItem(
            icon: Icon(Icons.nights_stay),
            label: 'Lullabies',
          ),
        ],
      ),
    );
  }
}

// SquareCard 위젯
class SquareCard extends StatelessWidget {
  final LinearGradient gradient;
  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final double iconSize;
  final double iconTopOffset;
  final Alignment buttonAlignment;

  const SquareCard({
    required this.gradient,
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    required this.iconSize,
    required this.iconTopOffset,
    required this.buttonAlignment,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: iconTopOffset + iconSize / 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(12, iconSize / 2 - 4, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                      overflow: TextOverflow.visible,
                      softWrap: true,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: buttonAlignment,
                    child: ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        elevation: 2,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'START',
                        style: TextStyle(
                          color: gradient.colors.first,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: iconTopOffset,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                iconPath,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 🎯 MediumCard - 원래 디자인 복원 + 오버플로우 안전 처리
class MediumCard extends StatelessWidget {
  final LinearGradient gradient;
  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final double iconSize;
  final double iconTopOffset;
  final double iconRightOffset;
  final bool useIconWidget;

  const MediumCard({
    required this.gradient,
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    required this.iconSize,
    required this.iconTopOffset,
    required this.iconRightOffset,
    this.useIconWidget = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // 🎯 디바이스 타입 감지
    final isTablet = screenWidth > 600;

    // 🎯 반응형 폰트 크기 (원래 크기 기준)
    double getResponsiveFontSize(double baseSize) {
      if (isTablet) {
        return baseSize * 1.5; // 태블릿에서는 1.5배
      } else {
        return baseSize; // 모바일에서는 원래 크기
      }
    }

    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        clipBehavior: Clip.none, // 🎯 아이콘이 카드 밖으로 나올 수 있도록
        children: [
          // 🎯 메인 카드 (원래 위치)
          Positioned.fill(
            top: iconTopOffset + iconSize / 2, // 🎯 아이콘 공간만큼 아래로
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: EdgeInsets.all(isTablet ? 16 : 10), // 반응형 패딩
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 🎯 사용 가능한 높이 계산
                  final availableHeight = constraints.maxHeight;
                  final buttonHeight = isTablet ? 28.0 : 20.0;
                  final padding = isTablet ? 8.0 : 4.0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🎯 텍스트 영역 (유연하게)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 제목
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: getResponsiveFontSize(13),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            // 부제목
                            Expanded(
                              child: Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: getResponsiveFontSize(9),
                                  color: Colors.white70,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 🎯 버튼 영역 (고정)
                      SizedBox(height: padding),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: onPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(buttonHeight / 2),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 16 : 12,
                              vertical: 0,
                            ),
                            elevation: 2,
                            minimumSize: Size(0, buttonHeight),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'START',
                            style: TextStyle(
                              color: gradient.colors.first,
                              fontWeight: FontWeight.bold,
                              fontSize: getResponsiveFontSize(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // 🎯 아이콘 (원래 위치 - 카드 위로)
          if (!useIconWidget && iconPath.isNotEmpty)
            Positioned(
              top: iconTopOffset,
              right: iconRightOffset,
              child: Image.asset(
                iconPath,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }
}

// 🎯 DarkCard - 원래 디자인 복원 + 안전 처리
class DarkCard extends StatelessWidget {
  final LinearGradient gradient;
  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final double iconSize;
  final double iconTopOffset;
  final double iconRightOffset;
  final bool showButton;

  const DarkCard({
    required this.gradient,
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    required this.iconSize,
    required this.iconTopOffset,
    required this.iconRightOffset,
    this.showButton = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // 🎯 반응형 폰트 크기
    double getResponsiveFontSize(double baseSize) {
      return isTablet ? baseSize * 1.5 : baseSize;
    }

    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 🎯 메인 카드 (원래 위치)
          Positioned.fill(
            top: iconTopOffset + iconSize / 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 16,
                vertical: isTablet ? 12 : 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🎯 텍스트 영역
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: getResponsiveFontSize(15),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isTablet ? 6 : 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: getResponsiveFontSize(11),
                            color: Colors.white70,
                            height: 1.3,
                          ),
                          maxLines: isTablet ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // 🎯 버튼 영역
                  if (showButton) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 20 : 16,
                          vertical: 0,
                        ),
                        elevation: 2,
                        minimumSize: Size(0, isTablet ? 32 : 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'START',
                        style: TextStyle(
                          color: gradient.colors.first,
                          fontWeight: FontWeight.bold,
                          fontSize: getResponsiveFontSize(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 🎯 아이콘 (원래 위치)
          Positioned(
            top: iconTopOffset,
            right: iconRightOffset,
            child: Image.asset(
              iconPath,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}