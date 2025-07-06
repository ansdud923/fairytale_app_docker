module.exports = {
  apps: [{
    name: 'fairytale-backend',
    script: '/opt/fairytale/start.sh',
    cwd: '/opt/fairytale',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '2G',
    restart_delay: 4000,
    min_uptime: '10s',
    max_restarts: 10,
    
    // 로그 설정
    log_file: '/opt/fairytale/logs/combined.log',
    out_file: '/opt/fairytale/logs/out.log',
    error_file: '/opt/fairytale/logs/error.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    
    // 환경변수 설정
    env: {
      NODE_ENV: 'development',
      SPRING_PROFILES_ACTIVE: 'dev'
    },
    
    env_production: {
      NODE_ENV: 'production',
      SPRING_PROFILES_ACTIVE: 'prod',
      LOG_LEVEL: 'WARN',
      SHOW_SQL: 'false',
      FORMAT_SQL: 'false'
    }
  }]
}
