#!/bin/sh

# Ensure we have executable permissions
chmod +x start.sh

# Create logs directory
mkdir -p /var/log/nginx

# Check if we're in a Railway environment
if [ -n "$RAILWAY_ENVIRONMENT" ]; then
  echo "Running in Railway environment"
  # Use Railway environment variables if available
  export PORT=${PORT:-3000}
  export HOST=${HOST:-0.0.0.0}
else
  # Default values for local development
  export PORT=3000
  export HOST=0.0.0.0
fi

# Start Nginx as a background process
echo "Starting Nginx..."
nginx -g "daemon off;" &

# Start Node.js backend
echo "Starting Node.js backend on port $PORT..."
cd /app && node dist/index.js 