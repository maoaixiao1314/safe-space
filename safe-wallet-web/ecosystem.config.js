module.exports = {
  apps: [{
    name: 'safe-web',
    script: 'yarn',
    args: 'dev',
    cwd: '/home/ubuntu/safe-space/safe-wallet-web/apps/web',
    env: {
      PORT: 3002,
      NODE_ENV: 'development'
    },
    error_file: '/home/ubuntu/safe-space/logs/safe-web-error.log',
    out_file: '/home/ubuntu/safe-space/logs/safe-web-out.log',
    time: true,
    autorestart: true,
    max_restarts: 10,
    min_uptime: '10s',
    restart_delay: 4000,
    watch: false,
    max_memory_restart: '2G'
  }]
};
