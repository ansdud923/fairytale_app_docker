// src/main/java/com/fairytale/fairytale/share/dto/ShareRequestDTO.java
package com.fairytale.fairytale.share.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ShareRequestDTO {
    private Long sourceId; // Story ID 또는 Gallery ID
    private String sourceType; // "STORY" 또는 "GALLERY"
}