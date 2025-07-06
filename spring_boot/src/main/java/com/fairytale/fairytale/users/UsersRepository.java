package com.fairytale.fairytale.users;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UsersRepository extends JpaRepository<Users,Long> {
    Optional<Users> findByEmail(String email);
    Optional<Users> findByUsername(String username);

    Optional<Users> findByGoogleId(String googleId);
    Optional<Users> findByKakaoId(String kakaoId);

    Optional<Object> findByNickname(String nickname);
}
