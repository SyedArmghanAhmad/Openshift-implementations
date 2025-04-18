#!/bin/sh

# Validate required env vars
: ${GROQ_API_KEY:?"ERROR: GROQ_API_KEY must be set"}

# Run Streamlit with minimal config
exec streamlit run main.py \
    --server.port=${STREAMLIT_SERVER_PORT:-8080} \
    --server.address=0.0.0.0