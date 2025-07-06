package com.fairytale.fairytale.lullaby.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class JamendoTrack {
    private String id;
    private String name;
    private Integer duration;  // int → Integer (null 허용)
    private String artist_name;
    private String audio;
    private String image;
    private String audiodownload;

    @Override
    public String toString() {
        return "JamendoTrack{" +
                "id='" + id + '\'' +
                ", name='" + name + '\'' +
                ", duration=" + duration +
                ", artist_name='" + artist_name + '\'' +
                ", audio='" + audio + '\'' +
                ", image='" + image + '\'' +
                ", audiodownload='" + audiodownload + '\'' +
                '}';
    }
}