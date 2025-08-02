# Stage 1: Build
FROM python:3.10-slim AS builder

# Instala dependências do sistema necessárias para compilar pacotes Python
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia apenas o requirements para cache do pip
COPY requirements.txt .

# Cria um ambiente virtual para isolação
RUN python -m venv /opt/venv

# Ativa o venv e instala dependências
RUN /opt/venv/bin/pip install --upgrade pip
RUN /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# Stage 2: Runtime
FROM python:3.10-slim

# Cria usuário não-root para rodar a aplicação
RUN useradd -m appuser

WORKDIR /app

# Copia ambiente virtual do build
COPY --from=builder /opt/venv /opt/venv

# Copia código fonte
COPY . .

# Usa o venv para rodar os comandos python/pip
ENV PATH="/opt/venv/bin:$PATH"

# Expor a porta que a aplicação vai rodar
EXPOSE 8000

# Variável de ambiente para uvicorn (pode ser sobrescrita no fly.toml)
ENV HOST=0.0.0.0
ENV PORT=8000

# Healthcheck para verificar se a aplicação está viva
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:${PORT}/ || exit 1

# Muda para usuário não-root por segurança
USER appuser

# Comando para rodar uvicorn
CMD ["uvicorn", "edgenova:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
