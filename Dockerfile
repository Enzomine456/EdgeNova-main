# Stage 1: Build
FROM python:3.10-slim AS builder

# Instala dependências do sistema necessárias para compilar pacotes Python
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia requirements para cache do pip
COPY requirements.txt .

# Cria ambiente virtual isolado
RUN python -m venv /opt/venv

# Atualiza pip e instala dependências no venv
RUN /opt/venv/bin/pip install --upgrade pip
RUN /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# Stage 2: Runtime
FROM python:3.10-slim

# Cria usuário não-root para rodar a aplicação
RUN useradd -m appuser

WORKDIR /app

# Copia ambiente virtual do build para o runtime
COPY --from=builder /opt/venv /opt/venv

# Copia o código fonte
COPY . .

# Usa o venv para rodar python e pip
ENV PATH="/opt/venv/bin:$PATH"

# Muda para usuário não-root por segurança
USER appuser

# Expõe a porta que a aplicação vai rodar
EXPOSE 8000

# Comando para rodar uvicorn com 4 workers (ajuste se precisar)
CMD ["uvicorn", "edgenova:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
