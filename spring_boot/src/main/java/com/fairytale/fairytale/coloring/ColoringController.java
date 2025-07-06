// ColoringController.java - 정리된 버전 (중복 제거)

package com.fairytale.fairytale.coloring;

import com.fairytale.fairytale.service.S3Service;
import com.fairytale.fairytale.share.ShareService;
import com.fairytale.fairytale.users.Users;
import com.fairytale.fairytale.users.UsersRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/coloring")
public class ColoringController {
    private final ColoringTemplateService coloringTemplateService;
    private final ColoringWorkRepository coloringWorkRepository;
    private final S3Service s3Service;
    private final ShareService shareService;
    private final UsersRepository usersRepository;

    // ColoringController.java - getMyColoringTemplates 메서드만 교체

    @GetMapping("/templates")
    public ResponseEntity<Map<String, Object>> getMyColoringTemplates(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            Authentication auth) {
        System.err.println("=== 컨트롤러 실행됨 ===");
        // 🎯 임시 하드코딩으로 문제 우회
        // 로그에서 확인된 실제 사용자명

        log.info("🔍 [임시] 색칠공부 템플릿 목록 조회 - User: {}, page: {}, size: {}", auth.getName(), page, size);

        try {
            Page<ColoringTemplate> templates = coloringTemplateService
                    .getAllTemplatesByUser(auth.getName(), PageRequest.of(page, size));

            List<Map<String, Object>> templateList = templates.getContent()
                    .stream()
                    .map(this::convertToDTO)
                    .collect(Collectors.toList());

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("templates", templateList);
            response.put("totalElements", templates.getTotalElements());
            response.put("totalPages", templates.getTotalPages());
            response.put("currentPage", page);

            log.info("✅ [임시] 색칠공부 템플릿 {}개 조회 성공", templateList.size());
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 색칠공부 템플릿 조회 오류: {}", e.getMessage());
            return ResponseEntity.status(500)
                    .body(Map.of("success", false, "error", "템플릿 조회 실패"));
        }
    }
//
//    // 🎯 내 색칠공부 템플릿 목록 조회 (사용자별)
//    @GetMapping("/templates")
//    public ResponseEntity<Map<String, Object>> getMyColoringTemplates(
//            @RequestParam(defaultValue = "0") int page,
//            @RequestParam(defaultValue = "10") int size,
//            Authentication authentication) {
//
//        // 🔍 Authentication null 체크 추가
//        if (authentication == null) {
//            log.error("❌ Authentication 객체가 null입니다");
//            return ResponseEntity.status(401).body(Map.of(
//                    "success", false,
//                    "error", "인증이 필요합니다"
//            ));
//        }
//
//        String username = authentication.getName();
//
//        // 🔍 사용자명 null 체크 추가
//        if (username == null || username.trim().isEmpty()) {
//            log.error("❌ 사용자명이 null이거나 비어있습니다");
//            return ResponseEntity.status(401).body(Map.of(
//                    "success", false,
//                    "error", "유효하지 않은 사용자 정보입니다"
//            ));
//        }
//
//        log.info("🔍 내 색칠공부 템플릿 목록 조회 요청 - User: {}, page: {}, size: {}", username, page, size);
//
//        try {
//            Page<ColoringTemplate> templates = coloringTemplateService
//                    .getAllTemplatesByUser(username, PageRequest.of(page, size));
//
//            List<Map<String, Object>> templateList = templates.getContent()
//                    .stream()
//                    .map(this::convertToDTO)
//                    .collect(Collectors.toList());
//
//            Map<String, Object> response = new HashMap<>();
//            response.put("success", true);
//            response.put("templates", templateList);
//            response.put("totalElements", templates.getTotalElements());
//            response.put("totalPages", templates.getTotalPages());
//            response.put("currentPage", page);
//
//            log.info("✅ 내 색칠공부 템플릿 {}개 조회 성공", templateList.size());
//            return ResponseEntity.ok(response);
//
//        } catch (Exception e) {
//            log.error("❌ 색칠공부 템플릿 조회 오류: {}", e.getMessage());
//            return ResponseEntity.status(500)
//                    .body(Map.of("success", false, "error", "템플릿 조회 실패"));
//        }
//    }

