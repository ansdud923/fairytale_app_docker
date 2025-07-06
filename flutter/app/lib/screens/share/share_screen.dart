// lib/screens/share/share_screen.dart - 전체 코드 (댓글 시스템 포함)
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../service/api_service.dart';
import 'package:video_player/video_player.dart';

class ShareScreen extends StatefulWidget {
  @override
  _ShareScreenState createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  List<SharePost> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  // 인증된 HTTP 요청을 위한 헤더 가져오기
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    return {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
  }

  // 공유 게시물 로드
  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);

    try {
      final headers = await _getAuthHeaders();

      print('🔍 공유 게시물 요청 시작');

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/share/posts'),
        headers: headers,
      );

      print('🔍 공유 게시물 응답 상태: ${response.statusCode}');
      print('🔍 공유 게시물 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        setState(() {
          _posts = responseData.map((item) => SharePost.fromJson(item)).toList();
        });

        print('✅ 공유 게시물 로드 완료: ${_posts.length}개 게시물');
      } else {
        throw Exception('공유 게시물 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 공유 게시물 로드 에러: $e');
      setState(() {
        _errorMessage = '공유 게시물을 불러오는데 실패했습니다.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 좋아요 토글
  Future<void> _toggleLike(SharePost post) async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/share/posts/${post.id}/like'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final updatedPost = SharePost.fromJson(json.decode(response.body));

        setState(() {
          final index = _posts.indexWhere((p) => p.id == post.id);
          if (index != -1) {
            _posts[index] = updatedPost;
          }
        });
      }
    } catch (e) {
      print('❌ 좋아요 토글 실패: $e');
    }
  }

  // 게시물 삭제
  Future<void> _deletePost(SharePost post) async {
    // 삭제 확인 다이얼로그
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('게시물 삭제'),
        content: Text('이 게시물을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('삭제'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      final headers = await _getAuthHeaders();

      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/api/share/posts/${post.id}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        setState(() {
          _posts.removeWhere((p) => p.id == post.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('게시물이 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('삭제 실패');
      }
    } catch (e) {
      print('❌ 게시물 삭제 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('게시물 삭제에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // + 버튼 클릭 시 선택 다이얼로그
  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '새 게시물 만들기',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),

              // 동화세상으로 이동
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFF6B756),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.auto_stories, color: Colors.white),
                ),
                title: Text('동화세상'),
                subtitle: Text('새로운 동화를 만들어서 공유하기'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/stories');
                },
              ),

              SizedBox(height: 10),

              // 갤러리로 이동
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                title: Text('갤러리'),
                subtitle: Text('저장된 작품을 공유하기'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/gallery');
                },
              ),

              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // 🎯 댓글 바텀시트 표시
  Future<void> _showCommentsBottomSheet(SharePost post) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(postId: post.id),
    );
  }

  Future<void> _onRefresh() async {
    await _loadPosts();
  }

  void _playVideo(SharePost post) {
    if (post.videoUrl != null && post.videoUrl!.isNotEmpty) {
      // 비디오가 있는 경우 비디오 플레이어
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            videoUrl: post.videoUrl!,
            title: post.storyTitle,
          ),
        ),
      );
    } else if (post.imageUrl != null || post.thumbnailUrl != null) {
      // 이미지만 있는 경우 전체화면 이미지 뷰어
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageViewerScreen(
            imageUrl: post.imageUrl ?? post.thumbnailUrl ?? '',
            title: post.storyTitle,
          ),
        ),
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async {
        // 🎯 뒤로가기 시 홈화면으로 이동
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        return false; // 기본 뒤로가기 동작 방지
      },
      child: BaseScaffold(
        child: SafeArea(
          child: Column(
            children: [
              // 상단 앱바
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.02,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // 🎯 뒤로가기 버튼도 홈으로 이동
                        Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/home',
                                (route) => false
                        );
                      },
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.black54,
                        size: screenWidth * 0.06,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '우리의 기록일지',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // + 버튼 (새 게시물 작성)
                    GestureDetector(
                      onTap: _showCreateOptions,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF9F8D),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: screenWidth * 0.05,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 게시물 피드
              Expanded(
                child: _isLoading
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFFFF9F8D),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '기록일지를 불러오는 중...',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                )
                    : _errorMessage != null
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPosts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF9F8D),
                        ),
                        child: Text('다시 시도'),
                      ),
                    ],
                  ),
                )
                    : _posts.isEmpty
                    ? _buildEmptyState(screenWidth, screenHeight)
                    : RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: Color(0xFFFF9F8D),
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      return _buildPostCard(_posts[index], screenWidth, screenHeight);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(double screenWidth, double screenHeight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: screenWidth * 0.2,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            '아직 공유된 동화가 없어요',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '첫 번째 동화를 만들어서 공유해보세요!',
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              color: Colors.black38,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateOptions,
            icon: Icon(Icons.add),
            label: Text('동화 만들기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF9F8D),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(SharePost post, double screenWidth, double screenHeight) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 게시물 헤더 (프로필 정보)
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // 프로필 아바타
                Container(
                  width: screenWidth * 0.12,
                  height: screenWidth * 0.12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.grey[600],
                    size: screenWidth * 0.06,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _formatDate(post.createdAt),
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                // 삭제 버튼 (작성자만)
                if (post.isOwner)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deletePost(post);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('삭제', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // 동화 제목
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFFFF9F8D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                post.storyTitle,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF9F8D),
                ),
              ),
            ),
          ),

          SizedBox(height: 12),

          // 컨텐츠 (비디오 또는 이미지)
          GestureDetector(
            onTap: () => _playVideo(post),
            child: Container(
              height: screenHeight * 0.3,
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[300],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // 썸네일 이미지
                    if (post.thumbnailUrl != null && post.thumbnailUrl!.isNotEmpty)
                      Image.network(
                        post.thumbnailUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildContentPlaceholder(post, screenWidth);
                        },
                      )
                    else
                      _buildContentPlaceholder(post, screenWidth),

                    // 재생 버튼 오버레이 (비디오인 경우만)
                    if (post.videoUrl != null && post.videoUrl!.isNotEmpty)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                          ),
                          child: Center(
                            child: Container(
                              width: screenWidth * 0.15,
                              height: screenWidth * 0.15,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.play_arrow,
                                color: Color(0xFFFF9F8D),
                                size: screenWidth * 0.08,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // 갤러리 표시 (이미지만 있는 경우)
                    if (post.sourceType == 'GALLERY')
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Gallery',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 🎯 좋아요 및 댓글 버튼 (댓글 기능 활성화)
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // 좋아요 버튼
                GestureDetector(
                  onTap: () => _toggleLike(post),
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: post.isLiked ? Colors.red : Colors.grey,
                        size: 24,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${post.likeCount}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                // 🎯 댓글 버튼 (클릭 기능 추가)
                GestureDetector(
                  onTap: () => _showCommentsBottomSheet(post),
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 24),
                      SizedBox(width: 4),
                      Text(
                        '${post.commentCount ?? 0}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentPlaceholder(SharePost post, double screenWidth) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              post.sourceType == 'GALLERY' ? Icons.photo : Icons.video_library,
              size: screenWidth * 0.15,
              color: Colors.grey[600],
            ),
            SizedBox(height: 8),
            Text(
              post.sourceType == 'GALLERY' ? '갤러리 이미지' : '동화 비디오',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: screenWidth * 0.035,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🎯 공유 게시물 데이터 모델 (commentCount 추가)
class SharePost {
  final int id;
  final String userName;
  final String storyTitle;
  final String? videoUrl;
  final String? imageUrl;
  final String? thumbnailUrl;
  final String sourceType;
  final int likeCount;
  final bool isLiked;
  final bool isOwner;
  final DateTime? createdAt;
  final int? commentCount; // 🎯 댓글 개수 필드 추가

  SharePost({
    required this.id,
    required this.userName,
    required this.storyTitle,
    this.videoUrl,
    this.imageUrl,
    this.thumbnailUrl,
    required this.sourceType,
    required this.likeCount,
    required this.isLiked,
    required this.isOwner,
    required this.createdAt,
    this.commentCount, // 🎯 추가
  });

  factory SharePost.fromJson(Map<String, dynamic> json) {
    String? createdAtStr = json['createdAt']?.toString();
    return SharePost(
      id: json['id'],
      userName: json['userName'],
      storyTitle: json['storyTitle'],
      videoUrl: json['videoUrl'],
      imageUrl: json['imageUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      sourceType: json['sourceType'] ?? 'STORY',
      likeCount: json['likeCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      isOwner: json['isOwner'] ?? false,
      createdAt: (createdAtStr != null && createdAtStr.isNotEmpty)
          ? DateTime.tryParse(createdAtStr)
          : null,
      commentCount: json['commentCount'] ?? 0, // 🎯 추가
    );
  }
}

// 🎯 댓글 바텀시트 위젯 (삭제 기능 추가)
class CommentsBottomSheet extends StatefulWidget {
  final int postId;

  const CommentsBottomSheet({Key? key, required this.postId}) : super(key: key);

  @override
  _CommentsBottomSheetState createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
  }

  Future<void> _loadComments() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/share/comments/${widget.postId}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            _comments = (responseData['comments'] as List)
                .map((json) => Comment.fromJson(json))
                .toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ 댓글 로드 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/share/comments/${widget.postId}'),
        headers: headers,
        body: json.encode({'content': _commentController.text.trim()}),
      );

      if (response.statusCode == 200) {
        _commentController.clear();
        _loadComments(); // 댓글 목록 새로고침
      }
    } catch (e) {
      print('❌ 댓글 작성 실패: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // 🎯 댓글 삭제 함수 추가
  Future<void> _deleteComment(int commentId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/api/share/comments/$commentId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        _loadComments(); // 댓글 목록 새로고침
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글이 삭제되었습니다.')),
        );
      } else {
        throw Exception('댓글 삭제 실패');
      }
    } catch (e) {
      print('❌ 댓글 삭제 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 삭제에 실패했습니다.')),
      );
    }
  }

  // 🎯 댓글 삭제 확인 다이얼로그
  Future<void> _showDeleteConfirmDialog(int commentId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('댓글 삭제'),
          content: Text('이 댓글을 삭제하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('삭제', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteComment(commentId);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 헤더
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '댓글 ${_comments.length}개',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),
          Divider(height: 1),

          // 댓글 목록
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('첫 번째 댓글을 작성해보세요!'),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final comment = _comments[index];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[300],
                        child: Icon(Icons.person, color: Colors.grey[600]),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    comment.userName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                // 🎯 삭제 버튼 (작성자만 표시)
                                if (comment.isOwner)
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _showDeleteConfirmDialog(comment.id);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => [
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, color: Colors.red, size: 18),
                                            SizedBox(width: 8),
                                            Text('삭제', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    child: Icon(
                                      Icons.more_vert,
                                      color: Colors.grey[600],
                                      size: 18,
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              comment.content,
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _formatCommentDate(comment.createdAt),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 댓글 입력
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: '댓글을 입력하세요...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    maxLines: null,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: _isSubmitting ? null : _submitComment,
                  icon: _isSubmitting
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Icon(Icons.send, color: Color(0xFFFF9F8D)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCommentDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

// 🎯 Comment 모델 (isOwner 필드 추가)
class Comment {
  final int id;
  final String content;
  final String username;
  final String userName;
  final DateTime? createdAt;
  final bool? isEdited;
  final bool isOwner; // 🎯 추가

  Comment({
    required this.id,
    required this.content,
    required this.username,
    required this.userName,
    this.createdAt,
    this.isEdited,
    this.isOwner = false, // 🎯 기본값
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      content: json['content'],
      username: json['username'],
      userName: json['userName'] ?? '${json['username']}님', // 🎯 null 안전 처리
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      isEdited: json['isEdited'] ?? false,
      isOwner: json['isOwner'] ?? false, // 🎯 추가
    );
  }
}

// 이미지 뷰어 화면 (갤러리 이미지용)
class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String title;

  const ImageViewerScreen({
    required this.imageUrl,
    required this.title,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        title: Text(
          title,
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return CircularProgressIndicator(color: Color(0xFFFF9F8D));
            },
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.white70),
                  SizedBox(height: 16),
                  Text(
                    '이미지를 불러올 수 없습니다',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// 비디오 플레이어 화면
class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoPlayerScreen({
    required this.videoUrl,
    required this.title,
    Key? key,
  }) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    try {
      _controller = VideoPlayerController.network(widget.videoUrl);
      _controller.initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
      }).catchError((error) {
        print('❌ 비디오 초기화 오류: $error');
        setState(() {
          _hasError = true;
        });
      });
    } catch (e) {
      print('❌ 비디오 컨트롤러 생성 오류: $e');
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        title: Text(
          widget.title,
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Center(
        child: _hasError
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.white70,
            ),
            SizedBox(height: 16),
            Text(
              '비디오를 재생할 수 없습니다',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '네트워크 연결을 확인해주세요',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isInitialized = false;
                });
                _initializeVideo();
              },
              child: Text('다시 시도'),
            ),
          ],
        )
            : _isInitialized
            ? Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      });
                    },
                  ),
                  Expanded(
                    child: VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                        playedColor: Color(0xFFFF9F8D),
                        bufferedColor: Colors.white30,
                        backgroundColor: Colors.white10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFFFF9F8D),
            ),
            SizedBox(height: 16),
            Text(
              '비디오를 불러오는 중...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}