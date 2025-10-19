#!/bin/bash
set -e

echo "=== Auto-Deploy Script for r6a.xlarge Instance ==="
echo "Instance: 3.238.229.163"
echo "Purpose: Deploy OOM fixes and test video processing"
echo ""

# System setup
echo "[1/8] Updating system packages..."
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y

# Install dependencies
echo "[2/8] Installing dependencies..."
sudo apt install -y \
  python3 python3-pip python3-venv \
  redis-server postgresql postgresql-contrib \
  git curl wget nginx \
  build-essential ffmpeg \
  htop

# Clone or update repository
echo "[3/8] Setting up application..."
if [ -d "/opt/editur-ai" ]; then
  cd /opt/editur-ai/backend
  git pull origin main
else
  sudo mkdir -p /opt/editur-ai
  cd /opt/editur-ai
  git clone https://github.com/ZetaSoftdev/video_clip_generator.git backend
  cd backend
fi

# Setup Python environment
echo "[4/8] Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Configure services
echo "[5/8] Configuring PostgreSQL..."
sudo -u postgres psql -c "CREATE USER editur WITH PASSWORD 'editur123';" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE editur_ai OWNER editur;" 2>/dev/null || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE editur_ai TO editur;" 2>/dev/null || true

# Setup environment variables
echo "[6/8] Configuring environment..."
cat > .env << 'EOF'
DATABASE_URL=postgresql://editur:editur123@localhost:5432/editur_ai
REDIS_URL=redis://localhost:6379/0
STORAGE_TYPE=local
WHISPER_MODEL_SIZE=base
AI_DEVICE=cpu
EOF

# Initialize database
echo "[7/8] Initializing database..."
source venv/bin/activate
python3 << 'PYEOF'
from database import init_database
init_database()
print("Database initialized successfully")
PYEOF

# Create systemd services
echo "[8/8] Creating systemd services..."

sudo tee /etc/systemd/system/editur-api.service > /dev/null << 'EOF'
[Unit]
Description=Editur AI API
After=network.target postgresql.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/editur-ai/backend
Environment="PATH=/opt/editur-ai/backend/venv/bin"
ExecStart=/opt/editur-ai/backend/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/editur-worker.service > /dev/null << 'EOF'
[Unit]
Description=Editur AI Celery Worker
After=network.target redis.service postgresql.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/editur-ai/backend
Environment="PATH=/opt/editur-ai/backend/venv/bin"
ExecStart=/opt/editur-ai/backend/venv/bin/celery -A tasks.celery_app worker --loglevel=info --concurrency=2
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start services
sudo systemctl daemon-reload
sudo systemctl enable editur-api editur-worker redis-server postgresql
sudo systemctl restart redis-server postgresql
sudo systemctl restart editur-api editur-worker

echo ""
echo "=== Deployment Complete! ==="
echo ""
echo "Services Status:"
sudo systemctl status editur-api --no-pager | head -5
sudo systemctl status editur-worker --no-pager | head -5
echo ""
echo "Memory Info:"
free -h | grep Mem
echo ""
echo "API Endpoint: http://3.238.229.163:8000"
echo "Docs: http://3.238.229.163:8000/docs"
echo ""
echo "To test video processing, upload skills5.mp4 via /docs interface"
echo "Monitor with: sudo journalctl -u editur-worker -f"
