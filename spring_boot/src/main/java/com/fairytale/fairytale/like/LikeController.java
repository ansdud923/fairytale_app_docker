package com.fairytale.fairytale.like;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;

@Controller
@RequiredArgsConstructor
public class LikeController {
    private final LikeService likeService;
}