    // 🎯 내 특정 템플릿 상세 조회 (사용자별)
    @GetMapping("/templates/{templateId}")
    public ResponseEntity<Map<String, Object>> getMyTemplateDetail(
            @PathVariable Long templateId,
            Authentication authentication) {

        String username = authentication.getName();
        log.info("🔍 내 색칠공부 템플릿 상세 조회 - ID: {}, User: {}", templateId, username);

        try {
            ColoringTemplate template = coloringTemplateService.getTemplateByIdAndUser(templateId, username);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("template", convertToDTO(template));

            log.info("✅ 내 색칠공부 템플릿 상세 조회 성공: {}", template.getTitle());
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 색칠공부 템플릿 상세 조회 오류: {}", e.getMessage());
            return ResponseEntity.status(404)
                    .body(Map.of("success", false, "error", "템플릿을 찾을 수 없습니다"));
        }
    }

    // 🎯 내 동화 ID로 색칠공부 템플릿 조회 (사용자별)
    @GetMapping("/templates/story/{storyId}")
    public ResponseEntity<Map<String, Object>> getMyTemplateByStoryId(
            @PathVariable String storyId,
            Authentication authentication) {

        String username = authentication.getName();
        log.info("🔍 내 동화별 색칠공부 템플릿 조회 - StoryId: {}, User: {}", storyId, username);

        try {
            return coloringTemplateService.getTemplateByStoryIdAndUser(storyId, username)
                    .map(template -> {
                        Map<String, Object> response = new HashMap<>();
                        response.put("success", true);
                        response.put("template", convertToDTO(template));
                        return ResponseEntity.ok(response);
                    })
                    .orElse(ResponseEntity.status(404)
                            .body(Map.of("success", false, "error", "해당 동화의 색칠공부 템플릿이 없습니다")));

        } catch (Exception e) {
            log.error("❌ 동화별 색칠공부 템플릿 조회 오류: {}", e.getMessage());
            return ResponseEntity.status(500)
                    .body(Map.of("success", false, "error", "조회 실패"));
        }
    }

    // 🎯 내 색칠공부 템플릿 검색 (사용자별)
    @GetMapping("/templates/search")
    public ResponseEntity<Map<String, Object>> searchMyTemplates(
            @RequestParam String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            Authentication authentication) {

        String username = authentication.getName();
        log.info("🔍 내 색칠공부 템플릿 검색 - 키워드: {}, User: {}", keyword, username);

        try {
            Page<ColoringTemplate> templates = coloringTemplateService
                    .searchTemplatesByTitleAndUser(keyword, username, PageRequest.of(page, size));

            List<Map<String, Object>> templateList = templates.getContent()
                    .stream()
                    .map(this::convertToDTO)
                    .collect(Collectors.toList());

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("templates", templateList);
            response.put("totalElements", templates.getTotalElements());
            response.put("keyword", keyword);

            log.info("✅ 내 색칠공부 템플릿 검색 완료 - {}개 발견", templateList.size());
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 색칠공부 템플릿 검색 오류: {}", e.getMessage());
            return ResponseEntity.status(500)
                    .body(Map.of("success", false, "error", "검색 실패"));
        }
    }

    // 🎯 색칠공부 템플릿 생성 API (사용자 정보 포함)
    @PostMapping("/create-template")
    public ResponseEntity<Map<String, Object>> createMyColoringTemplate(
            @RequestBody Map<String, String> request,
            Authentication authentication) {

        String username = authentication.getName();
        log.info("🎨 내 색칠공부 템플릿 생성 요청 - User: {}", username);

        try {
            String storyId = request.get("storyId");
            String title = request.get("title");
            String originalImageUrl = request.get("originalImageUrl");
            String blackWhiteImageUrl = request.get("blackWhiteImageUrl");

            log.info("🎨 템플릿 생성 파라미터:");
            log.info("  - storyId: {}", storyId);
            log.info("  - title: {}", title);
            log.info("  - originalImageUrl: {}", originalImageUrl);
            log.info("  - username: {}", username);

            if (storyId == null || title == null || originalImageUrl == null) {
                return ResponseEntity.status(400).body(Map.of(
                        "success", false,
                        "error", "필수 파라미터가 누락되었습니다."
                ));
            }

            Users user = usersRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + username));

