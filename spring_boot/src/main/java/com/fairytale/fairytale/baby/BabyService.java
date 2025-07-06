package com.fairytale.fairytale.baby;

import com.fairytale.fairytale.users.Users;
import com.fairytale.fairytale.users.UsersRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Service
@RequiredArgsConstructor
@Transactional
public class BabyService {
    private final BabyRepository babyRepository;
    private final UsersRepository usersRepository;

    // 사용자 ID로 아이 정보 조회
    @Transactional(readOnly = true)
    public Baby findByUserId(Long userId) {
        return babyRepository.findByUserId(userId);
    }

    // 아이 정보 생성
    public Baby createBaby(BabyCreateRequest request) {
        // 사용자 조회
        Users user = usersRepository.findById(request.getUserId())
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        // 이미 아이 정보가 있는지 확인
        Baby existingBaby = babyRepository.findByUserId(request.getUserId());
        if (existingBaby != null) {
            throw new RuntimeException("이미 등록된 아이 정보가 있습니다.");
        }

        // 날짜 문자열을 LocalDateTime으로 변환
        LocalDateTime birthDate = parseBirthDate(request.getBirthDate());

        Baby baby = new Baby();
        baby.setBabyName(request.getName());
        baby.setBabyGender(request.getGender() != null ? request.getGender() : "unknown");
        baby.setBabyBirthDate(birthDate);
        baby.setUser(user);

        return babyRepository.save(baby);
    }

    // 아이 정보 수정
    public Baby updateBaby(Long babyId, BabyUpdateRequest request) {
        Baby baby = babyRepository.findById(babyId)
                .orElseThrow(() -> new RuntimeException("아이 정보를 찾을 수 없습니다."));

        if (request.getName() != null) {
            baby.setBabyName(request.getName());
        }
        if (request.getGender() != null) {
            baby.setBabyGender(request.getGender());
        }
        if (request.getBirthDate() != null) {
            LocalDateTime birthDate = parseBirthDate(request.getBirthDate());
            baby.setBabyBirthDate(birthDate);
        }

        return babyRepository.save(baby);
    }

    // 날짜 문자열 파싱 (YYYY-MM-DD 형식)
    private LocalDateTime parseBirthDate(String birthDateStr) {
        try {
            // "2024-03-15" 형식을 LocalDateTime으로 변환
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");
            return java.time.LocalDate.parse(birthDateStr, formatter).atStartOfDay();
        } catch (Exception e) {
            throw new RuntimeException("날짜 형식이 올바르지 않습니다. YYYY-MM-DD 형식으로 입력해주세요.");
        }
    }

    // 아이 정보 삭제
    public void deleteBaby(Long babyId) {
        Baby baby = babyRepository.findById(babyId)
                .orElseThrow(() -> new RuntimeException("아이 정보를 찾을 수 없습니다."));
        babyRepository.delete(baby);
    }
}