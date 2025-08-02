# --------------------------- #
#         STAGE 1: Build      #
# --------------------------- #
FROM python:3.10-slim AS builder

# Variáveis para reuso
ENV VENV_PATH="/opt/venv" \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Atualiza e instala dependências do sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    libffi-dev \
    curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Cria diretório da aplicação
WORKDIR /app

# Copia e instala dependências do Python
COPY requirements.txt .
RUN python -m venv $VENV_PATH \
    && $VENV_PATH/bin/pip install --upgrade pip setuptools wheel \
    && $VENV_PATH/bin/pip install -r requirements.txt

# --------------------------- #
#       STAGE 2: Runtime      #
# --------------------------- #
FROM python:3.10-slim

# Variáveis de ambiente para performance e segurança
ENV VENV_PATH="/opt/venv" \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    PORT=8000

# Cria usuário app seguro e fixo (evita conflitos entre hosts)
RUN useradd --create-home --uid 1000 appuser

# Define diretório padrão do app
WORKDIR /app

# Copia virtualenv do estágio anterior
COPY --from=builder $VENV_PATH $VENV_PATH

# Copia todo o app
COPY --chown=appuser:appuser . .

# Troca para o usuário seguro
USER appuser

# Expõe a porta (usada pelo Uvicorn)
EXPOSE 8000

# Comando de inicialização
CMD ["uvicorn", "edgenova:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
