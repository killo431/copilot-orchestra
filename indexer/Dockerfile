FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source
COPY src/ ./src/
COPY .env.example .env

# Create directories for data and vector store
RUN mkdir -p /app/chroma_db /app/docs

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV DOCS_DIR=/app/docs
ENV CHROMA_PERSIST_DIR=/app/chroma_db

# Run the indexer
CMD ["python", "src/indexer.py"]
