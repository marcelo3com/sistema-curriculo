FROM python:3.12-slim

WORKDIR /app

# Evita gerar bytecode .pyc e força flush imediato de logs
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app/src

# Instala ferramentas do sistema para healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Instala dependências Python da aplicação
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia código-fonte e configurações
COPY src/ ./src/
COPY alembic.ini .

# Cria usuário não-root por segurança (Conforme diretriz do Card #422 / F12.4)
RUN useradd -u 1000 -m appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 3000

# Inicializa o servidor FastAPI com Uvicorn
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "3000"]
