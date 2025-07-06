// src/main/java/com/fairytale/fairytale/service/S3Service.java
package com.fairytale.fairytale.service;

import com.amazonaws.HttpMethod;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.model.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class S3Service {

    private final AmazonS3 amazonS3;

    @Value("${AWS_S3_BUCKET_NAME}")
    private String bucketName;

    @Value("${AWS_REGION:ap-northeast-2}")
    private String region;


    /**
     * 프로필 이미지 업로드
     */
    public String uploadProfileImage(MultipartFile file, Long userId) {
        try {
            // 파일 확장자 검증
            String contentType = file.getContentType();
            if (!isImageFile(contentType)) {
                throw new IllegalArgumentException("이미지 파일만 업로드 가능합니다.");
            }

            // 파일 크기 검증 (5MB 제한)
            if (file.getSize() > 5 * 1024 * 1024) {
                throw new IllegalArgumentException("파일 크기는 5MB를 초과할 수 없습니다.");
            }

            // 파일명 생성
            String fileName = generateProfileImageFileName(userId, getFileExtension(file.getOriginalFilename()));

            // S3에 업로드
            ObjectMetadata metadata = new ObjectMetadata();
            metadata.setContentType(contentType);
            metadata.setContentLength(file.getSize());
            metadata.setCacheControl("max-age=31536000"); // 1년 캐시

            PutObjectRequest putObjectRequest = new PutObjectRequest(
                    bucketName,
                    fileName,
                    file.getInputStream(),
                    metadata
            ).withCannedAcl(CannedAccessControlList.PublicRead);

            amazonS3.putObject(putObjectRequest);

            // 업로드된 파일의 URL 반환
            String imageUrl = getPublicUrl(fileName);

            log.info("✅ 프로필 이미지 업로드 성공: userId={}, fileName={}, url={}", userId, fileName, imageUrl);
            return imageUrl;

        } catch (IOException e) {
            log.error("❌ 프로필 이미지 업로드 실패: userId={}, error={}", userId, e.getMessage());
            throw new RuntimeException("파일 업로드 중 오류가 발생했습니다.", e);
        }
    }

    /**
     * Presigned URL 생성 (클라이언트에서 직접 업로드용)
     */
    public Map<String, Object> generatePresignedUrl(Long userId, String contentType) {
        try {
            // 파일명 생성
            String fileName = generateProfileImageFileName(userId, getExtensionFromContentType(contentType));

            // Presigned URL 생성 (10분 유효)
            Date expiration = new Date();
            long expTimeMillis = expiration.getTime();
            expTimeMillis += 1000 * 60 * 10; // 10분
            expiration.setTime(expTimeMillis);

            GeneratePresignedUrlRequest generatePresignedUrlRequest = new GeneratePresignedUrlRequest(bucketName, fileName)
                    .withMethod(HttpMethod.PUT)
                    .withExpiration(expiration);

            generatePresignedUrlRequest.addRequestParameter("Content-Type", contentType);

            URL presignedUrl = amazonS3.generatePresignedUrl(generatePresignedUrlRequest);

            Map<String, Object> result = new HashMap<>();
            result.put("presignedUrl", presignedUrl.toString());
            result.put("fileName", fileName);
            result.put("publicUrl", getPublicUrl(fileName));
            result.put("expiresAt", expiration);

            log.info("✅ Presigned URL 생성 성공: userId={}, fileName={}", userId, fileName);
            return result;

        } catch (Exception e) {
            log.error("❌ Presigned URL 생성 실패: userId={}, error={}", userId, e.getMessage());
            throw new RuntimeException("Presigned URL 생성 중 오류가 발생했습니다.", e);
        }
    }

    /**
     * 파일 삭제
     */
    public void deleteFile(String fileName) {
        try {
            amazonS3.deleteObject(bucketName, fileName);
            log.info("✅ 파일 삭제 성공: fileName={}", fileName);
        } catch (Exception e) {
            log.error("❌ 파일 삭제 실패: fileName={}, error={}", fileName, e.getMessage());
            throw new RuntimeException("파일 삭제 중 오류가 발생했습니다.", e);
        }
    }

    /**
     * 파일 존재 여부 확인
     */
    public boolean doesFileExist(String fileName) {
        try {
            amazonS3.getObjectMetadata(bucketName, fileName);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    // === Private Methods ===

    private String generateProfileImageFileName(Long userId, String extension) {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss"));
        String uuid = UUID.randomUUID().toString().substring(0, 8);
        return String.format("profile-images/user-%d-%s-%s%s", userId, timestamp, uuid, extension);
    }

    private String getPublicUrl(String fileName) {
        return String.format("https://%s.s3.%s.amazonaws.com/%s", bucketName, region, fileName);
    }

    private boolean isImageFile(String contentType) {
        return contentType != null && (
                contentType.equals("image/jpeg") ||
                        contentType.equals("image/jpg") ||
                        contentType.equals("image/png") ||
                        contentType.equals("image/gif")
        );
    }

    private String getFileExtension(String fileName) {
        if (fileName != null && fileName.contains(".")) {
            return fileName.substring(fileName.lastIndexOf("."));
        }
        return ".jpg"; // 기본값
    }

    private String getExtensionFromContentType(String contentType) {
        switch (contentType) {
            case "image/jpeg":
            case "image/jpg":
                return ".jpg";
            case "image/png":
                return ".png";
            case "image/gif":
                return ".gif";
            default:
                return ".jpg";
        }

    }

    /**
     * 🖼️ 외부 URL 이미지를 다운로드해서 S3에 업로드 (흑백변환용)
     */
    public String uploadImageFromUrl(String imageUrl, Long storyId) {
        try {
            log.info("🖼️ 외부 이미지 S3 업로드 시작: {}", imageUrl);

            // 1. 외부 URL에서 이미지 다운로드
            byte[] imageData = downloadImageFromUrl(imageUrl);
            log.info("📥 이미지 다운로드 완료: {} bytes", imageData.length);

            // 2. S3 키 생성
            String s3Key = generateImageFileName(storyId, getImageExtensionFromUrl(imageUrl));
            log.info("🔑 생성된 S3 키: {}", s3Key);

            // 3. 메타데이터 설정
            ObjectMetadata metadata = new ObjectMetadata();
            metadata.setContentLength(imageData.length);
            metadata.setContentType(getImageContentTypeFromUrl(imageUrl));
            metadata.setCacheControl("max-age=31536000"); // 1년 캐시

            // 4. S3에 업로드 (ACL 없이)
            try (java.io.ByteArrayInputStream inputStream = new java.io.ByteArrayInputStream(imageData)) {
                PutObjectRequest putRequest = new PutObjectRequest(
                        bucketName,
                        s3Key,
                        inputStream,
                        metadata
                );

                // 🚫 ACL 설정 제거 (버킷 정책으로 공개 접근 제어)
                // putRequest.setCannedAcl(CannedAccessControlList.PublicRead);

                PutObjectResult result = amazonS3.putObject(putRequest);
                log.info("✅ S3 이미지 업로드 완료. ETag: {}", result.getETag());
            }

            // 5. 공개 URL 반환
            String publicUrl = getPublicUrl(s3Key);
            log.info("✅ 생성된 이미지 공개 URL: {}", publicUrl);

            return publicUrl;

        } catch (Exception e) {
            log.error("❌ S3 이미지 업로드 실패: {}", e.getMessage());
            throw new RuntimeException("S3 이미지 업로드 실패: " + e.getMessage(), e);
        }
    }

    /**
     * 📥 외부 URL에서 이미지 다운로드
     */
    private byte[] downloadImageFromUrl(String imageUrl) {
        try {
            log.info("📥 이미지 다운로드 시작: {}", imageUrl);

            java.net.URL url = new java.net.URL(imageUrl);
            java.net.HttpURLConnection connection = (java.net.HttpURLConnection) url.openConnection();
            connection.setRequestMethod("GET");
            connection.setConnectTimeout(10000); // 10초 타임아웃
            connection.setReadTimeout(30000);    // 30초 읽기 타임아웃

            // User-Agent 설정 (일부 서버에서 요구)
            connection.setRequestProperty("User-Agent",
                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36");

            // 응답 코드 확인
            int responseCode = connection.getResponseCode();
            if (responseCode != 200) {
                throw new RuntimeException("이미지 다운로드 실패. HTTP 응답 코드: " + responseCode);
            }

            try (java.io.InputStream inputStream = connection.getInputStream();
                 java.io.ByteArrayOutputStream outputStream = new java.io.ByteArrayOutputStream()) {

                byte[] buffer = new byte[8192];
                int bytesRead;
                while ((bytesRead = inputStream.read(buffer)) != -1) {
                    outputStream.write(buffer, 0, bytesRead);
                }

                byte[] imageData = outputStream.toByteArray();
                log.info("✅ 이미지 다운로드 완료: {} bytes", imageData.length);
                return imageData;
            }

        } catch (Exception e) {
            log.error("❌ 이미지 다운로드 실패: {}", e.getMessage());
            throw new RuntimeException("이미지 다운로드 실패: " + e.getMessage(), e);
        }
    }

    /**
     * 🔑 이미지 파일명 생성 (충돌 방지)
     */
    private String generateImageFileName(Long storyId, String extension) {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy/MM/dd"));
        String uuid = UUID.randomUUID().toString().substring(0, 8);

        return String.format("images/%s/story-%d-%s%s", timestamp, storyId, uuid, extension);
    }

    /**
     * 🎨 URL에서 이미지 확장자 추출
     */
    private String getImageExtensionFromUrl(String imageUrl) {
        try {
            String lowerUrl = imageUrl.toLowerCase();
            if (lowerUrl.contains(".png")) return ".png";
            if (lowerUrl.contains(".jpg") || lowerUrl.contains(".jpeg")) return ".jpg";
            if (lowerUrl.contains(".gif")) return ".gif";
            if (lowerUrl.contains(".webp")) return ".webp";
            return ".jpg"; // 기본값
        } catch (Exception e) {
            return ".jpg"; // 오류 시 기본값
        }
    }

    /**
     * 🎨 URL에서 이미지 Content-Type 추출
     */
    private String getImageContentTypeFromUrl(String imageUrl) {
        try {
            String lowerUrl = imageUrl.toLowerCase();
            if (lowerUrl.contains(".png")) return "image/png";
            if (lowerUrl.contains(".jpg") || lowerUrl.contains(".jpeg")) return "image/jpeg";
            if (lowerUrl.contains(".gif")) return "image/gif";
            if (lowerUrl.contains(".webp")) return "image/webp";
            return "image/jpeg"; // 기본값
        } catch (Exception e) {
            return "image/jpeg"; // 오류 시 기본값
        }
    }

    // 🖼️ 로컬 이미지 파일을 S3에 업로드 (흑백 변환 이미지용)
    public String uploadImageFromLocalFile(String localFilePath, String folder) {
        try {
            log.info("🖼️ 로컬 이미지 파일 S3 업로드 시작: {}", localFilePath);

            // 1. 로컬 파일 존재 여부 확인
            java.io.File localFile = new java.io.File(localFilePath);
            if (!localFile.exists()) {
                throw new java.io.FileNotFoundException("로컬 파일이 존재하지 않습니다: " + localFilePath);
            }

            log.info("🔍 파일 크기: {} bytes", localFile.length());

            // 2. S3 키 생성 (폴더 지정 가능)
            String s3Key = generateImageFileNameWithFolder(folder, getFileExtension(localFile.getName()));
            log.info("🔑 생성된 S3 키: {}", s3Key);

            // 3. 메타데이터 설정
            ObjectMetadata metadata = new ObjectMetadata();
            metadata.setContentLength(localFile.length());
            metadata.setContentType(getImageContentTypeFromFile(localFile.getName()));
            metadata.setCacheControl("max-age=31536000"); // 1년 캐시

            // 4. S3에 업로드 (ACL 없이)
            try (java.io.FileInputStream fileInputStream = new java.io.FileInputStream(localFile)) {
                PutObjectRequest putRequest = new PutObjectRequest(
                        bucketName,
                        s3Key,
                        fileInputStream,
                        metadata
                );

                // ACL 설정 제거 (버킷 정책으로 공개 접근 제어)
                PutObjectResult result = amazonS3.putObject(putRequest);
                log.info("✅ S3 이미지 업로드 완료. ETag: {}", result.getETag());
            }

            // 5. 공개 URL 반환
            String publicUrl = getPublicUrl(s3Key);
            log.info("✅ 생성된 이미지 공개 URL: {}", publicUrl);

            return publicUrl;

        } catch (Exception e) {
            log.error("❌ S3 로컬 이미지 업로드 실패: {}", e.getMessage());
            throw new RuntimeException("S3 로컬 이미지 업로드 실패: " + e.getMessage(), e);
        }
    }

    /**
     * 🔑 폴더 지정 가능한 이미지 파일명 생성
     */
    private String generateImageFileNameWithFolder(String folder, String extension) {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy/MM/dd"));
        String uuid = UUID.randomUUID().toString().substring(0, 8);

        // 폴더가 지정되면 해당 폴더 사용, 없으면 기본 images 폴더
        String baseFolder = folder != null && !folder.isEmpty() ? folder : "images";

        return String.format("%s/%s/image-%s%s", baseFolder, timestamp, uuid, extension);
    }

    /**
     * 🎨 파일명에서 이미지 Content-Type 추출
     */
    private String getImageContentTypeFromFile(String fileName) {
        try {
            String lowerName = fileName.toLowerCase();
            if (lowerName.endsWith(".png")) return "image/png";
            if (lowerName.endsWith(".jpg") || lowerName.endsWith(".jpeg")) return "image/jpeg";
            if (lowerName.endsWith(".gif")) return "image/gif";
            if (lowerName.endsWith(".webp")) return "image/webp";
            return "image/png"; // 기본값 (흑백 이미지는 보통 PNG)
        } catch (Exception e) {
            return "image/png"; // 오류 시 기본값
        }
    }

    // s3업로드
    public boolean isS3Available() {
        try {
            return amazonS3.doesBucketExistV2(bucketName);
        } catch (Exception e) {
            return false;
        }
    }

    // S3Service.java에 추가할 메서드 (기존 uploadImageWithCustomKey 수정)

    public String uploadImageWithCustomKey(String localFilePath, String customKey) {
        try {
            File file = new File(localFilePath);
            if (!file.exists()) {
                log.error("❌ 파일이 존재하지 않음: {}", localFilePath);
                return null;
            }

            log.info("🖼️ 커스텀 키로 S3 업로드 시작: {} → {}", localFilePath, customKey);
            log.info("🔍 파일 크기: {} bytes", file.length());

            // 메타데이터 설정
            ObjectMetadata metadata = new ObjectMetadata();
            metadata.setContentLength(file.length());
            metadata.setContentType(getImageContentTypeFromFile(file.getName()));
            metadata.setCacheControl("max-age=31536000"); // 1년 캐시

            // 커스텀 키로 업로드 (UUID 생성하지 않음)
            try (java.io.FileInputStream fileInputStream = new java.io.FileInputStream(file)) {
                PutObjectRequest putRequest = new PutObjectRequest(
                        bucketName,
                        customKey,  // 🔥 전달받은 키 그대로 사용!
                        fileInputStream,
                        metadata
                );

                // ACL 설정 (기존 패턴과 동일)
                // putRequest.setCannedAcl(CannedAccessControlList.PublicRead); // 필요시 주석 해제

                PutObjectResult result = amazonS3.putObject(putRequest);
                log.info("✅ S3 커스텀 키 업로드 완료. ETag: {}", result.getETag());
            }

            // 공개 URL 반환
            String s3Url = getPublicUrl(customKey);
            log.info("✅ 커스텀 키로 S3 업로드 완료: {}", s3Url);
            return s3Url;

        } catch (Exception e) {
            log.error("❌ 커스텀 키 S3 업로드 실패: {}", e.getMessage());
            return null;
        }
    }

    // 오디오 파일 업로드
    public String uploadAudioFileWithPresignedUrl(String localFilePath) {
        try {
            log.info("📤 S3 오디오 파일 업로드 시작 (Presigned URL): {}", localFilePath);

            // 파일 업로드 (ACL 없이)
            java.io.File localFile = new java.io.File(localFilePath);
            if (!localFile.exists()) {
                throw new java.io.FileNotFoundException("로컬 파일이 존재하지 않습니다: " + localFilePath);
            }

            String s3Key = generateAudioFileName(localFile.getName());
            log.info("🔑 생성된 S3 키: {}", s3Key);

            ObjectMetadata metadata = new ObjectMetadata();
            metadata.setContentLength(localFile.length());
            metadata.setContentType(getAudioContentType(localFilePath));
            metadata.setCacheControl("max-age=31536000");

            try (java.io.FileInputStream fileInputStream = new java.io.FileInputStream(localFile)) {
                PutObjectRequest putRequest = new PutObjectRequest(
                        bucketName,
                        s3Key,
                        fileInputStream,
                        metadata
                );
                // ACL 설정 없음 - 비공개 파일

                amazonS3.putObject(putRequest);
                log.info("✅ S3 업로드 완료 (비공개): {}", s3Key);
            }

            // Presigned URL 생성 (24시간 유효)
            String presignedUrl = generateAudioPresignedUrl(s3Key, 24 * 60); // 24시간
            log.info("✅ Presigned URL 생성: {}", presignedUrl);

            return presignedUrl;

        } catch (Exception e) {
            log.error("❌ S3 오디오 업로드 실패: {}", e.getMessage());
            throw new RuntimeException("S3 파일 업로드 실패: " + e.getMessage(), e);
        }
    }

    /**
     * 📥 S3에서 오디오 파일을 바이트 배열로 다운로드
     */
    public byte[] downloadAudioFile(String s3Key) {
        try {
            log.info("📥 S3 파일 다운로드 시작: {}", s3Key);

            // 🔍 파일 존재 여부 확인
            if (!amazonS3.doesObjectExist(bucketName, s3Key)) {
                throw new java.io.FileNotFoundException("S3에 파일이 존재하지 않습니다: " + s3Key);
            }

            // 📥 S3에서 객체 가져오기
            S3Object s3Object = amazonS3.getObject(bucketName, s3Key);

            // 📖 스트림을 바이트 배열로 변환
            try (java.io.InputStream inputStream = s3Object.getObjectContent();
                 java.io.ByteArrayOutputStream outputStream = new java.io.ByteArrayOutputStream()) {

                byte[] buffer = new byte[8192]; // 8KB 버퍼
                int bytesRead;
                while ((bytesRead = inputStream.read(buffer)) != -1) {
                    outputStream.write(buffer, 0, bytesRead);
                }

                byte[] fileData = outputStream.toByteArray();
                log.info("✅ S3 다운로드 완료. 파일 크기: {} bytes", fileData.length);

                return fileData;
            }

        } catch (Exception e) {
            log.error("❌ S3 다운로드 실패: {}", e.getMessage());
            throw new RuntimeException("S3 파일 다운로드 실패: " + e.getMessage(), e);
        }
    }

    /**
     * 🔗 오디오 파일 Presigned URL 생성 (임시 접근용)
     */
    public String generateAudioPresignedUrl(String s3Key, int expirationMinutes) {
        try {
            log.info("🔗 오디오 Presigned URL 생성: {}, 만료시간: {}분", s3Key, expirationMinutes);

            Date expiration = new Date();
            long expTimeMillis = expiration.getTime();
            expTimeMillis += 1000L * 60 * expirationMinutes;
            expiration.setTime(expTimeMillis);

            GeneratePresignedUrlRequest generatePresignedUrlRequest = new GeneratePresignedUrlRequest(
                    bucketName, s3Key)
                    .withMethod(HttpMethod.GET)
                    .withExpiration(expiration);

            URL url = amazonS3.generatePresignedUrl(generatePresignedUrlRequest);
            String presignedUrl = url.toString();

            log.info("✅ 오디오 Presigned URL 생성 완료: {}", presignedUrl);
            return presignedUrl;

        } catch (Exception e) {
            log.error("❌ 오디오 Presigned URL 생성 실패: {}", e.getMessage());
            throw new RuntimeException("Presigned URL 생성 실패: " + e.getMessage(), e);
        }
    }

    /**
     * 🔍 S3 키를 URL에서 추출하는 유틸리티 메서드
     */
    public String extractS3KeyFromUrl(String url) {
        try {
            if (url.contains("amazonaws.com")) {
                // S3 직접 URL에서 키 추출
                String[] parts = url.split("/");
                StringBuilder s3Key = new StringBuilder();
                for (int i = 3; i < parts.length; i++) {
                    if (s3Key.length() > 0) s3Key.append("/");
                    s3Key.append(parts[i]);
                }
                return s3Key.toString();
            }
            return null;
        } catch (Exception e) {
            log.error("❌ S3 키 추출 실패: {}", e.getMessage());
            return null;
        }
    }

    /**
     * 📊 S3 연결 상태 확인 (헬스체크용)
     */
    public boolean isS3Connected() {
        try {
            return amazonS3.doesBucketExistV2(bucketName);
        } catch (Exception e) {
            log.error("❌ S3 연결 확인 실패: {}", e.getMessage());
            return false;
        }
    }

// === Private Methods for Audio Files ===

    /**
     * 🔑 오디오 파일명 생성 (중복 방지)
     */
    private String generateAudioFileName(String originalFileName) {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy/MM/dd"));
        String uuid = UUID.randomUUID().toString().substring(0, 8);
        String cleanFileName = originalFileName.replaceAll("[^a-zA-Z0-9._-]", "_"); // 안전한 파일명 처리

        return String.format("audio/%s/%s_%s", timestamp, uuid, cleanFileName);
    }

    /**
     * 🎵 오디오 파일 Content-Type 결정
     */
    private String getAudioContentType(String filePath) {
        String lowerPath = filePath.toLowerCase();

        if (lowerPath.endsWith(".mp3")) {
            return "audio/mpeg";
        } else if (lowerPath.endsWith(".wav")) {
            return "audio/wav";
        } else if (lowerPath.endsWith(".m4a")) {
            return "audio/mp4";
        } else if (lowerPath.endsWith(".ogg")) {
            return "audio/ogg";
        } else {
            return "application/octet-stream";
        }
    }
// src/main/java/com/fairytale/fairytale/service/S3Service.java (비디오 업로드 메서드 추가)
// 기존 S3Service.java에 다음 메서드들을 추가해주세요:

    /**
     * 🎬 로컬 비디오 파일을 S3에 업로드
     */
    public String uploadVideoFromLocalFile(String localFilePath, String folder) {
        try {
            log.info("🎬 로컬 비디오 파일 S3 업로드 시작: {}", localFilePath);

            // 1. 로컬 파일 존재 여부 확인
            java.io.File localFile = new java.io.File(localFilePath);
            if (!localFile.exists()) {
                throw new java.io.FileNotFoundException("로컬 파일이 존재하지 않습니다: " + localFilePath);
            }

            log.info("🔍 파일 크기: {} bytes", localFile.length());

            // 2. S3 키 생성 (폴더 지정 가능)
            String s3Key = generateVideoFileName(folder, getFileExtension(localFile.getName()));
            log.info("🔑 생성된 S3 키: {}", s3Key);

            // 3. 메타데이터 설정
            ObjectMetadata metadata = new ObjectMetadata();
            metadata.setContentLength(localFile.length());
            metadata.setContentType(getVideoContentTypeFromFile(localFile.getName()));
            metadata.setCacheControl("max-age=31536000"); // 1년 캐시

            // 4. S3에 업로드
            try (java.io.FileInputStream fileInputStream = new java.io.FileInputStream(localFile)) {
                PutObjectRequest putRequest = new PutObjectRequest(
                        bucketName,
                        s3Key,
                        fileInputStream,
                        metadata
                );

                PutObjectResult result = amazonS3.putObject(putRequest);
                log.info("✅ S3 비디오 업로드 완료. ETag: {}", result.getETag());
            }

            // 5. 공개 URL 반환
            String publicUrl = getPublicUrl(s3Key);
            log.info("✅ 생성된 비디오 공개 URL: {}", publicUrl);

            // 6. 업로드 후 로컬 파일 삭제 (옵션)
            try {
                localFile.delete();
                log.info("🗑️ 임시 로컬 파일 삭제 완료: {}", localFilePath);
            } catch (Exception e) {
                log.warn("⚠️ 임시 파일 삭제 실패: {}", e.getMessage());
            }

            return publicUrl;

        } catch (Exception e) {
            log.error("❌ S3 비디오 업로드 실패: {}", e.getMessage());
            throw new RuntimeException("S3 비디오 업로드 실패: " + e.getMessage(), e);
        }
    }

    /**
     * 🔑 비디오 파일명 생성 (중복 방지)
     */
    private String generateVideoFileName(String folder, String extension) {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy/MM/dd"));
        String uuid = UUID.randomUUID().toString().substring(0, 8);

        // 폴더가 지정되면 해당 폴더 사용, 없으면 기본 videos 폴더
        String baseFolder = folder != null && !folder.isEmpty() ? folder : "videos";

        return String.format("%s/%s/video-%s%s", baseFolder, timestamp, uuid, extension);
    }

    /**
     * 🎬 파일명에서 비디오 Content-Type 추출
     */
    private String getVideoContentTypeFromFile(String fileName) {
        try {
            String lowerName = fileName.toLowerCase();
            if (lowerName.endsWith(".mp4")) return "video/mp4";
            if (lowerName.endsWith(".avi")) return "video/x-msvideo";
            if (lowerName.endsWith(".mov")) return "video/quicktime";
            if (lowerName.endsWith(".wmv")) return "video/x-ms-wmv";
            if (lowerName.endsWith(".flv")) return "video/x-flv";
            if (lowerName.endsWith(".webm")) return "video/webm";
            return "video/mp4"; // 기본값
        } catch (Exception e) {
            return "video/mp4"; // 오류 시 기본값
        }
    }

    /**
     * 🎬 비디오 파일 존재 여부 확인
     */
    public boolean doesVideoExist(String videoKey) {
        try {
            amazonS3.getObjectMetadata(bucketName, videoKey);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * 🗑️ 비디오 파일 삭제
     */
    public void deleteVideo(String videoUrl) {
        try {
            // URL에서 S3 키 추출
            String s3Key = extractS3KeyFromUrl(videoUrl);
            if (s3Key != null) {
                amazonS3.deleteObject(bucketName, s3Key);
                log.info("✅ 비디오 파일 삭제 성공: {}", s3Key);
            }
        } catch (Exception e) {
            log.error("❌ 비디오 파일 삭제 실패: {}", e.getMessage());
        }
    }

    /**
     * 🎨 색칠 완성작 업로드 (MultipartFile → S3)
     */
    public String uploadColoringWork(MultipartFile file, String username, String storyId) {
        try {
            log.info("🎨 색칠 완성작 S3 업로드 시작 - User: {}, StoryId: {}", username, storyId);
            log.info("🔍 파일 정보 - Name: {}, ContentType: {}, Size: {}",
                    file.getOriginalFilename(), file.getContentType(), file.getSize());

            // 파일 검증 (더 관대하게)
            String contentType = file.getContentType();
            if (contentType == null) {
                // Content-Type이 없으면 파일명 확장자로 판단
                String fileName = file.getOriginalFilename();
                if (fileName != null && (fileName.endsWith(".png") || fileName.endsWith(".jpg") || fileName.endsWith(".jpeg"))) {
                    contentType = fileName.endsWith(".png") ? "image/png" : "image/jpeg";
                    log.info("📝 Content-Type을 파일명에서 추정: {}", contentType);
                } else {
                    contentType = "image/png"; // 기본값
                    log.info("📝 기본 Content-Type 사용: {}", contentType);
                }
            }

            if (!isImageFile(contentType) && !file.getOriginalFilename().matches(".*\\.(png|jpg|jpeg|gif|webp)$")) {
                log.warn("⚠️ 이미지 파일 검증 실패 - ContentType: {}, FileName: {}", contentType, file.getOriginalFilename());
                throw new IllegalArgumentException("이미지 파일만 업로드 가능합니다.");
            }

            // 파일 크기 검증 (10MB 제한)
            if (file.getSize() > 10 * 1024 * 1024) {
                throw new IllegalArgumentException("파일 크기는 10MB를 초과할 수 없습니다.");
            }

            // 색칠 완성작 전용 파일명 생성
            String fileName = generateColoringWorkFileName(username, storyId, getFileExtension(file.getOriginalFilename()));
            log.info("🔑 생성된 S3 키: {}", fileName);

            // 메타데이터 설정
            ObjectMetadata metadata = new ObjectMetadata();
            metadata.setContentType(contentType); // 추정된 Content-Type 사용
            metadata.setContentLength(file.getSize());
            metadata.setCacheControl("max-age=31536000");

            // S3 업로드
            PutObjectRequest putRequest = new PutObjectRequest(
                    bucketName,
                    fileName,
                    file.getInputStream(),
                    metadata
            );

            amazonS3.putObject(putRequest);

            String publicUrl = getPublicUrl(fileName);
            log.info("✅ 색칠 완성작 S3 업로드 완료: {}", publicUrl);

            return publicUrl;

        } catch (IOException e) {
            log.error("❌ 색칠 완성작 업로드 실패: {}", e.getMessage());
            throw new RuntimeException("색칠 완성작 업로드 실패", e);
        }
    }

    /**
     * 🔑 색칠 완성작 파일명 생성 (기존 generateProfileImageFileName 패턴 활용)
     */
    private String generateColoringWorkFileName(String username, String storyId, String extension) {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy/MM/dd"));
        String uuid = UUID.randomUUID().toString().substring(0, 8);

        // coloring-works/날짜/사용자명/스토리ID-UUID.확장자
        return String.format("coloring-works/%s/%s/story-%s-%s%s",
                timestamp, username, storyId, uuid, extension);
    }
}
