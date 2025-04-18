# Use an updated, more secure Python base image
FROM python:3.9-slim-bookworm as builder

# Install build dependencies with security fixes
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create and activate virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python dependencies with security patches
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip check

# --- Runtime stage ---
FROM python:3.9-slim-bookworm

# Update base image packages for security fixes
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# OpenShift security configurations
RUN useradd -m -u 1001 streamlit && \
    mkdir -p /app && \
    chown -R 1001:0 /app && \
    chmod -R g+rwX /app

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Set working directory and copy files with correct paths
WORKDIR /app
COPY app/main.py .
COPY requirements.txt .
COPY entrypoint.sh .

# Security hardening
# Fix permissions (critical change)
RUN chmod +x /app/entrypoint.sh && \
    chown 1001:0 /app/entrypoint.sh

# Switch to non-root user
USER 1001

# Streamlit configuration (without conflicting settings)
ENV STREAMLIT_SERVER_PORT=8080 \
    STREAMLIT_SERVER_HEADLESS=true \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Expose port
EXPOSE 8080

# Enhanced health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/_stcore/health || exit 1

# Optimized entrypoint
ENTRYPOINT ["./entrypoint.sh"]