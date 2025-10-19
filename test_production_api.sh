#!/bin/bash
"""
Test production API at api.editur.ai to create 3 reels with bestmili.mp4
"""

API_URL="http://34.232.105.133"
VIDEO_FILE="../bestmili.mp4"

echo "🧪 Testing Editur AI Production API"
echo "====================================="
echo "📡 API URL: $API_URL"
echo "📹 Video: $VIDEO_FILE"
echo "🎯 Creating 3 reels with bestmili.mp4"
echo ""

# Check if server is ready
echo "🔍 Checking server health..."
if curl -s "$API_URL/health" | grep -q "healthy"; then
    echo "✅ Server is healthy!"
else
    echo "❌ Server not ready yet. Please wait for setup to complete."
    exit 1
fi

echo ""
echo "📋 Getting API documentation..."
curl -s "$API_URL/docs" > /dev/null && echo "✅ API docs available at $API_URL/docs"

echo ""
echo "🎬 Starting video processing..."
echo "Uploading bestmili.mp4 and requesting 3 clips..."

# Upload video and process
response=$(curl -s -X POST "$API_URL/process" \
  -H "Content-Type: multipart/form-data" \
  -F "video=@$VIDEO_FILE" \
  -F "num_clips=3" \
  -F "aspect_ratio=9:16")

echo "📨 Response from server:"
echo "$response" | jq '.' 2>/dev/null || echo "$response"

# Extract job ID if available
job_id=$(echo "$response" | jq -r '.processing_id // .job_id // empty' 2>/dev/null)

if [ -n "$job_id" ]; then
    echo ""
    echo "🔄 Job ID: $job_id"
    echo "⏳ Monitoring progress..."
    
    # Monitor progress
    for i in {1..60}; do
        sleep 10
        status_response=$(curl -s "$API_URL/status/$job_id")
        status=$(echo "$status_response" | jq -r '.status // "unknown"' 2>/dev/null)
        progress=$(echo "$status_response" | jq -r '.progress_percentage // 0' 2>/dev/null)
        
        echo "📊 Progress: $progress% - Status: $status"
        
        if [ "$status" = "completed" ]; then
            echo ""
            echo "✅ Processing completed successfully!"
            echo "📋 Final results:"
            echo "$status_response" | jq '.' 2>/dev/null || echo "$status_response"
            
            # Try to get clips info
            clips_response=$(curl -s "$API_URL/results/$job_id")
            echo ""
            echo "🎬 Generated clips:"
            echo "$clips_response" | jq '.' 2>/dev/null || echo "$clips_response"
            break
        elif [ "$status" = "failed" ]; then
            echo "❌ Processing failed!"
            echo "$status_response"
            break
        fi
    done
else
    echo "❌ Could not extract job ID from response"
fi

echo ""
echo "🎉 Test completed!"