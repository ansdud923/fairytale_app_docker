package com.fairytale.fairytale.role;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;

@Controller
@RequiredArgsConstructor
public class RoleController {
    private final RoleService roleService;
}
