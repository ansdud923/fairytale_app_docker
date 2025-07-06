package com.fairytale.fairytale.lullaby.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class LullabyTheme {
    private String title;
    private String duration;
    private String audioUrl;
    private String description;
    private String artist;
    private String imageUrl;
}