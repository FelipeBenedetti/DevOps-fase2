# Estágio de build
FROM python:3.9-slim AS builder

WORKDIR /app

# Copiar apenas os arquivos necessários para instalar dependências
COPY requirements.txt .

# Instalar dependências em uma camada separada
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Estágio final
FROM python:3.9-slim

WORKDIR /app

# Copiar dependências do estágio de build
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages

# Copiar o código da aplicação
COPY src/ ./src/

# Definir variáveis de ambiente
ENV PYTHONPATH=/app
ENV FLASK_APP=src/app.py
ENV FLASK_ENV=production

# Expor a porta que a aplicação utilizará
EXPOSE 5000

# Usuário não-root para segurança
RUN useradd -m appuser
USER appuser

# Comando para iniciar a aplicação
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "src.app:app"]
