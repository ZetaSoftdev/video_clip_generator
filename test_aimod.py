#!/usr/bin/env python3
import asyncio
import sys
import json
from pathlib import Path
sys.path.insert(0, '.')
from services.video_service import VideoService

async def test():
    print("Testing aimod.mp4 word-level caption generation...")
    service = VideoService()
    result = await service.process_video(video_path='aimod.mp4', num_clips=1, burn_captions=False)
    
    clips = result.get('processed_clips', [])
    if not clips:
        print("FAILED: No clips generated")
        return False
    
    caption_path = clips[0].get('caption_path')
    if not caption_path or not Path(caption_path).exists():
        print(f"FAILED: Caption file missing at {caption_path}")
        return False
    
    with open(caption_path) as f:
        data = json.load(f)
    
    segments = data.get('segments', [])
    total_words = sum(len(s.get('words', [])) for s in segments)
    
    print(f"SUCCESS: {len(segments)} segments, {total_words} words")
    print(f"Caption file: {caption_path}")
    
    if segments:
        first_seg = segments[0]
        print(f"First segment: {len(first_seg.get('words', []))} words")
        if first_seg.get('words'):
            print(f"First word: {first_seg['words'][0]}")
    
    return True

if __name__ == "__main__":
    result = asyncio.run(test())
    sys.exit(0 if result else 1)
