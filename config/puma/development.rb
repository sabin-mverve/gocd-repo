rackup './server/app/config.ru'
environment 'development'
pidfile './pid/puma.pid'
state_path './pid/puma.state'
bind 'tcp://localhost:9294'
daemonize false