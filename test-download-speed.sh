#!/bin/bash

echo "🚀 Testing Download Speed with Optimized Streaming..."
echo "======================================================"
echo ""

# Test download speed
echo "Downloading clip_01_Segment_1.mp4..."
time scp -i "/Users/azeem/Desktop/dev/Editur AI/backend/editur-ai-key.pem" \
  ubuntu@3.238.229.163:/opt/editur-ai/backend/storage/results/clips_processing/clip_01_Segment_1.mp4 \
  /tmp/test_download.mp4

if [ -f "/tmp/test_download.mp4" ]; then
    SIZE=$(ls -lh /tmp/test_download.mp4 | awk '{print $5}')
    echo ""
    echo "✅ Download complete!"
    echo "   File size: $SIZE"
    rm /tmp/test_download.mp4
else
    echo "❌ Download failed"
fi
