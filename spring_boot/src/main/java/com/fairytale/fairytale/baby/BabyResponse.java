package com.fairytale.fairytale.baby;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class BabyResponse {
    private Long id;
    private String name;
    private String gender;
    private String birthDate;
    private String createdAt;

    public BabyResponse(Baby baby) {
        this.id = baby.getId();
        this.name = baby.getBabyName();
        this.gender = baby.getBabyGender();
        this.birthDate = baby.getBabyBirthDate().toLocalDate().toString();
        this.createdAt = baby.getCreatedAt().toString();
    }
}