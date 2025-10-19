#!/bin/bash

# Test video processing and monitor logs
# This script uploads skills5.mp4 and monitors the worker logs in real-time

echo "🚀 Starting video processing test with skills5.mp4..."
echo ""

# Upload the video and capture the processing_id
response=$(curl -s -X POST "http://localhost:8000/api/upload-video?num_clips=3&ratio=9:16" -F "file=@/tmp/skills5.mp4")
echo "📤 Upload Response:"
echo "$response" | python3 -m json.tool
echo ""

# Extract processing_id from response
processing_id=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin).get('processing_id', ''))")

if [ -z "$processing_id" ]; then
    echo "❌ Failed to get processing_id from response"
    exit 1
fi

echo "✅ Processing ID: $processing_id"
echo ""
echo "📊 Monitoring worker logs (Ctrl+C to stop)..."
echo "=============================================="
echo ""

# Monitor worker logs for this processing_id
sudo journalctl -u editur-worker -f --no-pager | grep --line-buffered "$processing_id\|📀\|🔍\|✅\|❌\|⚠️\|Error\|clip"
