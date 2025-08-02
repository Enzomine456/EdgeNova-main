app = "edgenova-main"
primary_region = "gru"

[build]
  dockerfile = "Dockerfile"

[env]
  PORT = "8000"

[[services]]
  internal_port = 8000
  protocol = "tcp"

  [[services.ports]]
    handlers = ["http"]
    port = 80

  [[services.ports]]
    handlers = ["tls", "http"]
    port = 443

[machines]
  cpus = 4         # Limita a 4 CPUs para evitar erro do Fly.io
  memory = 2048    # 2GB RAM, ajuste conforme necessidade

  # Quantidade de instâncias, opcional
  count = 2
