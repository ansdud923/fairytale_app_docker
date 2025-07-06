package com.fairytale.fairytale.story;

import com.fairytale.fairytale.baby.Baby;
import com.fairytale.fairytale.users.Users;
import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "story", indexes = {
        @Index(name = "idx_theme", columnList = "theme"),
        @Index(name = "idx_voice", columnList = "voice"),
        @Index(name = "idx_title", columnList = "title")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Story {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(length = 500, nullable = false)
    private String theme;

    @Column(length = 100, nullable = true)
    private String voice;

    @Column(length = 500, nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String content;

    // nullable = true로 변경 (나중에 추가되는 필드들)
    @Column(length = 500, nullable = true)
    private String voiceContent;

    @Column(name = "image", length = 500, nullable = true)
    @JsonProperty("image")
    private String image;

    @CreationTimestamp
    @Column(updatable = false)
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @JsonProperty("createdAt")
    private LocalDateTime createdAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "users_id")
    @JsonIgnore
    private Users user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "baby_id")  // baby_name이 아니라 baby_id로
    @JsonIgnore
    private Baby baby;  // String이 아니라 Baby 엔티티로

    @Column(name = "child_name")
    private String childName;
}

