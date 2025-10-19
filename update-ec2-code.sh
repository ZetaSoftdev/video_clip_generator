#!/bin/bash

# EC2 Code Update Script - Deploys latest backend2 integrated code
# This updates the EC2 instance with code that replaced ClipsAI

set -e

EC2_IP="34.205.131.51"
KEY_FILE="/Users/azeem/Desktop/dev/Editur AI/backend/editur-ai-key.pem"

echo "🚀 Updating EC2 Backend with Latest Code"
echo "=========================================="
echo "EC2 IP: $EC2_IP"
echo ""

# Check if EC2 is accessible
echo "📡 Checking EC2 connectivity..."
if ! ssh -i "$KEY_FILE" -o ConnectTimeout=10 ubuntu@$EC2_IP "echo 'Connected'" 2>/dev/null; then
    echo "❌ Cannot connect to EC2 instance"
    echo "⏳ Instance may still be initializing. Wait 5-10 minutes and try again."
    exit 1
fi

echo "✅ EC2 is accessible"
echo ""

# Pull latest code from GitHub
echo "📥 Pulling latest code from GitHub..."
ssh -i "$KEY_FILE" ubuntu@$EC2_IP << 'ENDSSH'
    cd /opt/editur-ai
    echo "Current directory: $(pwd)"
    echo "Git status before pull:"
    git status
    
    echo ""
    echo "Pulling latest changes..."
    git pull origin main
    
    echo ""
    echo "Latest commit:"
    git log --oneline -1
ENDSSH

echo ""
echo "✅ Code updated successfully"
echo ""

# Update .env to use STORAGE_TYPE=local
echo "⚙️  Updating .env configuration..."
ssh -i "$KEY_FILE" ubuntu@$EC2_IP << 'ENDSSH'
    cd /opt/editur-ai
    
    # Backup current .env
    cp .env .env.backup
    
    # Update STORAGE_TYPE to local
    sed -i 's/^STORAGE_TYPE=.*/STORAGE_TYPE=local/' .env
    
    echo "Updated .env settings:"
    grep "STORAGE_TYPE" .env
ENDSSH

echo "✅ Configuration updated"
echo ""

# Install/update Python dependencies
echo "📦 Installing updated dependencies..."
ssh -i "$KEY_FILE" ubuntu@$EC2_IP << 'ENDSSH'
    cd /opt/editur-ai
    source venv/bin/activate
    
    echo "Installing requirements..."
    pip install -r requirements.txt -q
    
    echo "✅ Dependencies installed"
ENDSSH

echo ""

# Restart services
echo "🔄 Restarting services..."
ssh -i "$KEY_FILE" ubuntu@$EC2_IP << 'ENDSSH'
    # Restart API service
    sudo systemctl restart editur-api
    echo "✅ API service restarted"
    
    # Restart worker service
    sudo systemctl restart editur-worker
    echo "✅ Worker service restarted"
    
    # Wait a moment for services to start
    sleep 3
    
    # Check service status
    echo ""
    echo "Service Status:"
    sudo systemctl status editur-api --no-pager | head -10
    echo ""
    sudo systemctl status editur-worker --no-pager | head -10
ENDSSH

echo ""
echo "✅ Services restarted successfully"
echo ""

# Test the API
echo "🧪 Testing API health..."
sleep 5
HEALTH_RESPONSE=$(curl -s http://$EC2_IP/api/health 2>&1)

if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    echo "✅ API is healthy!"
    echo "Response: $HEALTH_RESPONSE"
else
    echo "⚠️  API health check failed"
    echo "Response: $HEALTH_RESPONSE"
fi

echo ""
echo "================================================"
echo "✅ EC2 Backend Update Complete!"
echo "================================================"
echo ""
echo "🌐 API URL: http://$EC2_IP"
echo "📚 Docs: http://$EC2_IP/docs"
echo "❤️  Health: http://$EC2_IP/api/health"
echo ""
echo "🔍 Monitor logs:"
echo "   ssh -i $KEY_FILE ubuntu@$EC2_IP 'sudo journalctl -u editur-api -f'"
echo ""
