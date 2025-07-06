INSERT INTO role (role_name) VALUES ('ADMIN');

INSERT INTO users (
    username,
    nickname,
    email,
    hashed_password,
    role_id,
    google_id,
    kakao_id,
    created_at
) VALUES (
    'googleuser456',
    'GoogleUser',
    'googleuser@gmail.com',
    NULL, -- 소셜 로그인은 패스워드 불필요
    1,
    'google_123456789', -- Google ID
    NULL,
    NOW()
);