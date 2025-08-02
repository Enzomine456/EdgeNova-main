app = "edgenova-main"
primary_region = "gru"

[build]
  dockerfile = "Dockerfile"

[env]
  PORT = "8000"
  HOST = "0.0.0.0"

[[services]]
  internal_port = 8000
  protocol = "tcp"

  [[services.ports]]
    handlers = ["http"]
    port = 80

  [[services.ports]]
    handlers = ["tls", "http"]
    port = 443

  [services.concurrency]
    type = "connections"
    hard_limit = 25
    soft_limit = 20

  [services.healthcheck]
    interval = 10000     # 10s
    timeout = 2000       # 2s
    unhealthy_threshold = 3
    healthy_threshold = 2
    method = "GET"
    path = "/"
    protocol = "http"

[machines]
  cpus = 4
  memory = 2048
  count = 2
