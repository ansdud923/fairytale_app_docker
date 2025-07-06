package com.fairytale.fairytale.baby;

import com.fairytale.fairytale.users.Users;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Entity
@Table(name = "baby", indexes = {
        @Index(name = "idx_baby_name", columnList = "babyName"),
        @Index(name = "idx_baby_birthdate", columnList = "babyBirthDate")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Component
public class Baby {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(length = 100, nullable = false)
    private String babyName;

    @Column(length = 20, nullable = false)
    private String babyGender;

    @Column(nullable = false)
    private LocalDateTime babyBirthDate;

    @CreationTimestamp
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "users_id")
    private Users user;
}
