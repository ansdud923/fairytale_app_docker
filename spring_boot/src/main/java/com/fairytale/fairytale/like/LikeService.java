package com.fairytale.fairytale.like;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class LikeService {
    private final LIkeRepository lIkeRepository;
}
