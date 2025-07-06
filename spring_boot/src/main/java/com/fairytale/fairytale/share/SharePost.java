// src/main/java/com/fairytale/fairytale/share/SharePost.java
package com.fairytale.fairytale.share;

import com.fairytale.fairytale.users.Users;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "share_posts")
@Getter
@Setter
@EntityListeners(AuditingEntityListener.class)
public class SharePost {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private Users user;

    @Column(name = "story_title", length = 255)
    private String storyTitle;

    @Column(name = "video_url", length = 1000)
    private String videoUrl; // S3에 저장된 mp4 파일 URL (Stories에서만 사용)

    @Column(name = "image_url", length = 1000)
    private String imageUrl; // 이미지 URL (Gallery에서 사용)

    @Column(name = "thumbnail_url", length = 1000)
    private String thumbnailUrl; // 썸네일 이미지 URL

    @Column(name = "source_type", length = 50)
    private String sourceType; // "STORY" 또는 "GALLERY"

    @Column(name = "source_id")
    private Long sourceId; // 원본 Story ID 또는 Gallery ID

    @Column(name = "child_name", length = 100)
    private String childName; // 아이 이름

    @Column(name = "user_name", length = 100)
    private String userName; // "아이이름의 부모" 저장


    @Column(name = "like_count", nullable = false)
    private Integer likeCount = 0; // 좋아요 수

    // 좋아요한 사용자 목록
    @ManyToMany
    @JoinTable(
            name = "share_post_likes",
            joinColumns = @JoinColumn(name = "post_id"),
            inverseJoinColumns = @JoinColumn(name = "user_id")
    )
    private Set<Users> likedUsers = new HashSet<>();

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // 좋아요 추가
    public void addLike(Users user) {
        if (likedUsers.add(user)) {
            likeCount++;
        }
    }

    // 좋아요 제거
    public void removeLike(Users user) {
        if (likedUsers.remove(user)) {
            likeCount = Math.max(0, likeCount - 1);
        }
    }

    // 사용자가 좋아요했는지 확인
    public boolean isLikedBy(Users user) {
        return likedUsers.contains(user);
    }

    public Integer getLikeCount() {
        return likeCount == null ? 0 : likeCount;
    }
}