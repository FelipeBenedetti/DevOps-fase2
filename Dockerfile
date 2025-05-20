# Estágio de build
FROM python:3.9-slim AS builder

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Estágio final
FROM python:3.9-slim

WORKDIR /app

# Copiar dependências instaladas corretamente
COPY --from=builder /usr/local /usr/local

# Copiar código da aplicação
COPY src/ ./src/

# Variáveis de ambiente
ENV PYTHONPATH=/app
ENV FLASK_APP=src/app.py
ENV FLASK_ENV=production

EXPOSE 5000

# Usuário não-root para segurança
RUN useradd -m appuser
USER appuser

# Executar com gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "src.app:app"]
