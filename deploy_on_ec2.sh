#!/bin/bash

# Quick deployment script for OOM fixes
# Run this on your EC2 instance to deploy the fixes

set -e  # Exit on error

echo "========================================="
echo "Deploying Video Processing OOM Fixes"
echo "========================================="
echo ""

# Check if running on EC2 or need to SSH
if [ -f "/opt/editur-ai/backend/config.py" ]; then
    echo "✓ Running on EC2 instance"
    BACKEND_DIR="/opt/editur-ai/backend"
else
    echo "This script should be run on the EC2 instance"
    echo "To deploy from local machine, use:"
    echo "  scp deploy_on_ec2.sh ubuntu@api.editur.ai:~/"
    echo "  ssh ubuntu@api.editur.ai 'bash ~/deploy_on_ec2.sh'"
    exit 1
fi

cd $BACKEND_DIR

echo ""
echo "Step 1: Backing up current version..."
git rev-parse HEAD > /tmp/editur-backup-commit.txt
echo "  Backup commit: $(cat /tmp/editur-backup-commit.txt)"

echo ""
echo "Step 2: Pulling latest code..."
git fetch origin
git pull origin main

echo ""
echo "Step 3: Activating virtual environment..."
source venv/bin/activate

echo ""
echo "Step 4: Running cleanup script to mark stuck jobs as failed..."
python cleanup_stuck_jobs.py --max-time 20 || echo "  (No stuck jobs or script needs adjustment)"

echo ""
echo "Step 5: Restarting services..."
sudo systemctl restart editur-worker
sleep 2
sudo systemctl restart editur-api
sleep 2

echo ""
echo "Step 6: Checking service status..."
echo "Worker Status:"
sudo systemctl status editur-worker --no-pager | head -n 10

echo ""
echo "API Status:"
sudo systemctl status editur-api --no-pager | head -n 10

echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="
echo ""
echo "To monitor jobs, run:"
echo "  cd $BACKEND_DIR"
echo "  source venv/bin/activate"
echo "  python monitor_jobs.py --watch"
echo ""
echo "To check logs:"
echo "  sudo journalctl -u editur-worker -f"
echo ""
echo "To rollback if needed:"
echo "  cd $BACKEND_DIR"
echo "  git checkout \$(cat /tmp/editur-backup-commit.txt)"
echo "  sudo systemctl restart editur-worker"
echo "  sudo systemctl restart editur-api"
echo ""
