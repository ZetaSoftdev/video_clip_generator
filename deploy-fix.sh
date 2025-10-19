#!/bin/bash
set -e

KEY_FILE="/Users/azeem/Desktop/dev/Editur AI/backend/editur-ai-key.pem"
EC2_IP="34.205.131.51"

echo "🔄 Deploying storage_handler fix to EC2..."
echo ""

# Create a temporary script to run on EC2
cat > /tmp/ec2-deploy-commands.sh << 'DEPLOY_SCRIPT'
#!/bin/bash
set -e

cd /opt/editur-ai

echo "📥 Pulling latest code..."
git pull origin main

echo ""
echo "✅ Latest commit:"
git log --oneline -1

echo ""
echo "🔍 Verifying storage_handler fix:"
grep -n "dest_path.parent.mkdir" storage_handler.py || echo "⚠️  Fix not found!"

echo ""
echo "🔄 Restarting services..."
sudo systemctl restart editur-api
sudo systemctl restart editur-worker

echo ""
echo "⏳ Waiting 3 seconds for services to initialize..."
sleep 3

echo ""
echo "✅ Service status:"
sudo systemctl is-active editur-api
sudo systemctl is-active editur-worker

echo ""
echo "✅ Deployment complete!"
DEPLOY_SCRIPT

# Copy and execute the script on EC2
scp -i "$KEY_FILE" /tmp/ec2-deploy-commands.sh ubuntu@$EC2_IP:/tmp/
ssh -i "$KEY_FILE" ubuntu@$EC2_IP "bash /tmp/ec2-deploy-commands.sh"

echo ""
echo "🧪 Testing upload endpoint..."
curl -X POST http://$EC2_IP/api/upload-video \
  -F "file=@/tmp/test-video.mp4" \
  -F "num_clips=1" \
  -F "ratio=9:16" \
  -s | python3 -m json.tool || echo "Upload test failed"
