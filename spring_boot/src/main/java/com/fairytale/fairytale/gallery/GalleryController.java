package com.fairytale.fairytale.gallery;

import com.fairytale.fairytale.gallery.dto.ColoringImageRequest;
import com.fairytale.fairytale.gallery.dto.GalleryImageDTO;
import com.fairytale.fairytale.gallery.dto.GalleryStatsDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/gallery")
@RequiredArgsConstructor
public class GalleryController {

    private final GalleryService galleryService;

    /**
     * 사용자의 갤러리 이미지 목록 조회
     */
    @GetMapping("/images")
    public ResponseEntity<List<GalleryImageDTO>> getUserGalleryImages(Authentication auth) {
        try {
            String username = auth.getName();
            log.info("🔍 갤러리 이미지 조회 요청 - 사용자: {}", username);

            List<GalleryImageDTO> galleryImages = galleryService.getUserGalleryImages(username);

            log.info("✅ 갤러리 이미지 조회 완료 - 개수: {}", galleryImages.size());
            return ResponseEntity.ok(galleryImages);

        } catch (Exception e) {
            log.error("❌ 갤러리 이미지 조회 실패: {}", e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }

    /**
     * 특정 스토리의 갤러리 이미지 조회
     */
    @GetMapping("/images/{storyId}")
    public ResponseEntity<GalleryImageDTO> getStoryGalleryImage(
            @PathVariable Long storyId,
            Authentication auth) {
        try {
            String username = auth.getName();
            log.info("🔍 특정 스토리 갤러리 조회 - StoryId: {}, 사용자: {}", storyId, username);

            GalleryImageDTO galleryImage = galleryService.getStoryGalleryImage(storyId, username);

            if (galleryImage != null) {
                log.info("✅ 스토리 갤러리 이미지 조회 완료");
                return ResponseEntity.ok(galleryImage);
            } else {
                log.info("⚠️ 해당 스토리의 갤러리 이미지 없음");
                return ResponseEntity.notFound().build();
            }

        } catch (Exception e) {
            log.error("❌ 스토리 갤러리 이미지 조회 실패: {}", e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }

    /**
     * 색칠한 이미지 업로드/업데이트
     */
    @PostMapping("/coloring/{storyId}")
    public ResponseEntity<GalleryImageDTO> updateColoringImage(
            @PathVariable Long storyId,
            @RequestBody ColoringImageRequest request,
            Authentication auth) {
        try {
            String username = auth.getName();
            log.info("🔍 색칠한 이미지 업데이트 - StoryId: {}, 사용자: {}", storyId, username);

            GalleryImageDTO updatedImage = galleryService.updateColoringImage(storyId, request.getColoringImageUrl(), username);

            log.info("✅ 색칠한 이미지 업데이트 완료");
            return ResponseEntity.ok(updatedImage);

        } catch (Exception e) {
            log.error("❌ 색칠한 이미지 업데이트 실패: {}", e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }

    /**
     * 🎯 갤러리 아이템 삭제 (개선됨) - Story 또는 ColoringWork 모두 처리
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, Object>> deleteGalleryItem(
            @PathVariable Long id,
            @RequestParam(defaultValue = "story") String type, // "story" 또는 "coloring"
            Authentication auth) {
        try {
            String username = auth.getName();
            log.info("🔍 갤러리 아이템 삭제 - ID: {}, Type: {}, User: {}", id, type, username);

            boolean deleted = false;
            Map<String, Object> response = new HashMap<>();

            if ("coloring".equals(type)) {
                // 색칠 완성작 삭제
                deleted = galleryService.deleteColoringWork(id, username);
                response.put("deletedType", "coloring");
                log.info("🎨 색칠 완성작 삭제 시도 - ColoringWorkId: {}", id);
            } else {
                // 기존 갤러리 삭제 (storyId 기준으로 Story 삭제)
                deleted = galleryService.deleteGalleryImage(id, username);
                response.put("deletedType", "story");
                log.info("📖 스토리 삭제 시도 - StoryId: {}", id);
            }

            if (deleted) {
                response.put("success", true);
                response.put("message", "삭제되었습니다.");
                log.info("✅ 갤러리 아이템 삭제 완료 - Type: {}, ID: {}", type, id);
                return ResponseEntity.ok(response);
            } else {
                response.put("success", false);
                response.put("error", "삭제할 항목을 찾을 수 없습니다.");
                log.warn("⚠️ 삭제할 갤러리 아이템 없음 - ID: {}, Type: {}", id, type);
                return ResponseEntity.status(404).body(response);
            }

        } catch (Exception e) {
            log.error("❌ 갤러리 아이템 삭제 실패: {}", e.getMessage());
            return ResponseEntity.status(500).body(Map.of(
                    "success", false,
                    "error", "삭제 실패: " + e.getMessage()
            ));
        }
    }

    /**
     * 갤러리 통계 조회
     */
    @GetMapping("/stats")
    public ResponseEntity<GalleryStatsDTO> getGalleryStats(Authentication auth) {
        try {
            String username = auth.getName();
            log.info("🔍 갤러리 통계 조회 - 사용자: {}", username);

            GalleryStatsDTO stats = galleryService.getGalleryStats(username);

            log.info("✅ 갤러리 통계 조회 완료");
            return ResponseEntity.ok(stats);

        } catch (Exception e) {
            log.error("❌ 갤러리 통계 조회 실패: {}", e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }

    /**
     * 🎯 개선된 갤러리 조회 (타입별 필터링)
     */
    @GetMapping("/gallery")
    public ResponseEntity<?> getGallery(
            @RequestParam(defaultValue = "all") String type,
            Authentication authentication) {

        String username = authentication.getName();

        try {
            List<GalleryImageDTO> galleryImages;

            switch (type) {
                case "story":
                    galleryImages = galleryService.getUserStoryImages(username);
                    break;
                case "coloring":
                    galleryImages = galleryService.getUserColoringWorks(username);
                    break;
                case "all":
                default:
                    galleryImages = galleryService.getUserGalleryImages(username);
                    break;
            }

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("images", galleryImages);
            response.put("count", galleryImages.size());
            response.put("type", type);

            log.info("✅ 갤러리 조회 완료 - Type: {}, Count: {}", type, galleryImages.size());
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 갤러리 조회 오류: {}", e.getMessage());
            return ResponseEntity.status(500).body(Map.of(
                    "success", false,
                    "error", "갤러리 조회 실패: " + e.getMessage()
            ));
        }
    }
}