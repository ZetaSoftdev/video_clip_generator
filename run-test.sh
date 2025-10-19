#!/bin/bash

# Simple test script for video processing
echo "🚀 Testing Video Processing with skills5.mp4"
echo "=============================================="
echo ""

# Configuration
EC2_IP="3.238.229.163"
KEY_PATH="/Users/azeem/Desktop/dev/Editur AI/backend/editur-ai-key.pem"

echo "Step 1: Uploading video to EC2 API..."
RESPONSE=$(ssh -i "$KEY_PATH" ubuntu@$EC2_IP 'curl -s -X POST "http://localhost:8000/api/upload-video?num_clips=3&ratio=9:16" -F "file=@/tmp/skills5.mp4"')

echo "$RESPONSE"
echo ""

# Extract processing_id
PROCESSING_ID=$(echo "$RESPONSE" | grep -o '"processing_id":"[^"]*"' | cut -d'"' -f4)

if [ -z "$PROCESSING_ID" ]; then
    echo "❌ Failed to get processing_id"
    exit 1
fi

echo "✅ Processing ID: $PROCESSING_ID"
echo ""
echo "⏳ Waiting for processing to complete (this may take 5-10 minutes)..."
echo ""
echo "You can monitor logs with:"
echo "  ssh -i '$KEY_PATH' ubuntu@$EC2_IP 'sudo journalctl -u editur-worker -f'"
echo ""
echo "Or check status with:"
echo "  ssh -i '$KEY_PATH' ubuntu@$EC2_IP 'curl -s http://localhost:8000/api/status/$PROCESSING_ID | python3 -m json.tool'"
echo ""

# Save processing_id to a file
echo "$PROCESSING_ID" > /tmp/last_processing_id.txt
echo "💾 Processing ID saved to /tmp/last_processing_id.txt"
