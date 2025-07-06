package com.fairytale.fairytale.gallery;

import com.fairytale.fairytale.users.Users;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(name = "gallery")
@Getter
@Setter
@EntityListeners(AuditingEntityListener.class)
public class Gallery {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "story_id", nullable = false)
    private Long storyId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private Users user;

    @Column(name = "story_title")
    private String storyTitle;

    @Column(name = "color_image_url", length = 1000)
    private String colorImageUrl;      // 컬러 이미지 URL (참조용)

    @Column(name = "coloring_image_url", length = 1000)
    private String coloringImageUrl;   // 사용자가 색칠한 이미지 URL

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Column(name = "child_name")
    private String childName;
}