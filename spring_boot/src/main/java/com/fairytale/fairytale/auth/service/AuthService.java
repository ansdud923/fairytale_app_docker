//package com.fairytale.fairytale.auth.service;
//
////import com.fairytale.fairytale.auth.strategy.SessionAuthStrategy;
//import com.fairytale.fairytale.users.Users;
//import com.fairytale.fairytale.users.UsersRepository;
//import lombok.RequiredArgsConstructor;
//import org.springframework.stereotype.Service;
//
//import java.time.LocalDateTime;
//
//@Service
//@RequiredArgsConstructor
//public class AuthService {
//    private final UsersRepository usersRepository;
////    private final SessionAuthStrategy sessionAuthStrategy;
//
//    public String login(String email, String password) {
//        LocalDateTime now = LocalDateTime.now();
//        // 1. 이메일로 유저 조회 (Users 객체 받아오기)
//        Users user = usersRepository.findByEmail(email)
//                .orElseThrow(() -> new RuntimeException("유효하지 않은 email입니다."));
//
//        // 2. 비밀번호 비교
//        if (!user.getHashedPassword().equals(password)) {
//            throw new RuntimeException("비밀번호가 틀렸습니다.");
//        }
//
//        // 3. 세션 생성 메서드 호출해서 세션ID 받기
////        String sessionId = sessionAuthStrategy.authenticate(user, Long.parseLong(String.valueOf(now)));
//
//        // 4. 세션ID 반환
//        return sessionId;
//    }
//
//    public boolean isSessionValid(String sessionId) {
//        // TODO 5. 세션 유효성 검사 (sessionManager.isValid 호출)
//        return sessionAuthStrategy.isValid(sessionId);
//    }
//
//    public String getUsernameFromSession(String sessionId) {
//        // TODO 6. 세션ID로 유저명 가져오기 (sessionManager.getUsername 호출)
//        return sessionAuthStrategy.getUsername(sessionId);
//    }
//}