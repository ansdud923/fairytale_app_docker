package com.fairytale.fairytale.users;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class UsersService {
    private final UsersRepository usersRepository;

    /**
     * 프로필 이미지 URL 업데이트
     */
    public void updateProfileImageUrl(Long userId, String profileImageUrl) {
        try {
            log.info("🔍 [UsersService] 프로필 이미지 URL 업데이트: userId={}, url={}", userId, profileImageUrl);

            Optional<Users> userOptional = usersRepository.findById(userId);

            if (userOptional.isPresent()) {
                Users user = userOptional.get();
                user.setProfileImageUrl(profileImageUrl);
                usersRepository.save(user);

                log.info("✅ [UsersService] 프로필 이미지 URL 업데이트 성공: userId={}", userId);
            } else {
                log.error("❌ [UsersService] 사용자를 찾을 수 없음: userId={}", userId);
                throw new RuntimeException("사용자를 찾을 수 없습니다.");
            }

        } catch (Exception e) {
            log.error("❌ [UsersService] 프로필 이미지 URL 업데이트 실패: userId={}, error={}", userId, e.getMessage());
            throw new RuntimeException("프로필 이미지 URL 업데이트에 실패했습니다.", e);
        }
    }

    /**
     * 사용자 프로필 이미지 URL 조회
     */
    public String getProfileImageUrl(Long userId) {
        try {
            log.info("🔍 [UsersService] 프로필 이미지 URL 조회: userId={}", userId);

            Optional<Users> userOptional = usersRepository.findById(userId);

            if (userOptional.isPresent()) {
                String profileImageUrl = userOptional.get().getProfileImageUrl();
                log.info("✅ [UsersService] 프로필 이미지 URL 조회 성공: userId={}, url={}", userId, profileImageUrl);
                return profileImageUrl;
            } else {
                log.warn("⚠️ [UsersService] 사용자를 찾을 수 없음: userId={}", userId);
                return null;
            }

        } catch (Exception e) {
            log.error("❌ [UsersService] 프로필 이미지 URL 조회 실패: userId={}, error={}", userId, e.getMessage());
            return null;
        }
    }

    /**
     * 사용자 정보 조회
     */
    public Users getUserById(Long userId) {
        try {
            log.info("🔍 [UsersService] 사용자 정보 조회: userId={}", userId);

            Optional<Users> userOptional = usersRepository.findById(userId);

            if (userOptional.isPresent()) {
                log.info("✅ [UsersService] 사용자 정보 조회 성공: userId={}", userId);
                return userOptional.get();
            } else {
                log.warn("⚠️ [UsersService] 사용자를 찾을 수 없음: userId={}", userId);
                return null;
            }

        } catch (Exception e) {
            log.error("❌ [UsersService] 사용자 정보 조회 실패: userId={}, error={}", userId, e.getMessage());
            return null;
        }
    }

    /**
     * 프로필 이미지 URL 삭제
     */
    public void removeProfileImageUrl(Long userId) {
        try {
            log.info("🔍 [UsersService] 프로필 이미지 URL 삭제: userId={}", userId);

            Optional<Users> userOptional = usersRepository.findById(userId);

            if (userOptional.isPresent()) {
                Users user = userOptional.get();
                user.setProfileImageUrl(null);
                usersRepository.save(user);

                log.info("✅ [UsersService] 프로필 이미지 URL 삭제 성공: userId={}", userId);
            } else {
                log.error("❌ [UsersService] 사용자를 찾을 수 없음: userId={}", userId);
                throw new RuntimeException("사용자를 찾을 수 없습니다.");
            }

        } catch (Exception e) {
            log.error("❌ [UsersService] 프로필 이미지 URL 삭제 실패: userId={}, error={}", userId, e.getMessage());
            throw new RuntimeException("프로필 이미지 URL 삭제에 실패했습니다.", e);
        }
    }
}