package com.fairytale.fairytale.baby;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class BabyUpdateRequest {
    private String name;
    private String gender;
    private String birthDate; // YYYY-MM-DD 형식
}