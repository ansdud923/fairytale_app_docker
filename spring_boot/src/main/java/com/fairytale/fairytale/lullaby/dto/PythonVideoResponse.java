package com.fairytale.fairytale.lullaby.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import java.util.List;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class PythonVideoResponse {
    @JsonProperty("video_results")
    private List<YouTubeVideo> videoResults;
}