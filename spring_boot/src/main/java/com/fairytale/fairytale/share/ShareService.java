// src/main/java/com/fairytale/fairytale/share/ShareService.java
package com.fairytale.fairytale.share;

import com.fairytale.fairytale.coloring.ColoringWork;
import com.fairytale.fairytale.coloring.ColoringWorkRepository;
import com.fairytale.fairytale.comment.CommentRepository;
import com.fairytale.fairytale.gallery.Gallery;
import com.fairytale.fairytale.gallery.GalleryRepository;
import com.fairytale.fairytale.service.VideoService;
import com.fairytale.fairytale.share.dto.SharePostDTO;
import com.fairytale.fairytale.story.Story;
import com.fairytale.fairytale.story.StoryRepository;
import com.fairytale.fairytale.users.Users;
import com.fairytale.fairytale.users.UsersRepository;
import com.fairytale.fairytale.baby.Baby;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class ShareService {

    private final SharePostRepository sharePostRepository;
    private final StoryRepository storyRepository;
    private final GalleryRepository galleryRepository;
    private final UsersRepository usersRepository;
    private final VideoService videoService;
    private final CommentRepository commentRepository;
    private final ColoringWorkRepository coloringWorkRepository; // 추가
    /**
     * Stories에서 비디오 생성 및 공유 - 수정된 버전
     */
    public SharePostDTO shareFromStory(Long storyId, String username) {
        log.info("🎬 Stories에서 공유 시작 - StoryId: {}, 사용자: {}", storyId, username);

        // 1. 사용자 및 스토리 조회
        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + username));

        Story story = storyRepository.findByIdAndUser(storyId, user)
                .orElseThrow(() -> new RuntimeException("스토리를 찾을 수 없습니다: " + storyId));

        // 2. 개선된 필수 데이터 검증
        String imageUrl = story.getImage();
        String voiceUrl = story.getVoiceContent();

        log.info("🔍 공유 데이터 검증 - StoryId: {}", storyId);
        log.info("🔍 ImageUrl: {}", imageUrl);
        log.info("🔍 VoiceUrl: {}", voiceUrl);

        // 🎯 이미지 검증 (더 관대하게)
        if (imageUrl == null || imageUrl.trim().isEmpty() || "null".equals(imageUrl.trim())) {
            log.error("❌ 이미지 URL이 없음 - StoryId: {}, ImageUrl: '{}'", storyId, imageUrl);
            throw new RuntimeException("이미지가 없는 스토리는 공유할 수 없습니다. 이미지를 먼저 생성해주세요.");
        }

        // 🎯 음성 검증 (더 관대하게)
        if (voiceUrl == null || voiceUrl.trim().isEmpty() || "null".equals(voiceUrl.trim())) {
            log.error("❌ 음성 URL이 없음 - StoryId: {}, VoiceUrl: '{}'", storyId, voiceUrl);
            throw new RuntimeException("음성이 없는 스토리는 공유할 수 없습니다. 음성을 먼저 생성해주세요.");
        }

        // 🎯 URL 유효성 추가 검증
        if (!isValidUrl(imageUrl)) {
            log.error("❌ 유효하지 않은 이미지 URL - StoryId: {}, ImageUrl: {}", storyId, imageUrl);
            throw new RuntimeException("유효하지 않은 이미지 URL입니다.");
        }

        if (!isValidUrl(voiceUrl)) {
            log.error("❌ 유효하지 않은 음성 URL - StoryId: {}, VoiceUrl: {}", storyId, voiceUrl);
            throw new RuntimeException("유효하지 않은 음성 URL입니다.");
        }

        log.info("✅ 공유 데이터 검증 통과 - StoryId: {}", storyId);

        // 3. 비디오 생성 (안전하게 처리)
        String videoUrl;
        try {
            log.info("🎬 비디오 생성 시작 - StoryId: {}", storyId);
            videoUrl = videoService.createVideoFromImageAndAudio(
                    imageUrl,
                    voiceUrl,
                    story.getTitle()
            );
            log.info("✅ 비디오 생성 완료 - VideoUrl: {}", videoUrl);
        } catch (Exception e) {
            log.error("❌ 비디오 생성 실패 - StoryId: {}, Error: {}", storyId, e.getMessage());
            // 비디오 생성 실패 시 이미지를 대신 사용
            videoUrl = imageUrl;
            log.info("🔄 비디오 대신 이미지 사용 - StoryId: {}, ImageUrl: {}", storyId, videoUrl);
        }

        // 4. 썸네일 생성 (실패해도 진행)
        String thumbnailUrl = imageUrl; // 기본적으로 스토리 이미지 사용
        try {
            log.info("🖼️ 썸네일 생성 시작 - StoryId: {}", storyId);
            String generatedThumbnail = videoService.createThumbnail(videoUrl);
            if (generatedThumbnail != null && !generatedThumbnail.trim().isEmpty()) {
                thumbnailUrl = generatedThumbnail;
                log.info("✅ 썸네일 생성 완료 - ThumbnailUrl: {}", thumbnailUrl);
            } else {
                log.info("🔄 썸네일 생성 실패, 원본 이미지 사용 - StoryId: {}", storyId);
            }
        } catch (Exception e) {
            log.warn("⚠️ 썸네일 생성 실패, 원본 이미지 사용 - StoryId: {}, Error: {}", storyId, e.getMessage());
        }

        // 5. SharePost 생성 및 저장
        try {
            log.info("💾 SharePost 생성 및 저장 시작 - StoryId: {}", storyId);

            SharePost sharePost = new SharePost();
            sharePost.setUser(user);
            sharePost.setStoryTitle(story.getTitle());
            sharePost.setVideoUrl(videoUrl);
            sharePost.setImageUrl(imageUrl); // 🎯 이미지 URL도 설정
            sharePost.setThumbnailUrl(thumbnailUrl);
            sharePost.setSourceType("STORY");
            sharePost.setSourceId(storyId);

            // 🎯 아이 이름 설정 (Baby 정보에서 가져오기)
            String childName = getChildNameFromStory(story);
            String displayName = childName != null ? childName + "의 부모" : user.getUsername() + "님";
            sharePost.setUserName(displayName);

            SharePost savedPost = sharePostRepository.save(sharePost);
            log.info("✅ SharePost 저장 완료 - SharePostId: {}, StoryId: {}", savedPost.getId(), storyId);

            SharePostDTO result = convertToDTO(savedPost, user);
            log.info("✅ Stories 공유 전체 프로세스 완료 - SharePostId: {}, StoryId: {}", savedPost.getId(), storyId);

            return result;

        } catch (Exception e) {
            log.error("❌ SharePost 저장 실패 - StoryId: {}, Error: {}", storyId, e.getMessage());
            throw new RuntimeException("공유 게시물 저장에 실패했습니다: " + e.getMessage());
        }
    }

    /**
     * URL 유효성 검증 헬퍼 메서드
     */
    private boolean isValidUrl(String url) {
        if (url == null || url.trim().isEmpty()) {
            return false;
        }

        // 기본 URL 형식 검증
        String trimmedUrl = url.trim();
        if (trimmedUrl.startsWith("http://") || trimmedUrl.startsWith("https://")) {
            // S3 URL 패턴 검증
            return trimmedUrl.contains("amazonaws.com") ||
                    trimmedUrl.contains("cloudfront.net") ||
                    trimmedUrl.length() > 10; // 최소 길이 검증
        }

        return false;
    }

    /**
     * Story에서 아이 이름 추출 헬퍼 메서드
     */
    private String getChildNameFromStory(Story story) {
        try {
            if (story.getBaby() != null && story.getBaby().getBabyName() != null) {
                String babyName = story.getBaby().getBabyName().trim();
                if (!babyName.isEmpty()) {
                    return babyName;
                }
            }
            return null;
        } catch (Exception e) {
            log.debug("Baby 정보 조회 실패: {}", e.getMessage());
            return null;
        }
    }

    /**
     * Gallery에서 공유 (이미지만 업로드)
     */
    public SharePostDTO shareFromGallery(Long storyId, String username) {
        log.info("🖼️ Gallery에서 공유 시작 - StoryId: {}, 사용자: {}", storyId, username);

        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + username));

        Gallery gallery = galleryRepository.findByStoryId(storyId)
                .orElseThrow(() -> new RuntimeException("갤러리 항목을 찾을 수 없습니다: " + storyId));

        String imageUrl = gallery.getColoringImageUrl() != null ?
                gallery.getColoringImageUrl() : gallery.getColorImageUrl();

        if (imageUrl == null || imageUrl.isEmpty()) {
            throw new RuntimeException("공유할 이미지가 없습니다.");
        }

        SharePost sharePost = new SharePost();
        sharePost.setUser(user);
        sharePost.setStoryTitle(gallery.getStoryTitle());
        sharePost.setImageUrl(imageUrl); // 이미지 URL 설정
        sharePost.setThumbnailUrl(imageUrl); // 썸네일도 같은 이미지 사용
        sharePost.setSourceType("GALLERY");
        sharePost.setSourceId(gallery.getId()); // 실제 갤러리 PK
        // sharePost.setChildName(gallery.getChildName()); // Gallery에 childName이 없을 수 있으므로 주석
        sharePost.setVideoUrl("");

        SharePost savedPost = sharePostRepository.save(sharePost);
        log.info("✅ Gallery 공유 완료 - SharePostId: {}", savedPost.getId());

        return convertToDTO(savedPost, user);
    }

    /**
     * 모든 공유 게시물 조회 (모든 사용자의 게시물)
     */
    public List<SharePostDTO> getAllSharePosts(String currentUsername) {
        log.info("🔍 모든 공유 게시물 조회");

        Users currentUser = usersRepository.findByUsername(currentUsername).orElse(null);

        List<SharePost> posts = sharePostRepository.findAllByOrderByCreatedAtDesc();
        return posts.stream()
                .map(post -> convertToDTO(post, currentUser))
                .collect(Collectors.toList());
    }

    /**
     * 특정 사용자의 공유 게시물 조회
     */
    public List<SharePostDTO> getUserSharePosts(String username) {
        log.info("🔍 사용자 공유 게시물 조회 - 사용자: {}", username);

        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + username));

        List<SharePost> posts = sharePostRepository.findByUserOrderByCreatedAtDesc(user);
        return posts.stream()
                .map(post -> convertToDTO(post, user))
                .collect(Collectors.toList());
    }

    /**
     * 공유 게시물 삭제 (작성자만 가능)
     */
    /**
     * 공유 게시물 삭제 (작성자만 가능) - 댓글 먼저 삭제 로직 추가
     */
    public boolean deleteSharePost(Long postId, String username) {
        log.info("🗑️ 공유 게시물 삭제 - PostId: {}, 사용자: {}", postId, username);

        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + username));

        SharePost post = sharePostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("게시물을 찾을 수 없습니다: " + postId));

        // 작성자 확인
        if (!post.getUser().getId().equals(user.getId())) {
            log.warn("⚠️ 삭제 권한 없음 - 작성자가 아님");
            throw new RuntimeException("게시물을 삭제할 권한이 없습니다.");
        }

        try {
            // 🎯 1단계: 해당 게시물의 댓글들을 모두 삭제
            log.info("🗨️ 게시물의 댓글들 삭제 시작 - PostId: {}", postId);
            commentRepository.deleteBySharePostId(postId);
            log.info("✅ 댓글 삭제 완료");

            // 🎯 2단계: 좋아요 삭제는 자동으로 처리됨 (CASCADE)

            // 🎯 3단계: 게시물 삭제
            sharePostRepository.delete(post);
            log.info("✅ 공유 게시물 삭제 완료");

            return true;

        } catch (Exception e) {
            log.error("❌ 게시물 삭제 중 오류 발생: {}", e.getMessage());
            throw new RuntimeException("게시물 삭제 중 오류가 발생했습니다: " + e.getMessage());
        }
    }

    /**
     * 좋아요 토글
     */
    public SharePostDTO toggleLike(Long postId, String username) {
        log.info("❤️ 좋아요 토글 - PostId: {}, 사용자: {}", postId, username);

        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + username));

        SharePost post = sharePostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("게시물을 찾을 수 없습니다: " + postId));

        if (post.isLikedBy(user)) {
            post.removeLike(user);
            log.info("💔 좋아요 취소");
        } else {
            post.addLike(user);
            log.info("❤️ 좋아요 추가");
        }

        SharePost savedPost = sharePostRepository.save(post);
        return convertToDTO(savedPost, user);
    }

    /**
     * 🎯 특정 게시물 상세 조회
     */
    public SharePostDTO getSharePostById(Long postId, String currentUsername) {
        log.info("🔍 게시물 상세 조회 - PostId: {}, 요청자: {}", postId, currentUsername);

        Users currentUser = usersRepository.findByUsername(currentUsername).orElse(null);

        SharePost post = sharePostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("게시물을 찾을 수 없습니다: " + postId));

        SharePostDTO result = convertToDTO(post, currentUser);
        log.info("✅ 게시물 상세 조회 완료 - PostId: {}", postId);

        return result;
    }

    /**
     * 🔥 인기 게시물 조회 (좋아요 순)
     */
    public List<SharePostDTO> getPopularPosts(int limit, String currentUsername) {
        log.info("🔥 인기 게시물 조회 - 제한: {}, 요청자: {}", limit, currentUsername);

        Users currentUser = usersRepository.findByUsername(currentUsername).orElse(null);

        // 좋아요 수 기준으로 내림차순 정렬
        List<SharePost> posts = sharePostRepository.findAllByOrderByCreatedAtDesc(); // 임시로 일반 정렬 사용

        List<SharePostDTO> result = posts.stream()
                .limit(limit)
                .map(post -> convertToDTO(post, currentUser))
                .collect(Collectors.toList());

        log.info("✅ 인기 게시물 조회 완료 - {}개", result.size());
        return result;
    }

    /**
     * 📅 최근 게시물 조회
     */
    public List<SharePostDTO> getRecentPosts(int limit, String currentUsername) {
        log.info("📅 최근 게시물 조회 - 제한: {}, 요청자: {}", limit, currentUsername);

        Users currentUser = usersRepository.findByUsername(currentUsername).orElse(null);

        // 생성일 기준으로 내림차순 정렬
        List<SharePost> posts = sharePostRepository.findAllByOrderByCreatedAtDesc();

        List<SharePostDTO> result = posts.stream()
                .limit(limit)
                .map(post -> convertToDTO(post, currentUser))
                .collect(Collectors.toList());

        log.info("✅ 최근 게시물 조회 완료 - {}개", result.size());
        return result;
    }

    /**
     * 📊 사용자 통계 조회
     */
    public Map<String, Object> getUserStats(String username) {
        log.info("📊 사용자 통계 조회 - 사용자: {}", username);

        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + username));

        // 사용자의 게시물 수
        List<SharePost> userPosts = sharePostRepository.findByUserOrderByCreatedAtDesc(user);
        long postCount = userPosts.size();

        // 사용자가 받은 총 좋아요 수 (계산)
        long totalLikes = userPosts.stream()
                .mapToLong(SharePost::getLikeCount)
                .sum();

        // 최근 게시물 수
        long recentPostCount = Math.min(userPosts.size(), 5);

        Map<String, Object> stats = new HashMap<>();
        stats.put("username", username);
        stats.put("displayName", generateDisplayName(username));
        stats.put("postCount", postCount);
        stats.put("totalLikes", totalLikes);
        stats.put("recentPostCount", recentPostCount);
        stats.put("joinedDate", user.getCreatedAt());

        log.info("✅ 사용자 통계 조회 완료 - 사용자: {}, 게시물: {}개, 좋아요: {}개",
                username, postCount, totalLikes);

        return stats;
    }


    /**
     * 🎨 색칠 완성작에서 공유 (새로 추가)
     */
    public SharePostDTO shareFromColoringWork(Long coloringWorkId, String username) {
        log.info("🎨 색칠 완성작에서 공유 시작 - ColoringWorkId: {}, 사용자: {}", coloringWorkId, username);

        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + username));

        // 🎯 ColoringWork 조회 (ColoringWorkRepository 필요)
        ColoringWork coloringWork = coloringWorkRepository.findById(coloringWorkId)
                .orElseThrow(() -> new RuntimeException("색칠 완성작을 찾을 수 없습니다: " + coloringWorkId));

        // 권한 확인
        if (!coloringWork.getUsername().equals(username)) {
            throw new RuntimeException("본인의 작품만 공유할 수 있습니다.");
        }

        // 공유할 이미지 URL 확인
        String imageUrl = coloringWork.getCompletedImageUrl();
        if (imageUrl == null || imageUrl.isEmpty()) {
            throw new RuntimeException("공유할 색칠 완성작 이미지가 없습니다.");
        }

        // SharePost 생성
        SharePost sharePost = new SharePost();
        sharePost.setUser(user);
        sharePost.setStoryTitle(coloringWork.getStoryTitle() != null ?
                coloringWork.getStoryTitle() : "색칠 완성작");
        sharePost.setImageUrl(imageUrl); // 색칠된 이미지
        sharePost.setThumbnailUrl(imageUrl); // 썸네일도 같은 이미지
        sharePost.setSourceType("COLORING_WORK"); // 🎯 새로운 소스 타입
        sharePost.setSourceId(coloringWorkId); // ColoringWork ID
        sharePost.setVideoUrl(""); // 비디오 없음

        SharePost savedPost = sharePostRepository.save(sharePost);
        log.info("✅ 색칠 완성작 공유 완료 - SharePostId: {}", savedPost.getId());

        return convertToDTO(savedPost, user);
    }
    /**
     * SharePost를 DTO로 변환
     */
    private SharePostDTO convertToDTO(SharePost post, Users currentUser) {
        // 🎯 작성자 이름 포맷팅
        String displayName = generateDisplayName(post.getUser().getUsername());

        boolean isLiked = currentUser != null && post.isLikedBy(currentUser);
        boolean isOwner = currentUser != null && post.getUser().getId().equals(currentUser.getId());

        return SharePostDTO.builder()
                .id(post.getId())
                .userName(displayName)
                .storyTitle(post.getStoryTitle())
                .videoUrl(post.getVideoUrl())
                .imageUrl(post.getImageUrl())
                .thumbnailUrl(post.getThumbnailUrl())
                .sourceType(post.getSourceType())
                .likeCount(post.getLikeCount())
                .isLiked(isLiked)
                .isOwner(isOwner)
                .createdAt(post.getCreatedAt())
                .commentCount(getCommentCount(post.getId()))
                .build();
    }

    /**
     * 🎯 사용자 표시명 생성 (Baby.babyName 사용)
     */
    private String generateDisplayName(String username) {
        try {
            log.info("🔍 사용자 표시명 생성 - Username: {}", username);

            // 1. 사용자 정보 조회
            Users user = usersRepository.findByUsername(username).orElse(null);
            if (user == null) {
                log.warn("⚠️ 사용자를 찾을 수 없음: {}", username);
                return username + "님";
            }

            // 2. 🎯 Baby 엔티티에서 아이 이름 가져오기
            try {
                List<Baby> babies = user.getBabies();
                if (babies != null && !babies.isEmpty()) {
                    // 첫 번째 아기의 이름 사용
                    Baby firstBaby = babies.get(0);
                    String babyName = firstBaby.getBabyName(); // 🎯 실제 필드명 사용

                    if (babyName != null && !babyName.trim().isEmpty()) {
                        String displayName = babyName + "의 부모";
                        log.info("✅ 아기 이름으로 표시명 생성: {}", displayName);
                        return displayName;
                    }
                }
            } catch (Exception e) {
                log.info("ℹ️ Baby 정보 조회 실패, 다른 방법 시도: {}", e.getMessage());
            }

            // 3. Users의 getName() 메서드 사용 (nickname 우선, 없으면 username)
            String userName = user.getName();
            if (userName != null && !userName.trim().isEmpty()) {
                String displayName = userName + "님";
                log.info("✅ 사용자명으로 표시명 생성: {}", displayName);
                return displayName;
            }

            // 4. 최종 폴백
            String displayName = username + "님";
            log.info("✅ 최종 폴백 표시명 생성: {}", displayName);
            return displayName;

        } catch (Exception e) {
            log.error("❌ 표시명 생성 실패: {}", e.getMessage());
            return username + "님"; // 최종 폴백
        }
    }

    /**
     * 🎯 댓글 개수 조회
     */
    private int getCommentCount(Long postId) {
        try {
            return (int) commentRepository.countBySharePostId(postId);
        } catch (Exception e) {
            log.warn("⚠️ 댓글 개수 조회 실패: {}", e.getMessage());
            return 0;
        }
    }
}