#!/bin/bash
# Deployment script for word-level caption fixes

set -e

echo "======================================"
echo "Word-Level Caption System Deployment"
echo "======================================"
echo ""

# Check if we're in the backend directory
if [ ! -f "main.py" ]; then
    echo "Error: Must run from backend directory"
    exit 1
fi

echo "1. Checking system dependencies..."
command -v ffmpeg >/dev/null 2>&1 || { echo "  Installing ffmpeg..."; sudo apt-get install -y ffmpeg || brew install ffmpeg; }
command -v ffprobe >/dev/null 2>&1 || { echo "  ffprobe missing!"; exit 1; }
echo "  ✓ FFmpeg installed"

echo ""
echo "2. Checking Python dependencies..."
python3 -c "import fastapi" 2>/dev/null || { echo "  Installing requirements..."; pip3 install -r requirements.txt; }
echo "  ✓ Python packages installed"

echo ""
echo "3. Checking environment configuration..."
if [ ! -f ".env" ]; then
    echo "  Creating .env from template..."
    cp env.template .env
fi

if ! grep -q "OPENAI_API_KEY=" .env; then
    echo "  ⚠️  OPENAI_API_KEY not found in .env"
    echo "  Add: OPENAI_API_KEY=sk-xxxx to .env file"
    echo "  This enables word-level transcription fallback"
fi

echo ""
echo "4. Testing transcription service..."
python3 -c "
import sys
sys.path.insert(0, '.')
from services.transcription import TranscriptionService
svc = TranscriptionService()
print('  WhisperX:', 'AVAILABLE' if svc.whisperx_available else 'NOT AVAILABLE')
print('  Faster Whisper:', 'AVAILABLE' if svc.faster_whisper_available else 'NOT AVAILABLE')
import config
print('  OpenAI API:', 'CONFIGURED' if config.OPENAI_API_KEY else 'NOT CONFIGURED')
"

echo ""
echo "5. Git status..."
git status --short services/ || echo "  (Not a git repository)"

echo ""
echo "======================================"
echo "Deployment Summary"
echo "======================================"
echo "Modified files:"
echo "  - services/transcription.py (OpenAI API fallback)"
echo "  - services/video_service.py (word-level JSON generation)"
echo "  - services/edit.py (ffmpeg path fixes)"
echo ""
echo "To deploy to production:"
echo "  1. Add OPENAI_API_KEY to production environment"
echo "  2. git add services/"
echo "  3. git commit -m 'Fix: Word-level caption generation'"
echo "  4. git push origin main"
echo "  5. Restart: celery-worker + fastapi"
echo ""
echo "To test locally:"
echo "  python3 test_aimod.py"
echo ""
