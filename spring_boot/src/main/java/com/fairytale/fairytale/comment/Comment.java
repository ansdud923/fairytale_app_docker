// Comment.java - @Data 어노테이션 추가

package com.fairytale.fairytale.comment;

import com.fairytale.fairytale.share.SharePost;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "comments")
@Data // 🎯 @Data 어노테이션 추가 (모든 getter/setter 자동 생성)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Comment {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "share_post_id", nullable = false)
    private SharePost sharePost;

    @Column(nullable = false, length = 100)
    private String username; // 댓글 작성자

    @Column(name = "user_name", length = 100)
    private String userName; // 표시될 이름 (예: "아이이름의 부모")

    @Column(nullable = false, length = 1000)
    private String content; // 댓글 내용

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}