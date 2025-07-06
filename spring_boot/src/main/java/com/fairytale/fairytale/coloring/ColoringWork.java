package com.fairytale.fairytale.coloring;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "coloring_works")
@Getter
@Setter
public class ColoringWork {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String username; // 사용자명

    @Column(name = "story_title", length = 500)
    private String storyTitle; // 동화 제목

    @Column(name = "original_image_url", length = 1000)
    private String originalImageUrl; // 원본 템플릿 이미지 URL

    @Column(name = "completed_image_url", nullable = false, length = 1000)
    private String completedImageUrl; // 색칠 완성한 이미지 URL

    @Column(name = "template_id")
    private Long templateId; // 사용한 템플릿 ID (선택사항)

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    // 기본 생성자
    public ColoringWork() {
    }

    // Builder 패턴용 생성자
    public ColoringWork(String username, String storyTitle, String originalImageUrl,
                        String completedImageUrl, Long templateId) {
        this.username = username;
        this.storyTitle = storyTitle;
        this.originalImageUrl = originalImageUrl;
        this.completedImageUrl = completedImageUrl;
        this.templateId = templateId;
    }

    // Builder 패턴
    public static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private String username;
        private String storyTitle;
        private String originalImageUrl;
        private String completedImageUrl;
        private Long templateId;

        public Builder username(String username) {
            this.username = username;
            return this;
        }

        public Builder storyTitle(String storyTitle) {
            this.storyTitle = storyTitle;
            return this;
        }

        public Builder originalImageUrl(String originalImageUrl) {
            this.originalImageUrl = originalImageUrl;
            return this;
        }

        public Builder completedImageUrl(String completedImageUrl) {
            this.completedImageUrl = completedImageUrl;
            return this;
        }

        public Builder templateId(Long templateId) {
            this.templateId = templateId;
            return this;
        }

        public ColoringWork build() {
            return new ColoringWork(username, storyTitle, originalImageUrl,
                    completedImageUrl, templateId);
        }
    }

    @Override
    public String toString() {
        return "ColoringWork{" +
                "id=" + id +
                ", username='" + username + '\'' +
                ", storyTitle='" + storyTitle + '\'' +
                ", originalImageUrl='" + originalImageUrl + '\'' +
                ", completedImageUrl='" + completedImageUrl + '\'' +
                ", templateId=" + templateId +
                ", createdAt=" + createdAt +
                '}';
    }
}