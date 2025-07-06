package com.fairytale.fairytale.users;

import com.fairytale.fairytale.article.Article;
import com.fairytale.fairytale.baby.Baby;
import com.fairytale.fairytale.coloring.ColoringTemplate;
import com.fairytale.fairytale.like.Like;
import com.fairytale.fairytale.role.Role;
import com.fairytale.fairytale.story.Story;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "users", indexes = {
        @Index(name = "idx_user_username", columnList = "username"),
        @Index(name = "idx_user_nickname", columnList = "nickname"),
        @Index(name = "idx_user_email", columnList = "email"),
        @Index(name = "idx_user_google_id", columnList = "googleId"),
        @Index(name = "idx_user_kakao_id", columnList = "kakaoId"),
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Users {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 100)
    private String username;

    @Column(nullable = false, unique = true, length = 100)
    private String nickname;

    @Column(unique = true, length = 200)
    private String email;

    @Column(length = 512)
    private String hashedPassword;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "role_id")
    private Role role;

    @Column(unique = true, length = 100)
    private String googleId;

    @Column(unique = true, length = 100)
    private String kakaoId;

    @Column(name = "profile_image_url", length = 500)
    private String profileImageUrl;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
    private List<Story> stories;

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
    private List<Article> articles;

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
    private List<Baby> babies;

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
    private List<Like> likes;

    // 🎯 ColoringTemplate 관계 추가 (누락된 부분!)
    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
    private List<ColoringTemplate> coloringTemplates;

    /**
     * 🎯 getUsername() 메서드 - Lombok @Getter로 자동 생성되어야 하지만 명시적으로 추가
     * (실제로는 @Getter 어노테이션이 이미 있어서 자동 생성되어야 하는데,
     *  혹시 다른 이유로 인식이 안 될 수 있어서 명시적으로 추가)
     */
    public String getUsername() {
        return this.username;
    }

    /**
     * 사용자 표시명 반환 (nickname 우선, 없으면 username)
     */
    public String getName() {
        if (nickname != null && !nickname.trim().isEmpty()) {
            return nickname;
        }
        return username;
    }

    /**
     * 🎯 getUserName() 메서드 추가 (CommentService에서 호출)
     * getName()과 동일한 로직
     */
    public String getUserName() {
        return getName(); // 기존 getName() 메서드 재활용
    }

    /**
     * 🎯 사용자의 첫 번째 아기 이름으로 표시명 생성
     */
    public String getDisplayNameWithBaby() {
        try {
            // Baby 정보에서 아이 이름 조회
            if (babies != null && !babies.isEmpty()) {
                Baby firstBaby = babies.get(0);
                String babyName = firstBaby.getBabyName();

                if (babyName != null && !babyName.trim().isEmpty()) {
                    return babyName + "의 부모";
                }
            }

            // Baby 정보가 없으면 기본 이름 사용
            return getName() + "님";

        } catch (Exception e) {
            // 오류 발생 시 기본 이름 반환
            return getName() + "님";
        }
    }
}