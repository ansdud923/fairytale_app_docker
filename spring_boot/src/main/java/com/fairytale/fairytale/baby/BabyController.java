package com.fairytale.fairytale.baby;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/baby")
@RequiredArgsConstructor
@CrossOrigin(origins = "*") // 🆕 CORS 문제 해결
public class BabyController {
    private final BabyService babyService;

    // 사용자의 아이 정보 조회
    @GetMapping
    public ResponseEntity<Map<String, Object>> getUserBaby(@RequestParam Long userId) {
        System.out.println("🔍 ===== 아이 정보 조회 요청 =====");
        System.out.println("🔍 요청된 userId: " + userId);

        Map<String, Object> response = new HashMap<>();

        try {
            Baby baby = babyService.findByUserId(userId);
            System.out.println("🔍 조회된 아이 정보: " + (baby != null ? baby.getBabyName() + " (" + baby.getId() + ")" : "없음"));

            if (baby != null) {
                Map<String, Object> babyData = new HashMap<>();
                babyData.put("id", baby.getId());
                babyData.put("name", baby.getBabyName());
                babyData.put("gender", baby.getBabyGender());
                babyData.put("birthDate", baby.getBabyBirthDate().toLocalDate().toString()); // 🔧 LocalDate로 변환

                response.put("success", true);
                response.put("data", babyData);
                response.put("hasChild", true);

                System.out.println("✅ 아이 정보 조회 성공: " + baby.getBabyName());
            } else {
                response.put("success", true);
                response.put("data", null);
                response.put("hasChild", false);

                System.out.println("✅ 아이 정보 없음 - hasChild: false");
            }

            System.out.println("🔍 응답 데이터: " + response);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            System.err.println("❌ 아이 정보 조회 오류: " + e.getMessage());
            e.printStackTrace();

            response.put("success", false);
            response.put("message", "아이 정보 조회에 실패했습니다: " + e.getMessage());
            response.put("hasChild", false); // 🆕 오류 시에도 hasChild 추가
            return ResponseEntity.badRequest().body(response);
        }
    }

    // 아이 정보 저장
    @PostMapping
    public ResponseEntity<Map<String, Object>> createBaby(@RequestBody BabyCreateRequest request) {
        System.out.println("🔍 ===== 아이 정보 저장 요청 =====");
        System.out.println("🔍 요청 데이터: userId=" + request.getUserId() + ", name=" + request.getName() +
                ", gender=" + request.getGender() + ", birthDate=" + request.getBirthDate());

        Map<String, Object> response = new HashMap<>();

        try {
            Baby savedBaby = babyService.createBaby(request);
            System.out.println("✅ 아이 정보 저장 성공: " + savedBaby.getBabyName() + " (ID: " + savedBaby.getId() + ")");

            Map<String, Object> babyData = new HashMap<>();
            babyData.put("id", savedBaby.getId());
            babyData.put("name", savedBaby.getBabyName());
            babyData.put("gender", savedBaby.getBabyGender());
            babyData.put("birthDate", savedBaby.getBabyBirthDate().toLocalDate().toString()); // 🔧 LocalDate로 변환

            response.put("success", true);
            response.put("data", babyData);
            response.put("message", "아이 정보가 성공적으로 저장되었습니다.");

            System.out.println("🔍 저장 응답: " + response);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            System.err.println("❌ 아이 정보 저장 오류: " + e.getMessage());
            e.printStackTrace();

            response.put("success", false);
            response.put("message", "아이 정보 저장에 실패했습니다: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    // 아이 정보 수정
    @PutMapping("/{babyId}")
    public ResponseEntity<Map<String, Object>> updateBaby(
            @PathVariable Long babyId,
            @RequestBody BabyUpdateRequest request) {
        System.out.println("🔍 ===== 아이 정보 수정 요청 =====");
        System.out.println("🔍 babyId: " + babyId + ", 수정 데이터: " + request.getName());

        Map<String, Object> response = new HashMap<>();

        try {
            Baby updatedBaby = babyService.updateBaby(babyId, request);
            System.out.println("✅ 아이 정보 수정 성공: " + updatedBaby.getBabyName());

            Map<String, Object> babyData = new HashMap<>();
            babyData.put("id", updatedBaby.getId());
            babyData.put("name", updatedBaby.getBabyName());
            babyData.put("gender", updatedBaby.getBabyGender());
            babyData.put("birthDate", updatedBaby.getBabyBirthDate().toLocalDate().toString()); // 🔧 LocalDate로 변환

            response.put("success", true);
            response.put("data", babyData);
            response.put("message", "아이 정보가 성공적으로 수정되었습니다.");

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            System.err.println("❌ 아이 정보 수정 오류: " + e.getMessage());
            e.printStackTrace();

            response.put("success", false);
            response.put("message", "아이 정보 수정에 실패했습니다: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }
}