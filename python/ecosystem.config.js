module.exports = {
  apps: [{
    name: 'fastapi',
    script: 'uvicorn',
    args: 'ai_server:app --host 0.0.0.0 --port 8000',
    interpreter: '/opt/fairytale/python/venv/bin/python',
    cwd: '/opt/fairytale/python',
    env_file: '.env',
    instances: 1,
    autorestart: true,
    watch: false
  }]
};
