//package com.fairytale.fairytale.auth.strategy;
//
//import com.fairytale.fairytale.users.Users;
//import com.fairytale.fairytale.users.UsersRepository;
//import jakarta.servlet.http.HttpServletRequest;
//import lombok.RequiredArgsConstructor;
//import org.springframework.stereotype.Component;
//
//import java.util.Map;
//import java.util.Optional;
//import java.util.UUID;
//import java.util.concurrent.ConcurrentHashMap;
//
//@Component("sessionAuthStrategy") // 스프링 빈으로 등록
//@RequiredArgsConstructor
//public abstract class SessionAuthStrategy implements AuthStrategy {
//    private final UsersRepository usersRepository;
//
//    // TODO: 사용자 세션 정보를 저장할 Map 정의 (스레드 세이프한 자료구조로)
//    // 세션ID와 유저ID를 넣어야 함. 매칭시키기 위해서
//    // 사용자가 이후에 게시글 보기같은 요청을 보낼 때 유저정보를 찾아오기 위해 담아둠.
//    Map<String, String> sessionInfo = new ConcurrentHashMap<>();
//
//    public String authenticate(Users user, Long durationMs) {
//        if (user == null) {
//            throw new RuntimeException("유저 정보 없음!");
//        }
//        String sessionId = UUID.randomUUID().toString();
//        sessionInfo.put(sessionId, String.valueOf(user.getId())); // 유저 ID 저장
//        return sessionId;
//    }
//
//    // TODO: isValid(String sessionId) 구현
//    public boolean isValid(String sessionId) {
//        return sessionInfo.containsKey(sessionId);
//    }
//
//    // TODO: extractUsername(String sessionId) 구현
//    public String getUsername(String sessionId) {
//        // 1. sessionId으로 Map에서 Users 객체 조회
//        String userId = sessionInfo.get(sessionId);
//        // 2. Users 객체가 존재하면 사용자 email 또는 username 리턴
//        if (userId != null) {
//            Optional<Users> userOpt = usersRepository.findById(Long.parseLong(userId));
//            return userOpt.map(Users::getUsername).orElse(null);
//        }
//        // 3. 없으면 null 리턴
//        return null;
//    }
//}