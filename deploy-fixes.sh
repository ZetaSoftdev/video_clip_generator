#!/bin/bash

# Deploy fixes to EC2
# This script:
# 1. Commits and pushes code to GitHub
# 2. Pulls code on EC2
# 3. Updates systemd service with correct PATH
# 4. Restarts services

set -e

echo "🚀 Starting deployment of fixes to EC2..."

# Configuration
EC2_IP="3.238.229.163"
KEY_PATH="/Users/azeem/Desktop/dev/Editur AI/backend/editur-ai-key.pem"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Step 1: Committing and pushing code to GitHub${NC}"
git add -A
git commit -m "Fix: Add full PATH to systemd service for ffmpeg/ffprobe access" || echo "No changes to commit"
git push origin main

echo -e "${GREEN}✅ Code pushed to GitHub${NC}"

echo -e "${BLUE}Step 2: Deploying to EC2${NC}"

ssh -i "$KEY_PATH" ubuntu@$EC2_IP << 'ENDSSH'
set -e

echo "📥 Pulling latest code from GitHub..."
cd /opt/editur-ai/backend
git pull origin main

echo "📝 Updating systemd service file..."
sudo cp editur-worker.service /etc/systemd/system/editur-worker.service
sudo systemctl daemon-reload

echo "🔄 Restarting services..."
sudo systemctl restart editur-worker
sudo systemctl restart editur-api

echo "✅ Services restarted"

echo "📊 Checking service status..."
sudo systemctl status editur-worker --no-pager | head -15
echo ""
sudo systemctl status editur-api --no-pager | head -15

ENDSSH

echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo "🧪 You can now test with:"
echo "   curl -X POST \"http://$EC2_IP:8000/api/upload-video?num_clips=3&ratio=9:16\" -F \"file=@skills5.mp4\""
