package com.fairytale.fairytale.story.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)  // null 필드는 JSON에서 제외
public class FastApiStoryRequest {
    private String name;     // null일 때는 JSON에 포함되지 않음
    private String theme;
}
