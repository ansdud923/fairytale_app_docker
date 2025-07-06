package com.fairytale.fairytale.coloring;

import com.fairytale.fairytale.service.S3Service;
import com.fairytale.fairytale.story.StoryService;
import com.fairytale.fairytale.users.Users;
import com.fairytale.fairytale.users.UsersRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Lazy;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;
import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class ColoringTemplateService {
    private final ColoringTemplateRepository coloringTemplateRepository;
    private final S3Service s3Service;
    @Lazy
    private final StoryService storyService; // 직접 주입!
    private final RestTemplate restTemplate = new RestTemplate();
    @Value("${FASTAPI_BASE_URL:http://localhost:8000}")
    private String fastApiBaseUrl;
    private final UsersRepository usersRepository;

    // 🎯 색칠공부 템플릿 생성 (사용자 정보 포함)
    @Transactional
    public ColoringTemplate createColoringTemplate(String storyId, String title,
                                                   String originalImageUrl, String blackWhiteImageUrl,
                                                   Users user) { // 🎯 user 파라미터 추가

        System.out.println("🎨 [ColoringTemplateService] 색칠공부 템플릿 생성 시작 - StoryId: " + storyId + ", User: " + user.getUsername());

        // 🎯 흑백 이미지가 없으면 변환
        if (blackWhiteImageUrl == null || blackWhiteImageUrl.trim().isEmpty()) {
            System.out.println("🔄 [ColoringTemplateService] 온디맨드 흑백 변환 시작");
            blackWhiteImageUrl = convertImageToColoringBook(originalImageUrl);
        }

        // 🎯 기존 템플릿 확인 (사용자별로)
        Optional<ColoringTemplate> existing = coloringTemplateRepository.findByStoryIdAndUser(storyId, user);

        ColoringTemplate template;
        if (existing.isPresent()) {
            System.out.println("🔄 [ColoringTemplateService] 기존 템플릿 업데이트");
            template = existing.get();
            template.setTitle(title);
            template.setOriginalImageUrl(originalImageUrl);
            template.setBlackWhiteImageUrl(blackWhiteImageUrl);
            template.setUser(user); // 🎯 이 줄 추가!
        } else {
            System.out.println("🆕 [ColoringTemplateService] 새 템플릿 생성");
            template = ColoringTemplate.builder()
                    .title(title)
                    .storyId(storyId)
                    .originalImageUrl(originalImageUrl)
                    .blackWhiteImageUrl(blackWhiteImageUrl)
                    .user(user) // 🎯 .users(user) → .user(user)로 변경
                    .build();
        }

        ColoringTemplate savedTemplate = coloringTemplateRepository.save(template);
        System.out.println("✅ [ColoringTemplateService] 색칠공부 템플릿 저장 완료 - ID: " + savedTemplate.getId());

        return savedTemplate;
    }

    // 🎯 오버로드 메서드 (기존 호출 방식 호환성)
    public ColoringTemplate createColoringTemplate(String storyId, String title,
                                                   String originalImageUrl, String blackWhiteImageUrl) {
        // 🚫 사용자 정보 없이 호출되면 에러
        throw new RuntimeException("색칠공부 템플릿 생성 시 사용자 정보가 필요합니다. createColoringTemplate(storyId, title, originalImageUrl, blackWhiteImageUrl, user)를 사용하세요.");
    }

    // ====== 사용자별 조회 메서드들 ======

    // 🎯 사용자별 모든 색칠공부 템플릿 조회
    @Transactional(readOnly = true)
    public Page<ColoringTemplate> getAllTemplatesByUser(String username, Pageable pageable) {
        System.out.println("🔍 [ColoringTemplateService] 사용자별 색칠공부 템플릿 목록 조회 - User: " + username);

        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + username));

        return coloringTemplateRepository.findByUserOrderByCreatedAtDesc(user, pageable);
    }

    // 🎯 사용자별 특정 템플릿 조회
    public ColoringTemplate getTemplateByIdAndUser(Long templateId, String username) {
        System.out.println("🔍 [ColoringTemplateService] 사용자별 색칠공부 템플릿 상세 조회 - ID: " + templateId + ", User: " + username);

        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + username));

        ColoringTemplate template = coloringTemplateRepository.findById(templateId)
                .orElseThrow(() -> new RuntimeException("색칠공부 템플릿을 찾을 수 없습니다: " + templateId));

        // 🎯 본인의 템플릿인지 확인
        if (!template.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("접근 권한이 없습니다. 본인의 색칠공부 템플릿만 조회할 수 있습니다.");
        }

        return template;
    }

    // 🎯 사용자별 제목으로 검색
    public Page<ColoringTemplate> searchTemplatesByTitleAndUser(String keyword, String username, Pageable pageable) {
        System.out.println("🔍 [ColoringTemplateService] 사용자별 색칠공부 템플릿 검색 - 키워드: " + keyword + ", User: " + username);

        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + username));

        return coloringTemplateRepository.findByUserAndTitleContainingOrderByCreatedAtDesc(user, keyword, pageable);
    }

    // 🎯 사용자별 템플릿 삭제
    @Transactional
    public void deleteTemplateByUser(Long templateId, String username) {
        System.out.println("🗑️ [ColoringTemplateService] 사용자별 색칠공부 템플릿 삭제 - ID: " + templateId + ", User: " + username);

        ColoringTemplate template = getTemplateByIdAndUser(templateId, username); // 권한 확인 포함
        coloringTemplateRepository.delete(template);

        System.out.println("✅ [ColoringTemplateService] 색칠공부 템플릿 삭제 완료");
    }

    // 🎯 효율적인 흑백 변환 (기존 이미지 우선 검색)
    private String convertImageToColoringBook(String originalImageUrl) {
        try {
            System.out.println("🔍 [ColoringTemplateService] 온디맨드 흑백 변환: " + originalImageUrl);

            // 1. S3 URL인 경우 기존 흑백 이미지 먼저 확인
            if (originalImageUrl.startsWith("http") && originalImageUrl.contains("amazonaws.com")) {
                String existingBwUrl = findExistingBlackWhiteImageInS3(originalImageUrl);
                if (existingBwUrl != null) {
                    System.out.println("✅ [ColoringTemplateService] 기존 흑백 이미지 재사용: " + existingBwUrl);
                    return existingBwUrl;
                }
            }

            // 2. 기존 이미지 없으면 StoryService로 새로 변환
            System.out.println("🔄 [ColoringTemplateService] StoryService로 새 변환 요청");
            String blackWhiteUrl = callStoryServiceDirectly(originalImageUrl);

            System.out.println("✅ [ColoringTemplateService] 흑백 변환 완료: " + blackWhiteUrl);
            return blackWhiteUrl;

        } catch (Exception e) {
            System.err.println("❌ [ColoringTemplateService] 흑백 변환 실패: " + e.getMessage());
            return originalImageUrl;
        }
    }

    // 🚀 StoryService 직접 호출 (핵심!)
    private String callStoryServiceDirectly(String originalImageUrl) {
        try {
            System.out.println("🔄 [ColoringTemplateService] StoryService 직접 호출: " + originalImageUrl);

            // StoryService의 processImageToBlackWhite 메서드 직접 호출
            String blackWhiteUrl = storyService.processImageToBlackWhite(originalImageUrl);

            System.out.println("✅ [ColoringTemplateService] StoryService 직접 호출 성공: " + blackWhiteUrl);
            return blackWhiteUrl;

        } catch (Exception e) {
            System.err.println("❌ [ColoringTemplateService] StoryService 직접 호출 오류: " + e.getMessage());
            return originalImageUrl;
        }
    }

    // 🔍 기존 흑백 이미지 검색 (URL 패턴 단순화)
    private String findExistingBlackWhiteImageInS3(String originalS3Url) {
        try {
            // 원본: story-images/2025/06/13/image-xxxxx.png
            // 흑백: bw-images/2025/06/13/image-xxxxx.png (bw- 접두사 제거!)
            String predictedBwUrl = originalS3Url.replace("story-images/", "bw-images/");

            System.out.println("🔍 [ColoringTemplateService] 기존 흑백 이미지 확인: " + predictedBwUrl);

            // HEAD 요청으로 존재 여부 확인
            ResponseEntity<String> response = restTemplate.exchange(
                    predictedBwUrl, HttpMethod.HEAD, null, String.class);

            if (response.getStatusCode().is2xxSuccessful()) {
                System.out.println("✅ [ColoringTemplateService] 기존 흑백 이미지 발견: " + predictedBwUrl);
                return predictedBwUrl;
            }
        } catch (Exception e) {
            System.out.println("📝 [ColoringTemplateService] 기존 흑백 이미지 없음: " + e.getMessage());
        }
        return null;
    }

    // 🔍 파일 경로 해결
    private java.io.File resolveImageFile(String imagePath) {
        System.out.println("🔍 [ColoringTemplateService] 이미지 파일 경로 해결: " + imagePath);

        java.io.File file = new java.io.File(imagePath);
        if (file.isAbsolute() && file.exists()) {
            System.out.println("✅ [ColoringTemplateService] 절대경로로 파일 발견: " + file.getAbsolutePath());
            return file;
        }

        String[] searchPaths = {
                "./",
                "../python/",
                System.getProperty("user.dir"),
                "/tmp/",
        };

        for (String searchPath : searchPaths) {
            java.io.File searchFile = new java.io.File(searchPath, imagePath.startsWith("./") ? imagePath.substring(2) : imagePath);

            if (searchFile.exists()) {
                System.out.println("✅ [ColoringTemplateService] 파일 발견: " + searchFile.getAbsolutePath());
                return searchFile;
            }
        }

        String fileName = new java.io.File(imagePath).getName();
        for (String searchPath : searchPaths) {
            java.io.File searchFile = new java.io.File(searchPath, fileName);

            if (searchFile.exists()) {
                System.out.println("✅ [ColoringTemplateService] 파일명으로 파일 발견: " + searchFile.getAbsolutePath());
                return searchFile;
            }
        }

        System.out.println("❌ [ColoringTemplateService] 모든 경로에서 파일을 찾을 수 없음");
        return file;
    }

    // 🔍 로컬 파일 유효성 검사
    private boolean isValidLocalFile(String filePath) {
        try {
            File file = new File(filePath);

            // 파일 존재 여부 확인
            if (!file.exists()) {
                System.out.println("❌ [ColoringTemplateService] 파일이 존재하지 않음: " + filePath);
                return false;
            }

            // 파일인지 확인 (디렉토리가 아닌)
            if (!file.isFile()) {
                System.out.println("❌ [ColoringTemplateService] 디렉토리임, 파일이 아님: " + filePath);
                return false;
            }

            // 이미지 파일 확장자 확인
            String fileName = file.getName().toLowerCase();
            if (!fileName.endsWith(".png") && !fileName.endsWith(".jpg") &&
                    !fileName.endsWith(".jpeg") && !fileName.endsWith(".webp")) {
                System.out.println("❌ [ColoringTemplateService] 이미지 파일이 아님: " + filePath);
                return false;
            }

            // 파일 크기 확인 (0바이트가 아닌지)
            if (file.length() == 0) {
                System.out.println("❌ [ColoringTemplateService] 빈 파일: " + filePath);
                return false;
            }

            System.out.println("✅ [ColoringTemplateService] 유효한 로컬 파일: " + filePath);
            return true;

        } catch (Exception e) {
            System.err.println("❌ [ColoringTemplateService] 파일 검증 실패: " + e.getMessage());
            return false;
        }
    }

    // 🔍 URL에서 파일 확장자 추출
    private String getFileExtension(String url) {
        try {
            String fileName = url.substring(url.lastIndexOf('/') + 1);

            if (fileName.contains("?")) {
                fileName = fileName.substring(0, fileName.indexOf("?"));
            }

            if (fileName.contains(".")) {
                String extension = fileName.substring(fileName.lastIndexOf("."));
                System.out.println("🔍 [ColoringTemplateService] 추출된 확장자: " + extension);
                return extension;
            }

            System.out.println("⚠️ [ColoringTemplateService] 확장자를 찾을 수 없음, 기본값 사용: .jpg");
            return ".jpg";

        } catch (Exception e) {
            System.err.println("❌ [ColoringTemplateService] 확장자 추출 실패: " + e.getMessage());
            return ".jpg";
        }
    }

    // 🗑️ 파일 삭제 (정리용)
    private void deleteLocalFile(String filePath) {
        try {
            if (filePath != null && !filePath.isEmpty()) {
                Path path = Paths.get(filePath);
                if (Files.exists(path)) {
                    Files.delete(path);
                    System.out.println("🗑️ [ColoringTemplateService] 임시 파일 삭제: " + filePath);
                }
            }
        } catch (Exception e) {
            System.err.println("❌ [ColoringTemplateService] 파일 삭제 실패: " + e.getMessage());
        }
    }

    // ====== 조회 및 관리 메서드들 ======

    // 🎨 모든 색칠공부 템플릿 조회
    public Page<ColoringTemplate> getAllTemplates(Pageable pageable) {
        System.out.println("🔍 [ColoringTemplateService] 색칠공부 템플릿 목록 조회");
        return coloringTemplateRepository.findAllByOrderByCreatedAtDesc(pageable);
    }

    // 🎨 특정 템플릿 조회
    public ColoringTemplate getTemplateById(Long templateId) {
        System.out.println("🔍 [ColoringTemplateService] 색칠공부 템플릿 상세 조회 - ID: " + templateId);
        return coloringTemplateRepository.findById(templateId)
                .orElseThrow(() -> new RuntimeException("색칠공부 템플릿을 찾을 수 없습니다: " + templateId));
    }

    // 🎨 동화 ID로 색칠공부 템플릿 조회
    public Optional<ColoringTemplate> getTemplateByStoryId(String storyId, String username) {
        System.out.println("🔍 [ColoringTemplateService] 사용자별 동화 색칠공부 템플릿 조회 - StoryId: " + storyId + ", User: " + username);

        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + username));

        return coloringTemplateRepository.findByStoryIdAndUser(storyId, user);
    }

    // 🎯 명확한 네이밍의 별칭 메서드
    public Optional<ColoringTemplate> getTemplateByStoryIdAndUser(String storyId, String username) {
        return getTemplateByStoryId(storyId, username);
    }

    // 🎨 제목으로 검색
    public Page<ColoringTemplate> searchTemplatesByTitle(String keyword, Pageable pageable) {
        System.out.println("🔍 [ColoringTemplateService] 색칠공부 템플릿 검색 - 키워드: " + keyword);
        return coloringTemplateRepository.findByTitleContainingOrderByCreatedAtDesc(keyword, pageable);
    }

    // 🎨 템플릿 삭제
    public void deleteTemplate(Long templateId) {
        System.out.println("🗑️ [ColoringTemplateService] 색칠공부 템플릿 삭제 - ID: " + templateId);

        ColoringTemplate template = getTemplateById(templateId);
        coloringTemplateRepository.delete(template);

        System.out.println("✅ [ColoringTemplateService] 색칠공부 템플릿 삭제 완료");
    }
}