            // 🎯 사용자 정보 포함하여 템플릿 생성
            ColoringTemplate template = coloringTemplateService.createColoringTemplate(
                    storyId,
                    title,
                    originalImageUrl,
                    blackWhiteImageUrl,
                    user
            );

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "색칠공부 템플릿이 생성되었습니다!");
            response.put("template", convertToDTO(template));

            log.info("✅ 내 색칠공부 템플릿 생성 완료 - ID: {}", template.getId());
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 색칠공부 템플릿 생성 오류: {}", e.getMessage());
            return ResponseEntity.status(500).body(Map.of(
                    "success", false,
                    "error", "템플릿 생성 실패: " + e.getMessage()
            ));
        }
    }

    // 🎯 색칠 완성작 저장 (Base64 이미지)
    @PostMapping("/save")
    public ResponseEntity<Map<String, Object>> saveMyColoredImage(
            @RequestBody Map<String, Object> request,
            Authentication authentication) {

        String username = authentication.getName();
        log.info("🎨 내 색칠 완성작 저장 요청 (Base64) - User: {}", username);

        try {
            String originalImageUrl = (String) request.get("originalImageUrl");
            String completedImageBase64 = (String) request.get("completedImageBase64");
            String storyTitle = (String) request.get("storyTitle");

            log.info("🎨 원본 이미지: {}", originalImageUrl);
            log.info("🎨 Base64 이미지 길이: {}",
                    (completedImageBase64 != null ? completedImageBase64.length() : "null"));

            if (originalImageUrl == null || completedImageBase64 == null) {
                return ResponseEntity.status(400).body(Map.of(
                        "success", false,
                        "error", "필수 파라미터가 누락되었습니다."
                ));
            }

            String savedImageUrl = saveBase64ImageToStorage(completedImageBase64, username);

            ColoringWork coloringWork = ColoringWork.builder()
                    .username(username)
                    .originalImageUrl(originalImageUrl)
                    .completedImageUrl(savedImageUrl)
                    .storyTitle(storyTitle != null ? storyTitle : "색칠 완성작")
                    .build();

            ColoringWork saved = coloringWorkRepository.save(coloringWork);
            log.info("✅ DB에 내 색칠 완성작 저장 완료: {}", saved.getId());

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "색칠 완성작이 갤러리에 저장되었습니다!");
            response.put("savedImageUrl", savedImageUrl);
            response.put("coloringWorkId", saved.getId());
            response.put("savedAt", java.time.LocalDateTime.now().toString());

            log.info("✅ 내 색칠 완성작 저장 완료 - URL: {}", savedImageUrl);
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 색칠 완성작 저장 오류: {}", e.getMessage());
            return ResponseEntity.status(500).body(Map.of(
                    "success", false,
                    "error", "저장 실패: " + e.getMessage()
            ));
        }
    }

    // 🎯 개선된 색칠 완성작 저장 (MultipartFile)
    @PostMapping("/save-coloring-work")
    public ResponseEntity<?> saveMyColoringWork(
            @RequestParam("storyId") String storyId,
            @RequestParam(value = "originalImageUrl", required = false) String originalImageUrl,
            @RequestParam("coloredImage") MultipartFile coloredImage,
            Authentication authentication) {

        String username = authentication.getName();
        log.info("🎨 내 색칠 완성작 저장 요청 - StoryId: {}, User: {}", storyId, username);

        try {
            // 🎯 Users 엔티티 조회
            Users user = usersRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + username));
            ColoringTemplate template = coloringTemplateService.getTemplateByStoryIdAndUser(storyId, username)
                    .orElseGet(() -> {
                        log.info("🔄 내 템플릿이 없어서 새로 생성 - StoryId: {}, User: {}", storyId, username);
                        try {
                            return coloringTemplateService.createColoringTemplate(
                                    storyId,
                                    "색칠 템플릿 " + storyId,
                                    originalImageUrl != null ? originalImageUrl : "",
                                    null,
                                    user
                            );
                        } catch (Exception e) {
                            log.error("템플릿 생성 실패: {}", e.getMessage());
                            throw new RuntimeException("템플릿 생성에 실패했습니다: " + e.getMessage());
                        }
                    });

            String coloredImageUrl = s3Service.uploadColoringWork(coloredImage, username, storyId);

            ColoringWork coloringWork = ColoringWork.builder()
                    .username(username)
                    .storyTitle(template.getTitle())
                    .originalImageUrl(template.getOriginalImageUrl())
                    .completedImageUrl(coloredImageUrl)
                    .templateId(template.getId())
                    .build();

            ColoringWork savedWork = coloringWorkRepository.save(coloringWork);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("coloringWorkId", savedWork.getId());
            response.put("coloredImageUrl", coloredImageUrl);
            response.put("message", "색칠 완성작이 갤러리에 저장되었습니다!");

            log.info("✅ 내 색칠 완성작 저장 완료 - ID: {}", savedWork.getId());
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 색칠 완성작 저장 실패: {}", e.getMessage());
            return ResponseEntity.status(500).body(Map.of(
                    "success", false,
                    "error", "색칠 완성작 저장 실패: " + e.getMessage()
            ));
        }
    }

    // 🎯 색칠 완성작 공유 API
    @PostMapping("/share/{coloringWorkId}")
    public ResponseEntity<Map<String, Object>> shareMyColoringWork(
            @PathVariable Long coloringWorkId,
            Authentication authentication) {

        String username = authentication.getName();
        log.info("🎨 내 색칠 완성작 공유 요청 - ColoringWorkId: {}, User: {}", coloringWorkId, username);

        try {
            ColoringWork coloringWork = coloringWorkRepository.findById(coloringWorkId)
                    .orElseThrow(() -> new RuntimeException("색칠 완성작을 찾을 수 없습니다."));

            if (!coloringWork.getUsername().equals(username)) {
                log.error("❌ 권한 없음 - 작품 소유자: {}, 요청자: {}", coloringWork.getUsername(), username);
                return ResponseEntity.status(403)
                        .body(Map.of("success", false, "error", "본인의 작품만 공유할 수 있습니다."));
            }

            var sharePostDTO = shareService.shareFromColoringWork(coloringWorkId, username);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "색칠 완성작이 성공적으로 공유되었습니다!");
            response.put("shareId", sharePostDTO.getId());
            response.put("coloringWorkId", coloringWorkId);

            log.info("✅ 내 색칠 완성작 공유 완료 - ShareId: {}", sharePostDTO.getId());
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 색칠 완성작 공유 실패: {}", e.getMessage());
            return ResponseEntity.status(500)
                    .body(Map.of("success", false, "error", "공유 실패: " + e.getMessage()));
        }
    }

    // 🎯 내 색칠공부 템플릿 삭제
    @DeleteMapping("/templates/{templateId}")
    public ResponseEntity<Map<String, Object>> deleteMyTemplate(
            @PathVariable Long templateId,
            Authentication authentication) {

        String username = authentication.getName();
        log.info("🗑️ 내 색칠공부 템플릿 삭제 요청 - ID: {}, User: {}", templateId, username);

        try {
            coloringTemplateService.deleteTemplateByUser(templateId, username);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "템플릿이 삭제되었습니다.");

            log.info("✅ 내 색칠공부 템플릿 삭제 완료 - ID: {}", templateId);
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 색칠공부 템플릿 삭제 실패: {}", e.getMessage());
            return ResponseEntity.status(500)
                    .body(Map.of("success", false, "error", "템플릿 삭제 실패: " + e.getMessage()));
        }
    }

    // ====== Private 헬퍼 메서드들 ======

    private String saveBase64ImageToStorage(String base64Image, String username) {
        try {
            log.info("🔍 Base64 이미지 저장 시작");
            byte[] imageBytes = java.util.Base64.getDecoder().decode(base64Image);
            String fileName = "coloring_" + username + "_" + System.currentTimeMillis() + ".png";
            return saveToLocalStorage(imageBytes, fileName);
        } catch (Exception e) {
            log.error("❌ 이미지 저장 실패: {}", e.getMessage());
            throw new RuntimeException("이미지 저장에 실패했습니다", e);
        }
    }

    private String saveToLocalStorage(byte[] imageBytes, String fileName) {
        try {
            String uploadDir = "src/main/resources/static/coloring/";
            java.nio.file.Path uploadPath = java.nio.file.Paths.get(uploadDir);

            if (!java.nio.file.Files.exists(uploadPath)) {
                java.nio.file.Files.createDirectories(uploadPath);
            }

            java.nio.file.Path filePath = uploadPath.resolve(fileName);
            try (java.io.FileOutputStream fos = new java.io.FileOutputStream(filePath.toFile())) {
                fos.write(imageBytes);
            }

            log.info("✅ 로컬 저장 완료: {}", fileName);
            return "http://localhost:8080/coloring/" + fileName;

        } catch (Exception e) {
            log.error("❌ 로컬 저장 실패: {}", e.getMessage());
            throw new RuntimeException("로컬 이미지 저장에 실패했습니다", e);
        }
    }

    private Map<String, Object> convertToDTO(ColoringTemplate template) {
        Map<String, Object> dto = new HashMap<>();
        dto.put("id", template.getId().toString());
        dto.put("title", template.getTitle());
        dto.put("storyId", template.getStoryId());
        dto.put("imageUrl", template.getBlackWhiteImageUrl());
        dto.put("originalImageUrl", template.getOriginalImageUrl());
        dto.put("storyTitle", template.getTitle());
        dto.put("createdAt", template.getCreatedAt().format(
                DateTimeFormatter.ofPattern("yyyy-MM-dd")));
        return dto;
    }
}