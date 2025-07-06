package com.fairytale.fairytale.auth.strategy;

import com.fairytale.fairytale.users.Users;
import lombok.RequiredArgsConstructor;

@RequiredArgsConstructor
public class AuthContext {
    private final AuthStrategy strategy;

    public String authenticate(Users user, Long durationMs) {
        return strategy.authenticate(user, durationMs);
    }
}
