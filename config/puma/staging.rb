rackup './server/app/config.ru'
environment 'staging'
pidfile './pid/puma.pid'
state_path './pid/puma.state'
stdout_redirect './logs/stdout.log', './logs/stderr.log', true
bind 'tcp://localhost:9294'
daemonize