#!/usr/bin/env python3
import subprocess
import sys
import time
import json

KEY_FILE = "/Users/azeem/Desktop/dev/Editur AI/backend/editur-ai-key.pem"
EC2_IP = "3.238.229.163"

def run_ssh_command(command):
    """Run SSH command and return output"""
    full_cmd = [
        "ssh",
        "-i", KEY_FILE,
        "-o", "StrictHostKeyChecking=no",
        "-o", "ConnectTimeout=15",
        f"ubuntu@{EC2_IP}",
        command
    ]
    
    try:
        result = subprocess.run(full_cmd, capture_output=True, text=True, timeout=30)
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return -1, "", "Command timed out"
    except Exception as e:
        return -1, "", str(e)

def main():
    print("🔄 Deploying storage_handler fix to EC2...")
    print()
    
    # Step 1: Pull latest code
    print("📥 Step 1: Pulling latest code from GitHub...")
    code, stdout, stderr = run_ssh_command("cd /opt/editur-ai/backend && git pull origin main 2>&1")
    output = stdout + stderr
    if "Already up to date" in output or "Updating" in output or "Fast-forward" in output:
        print(output)
    elif code != 0:
        print(f"⚠️  Git pull output: {output}")
        # Continue anyway as it might just be warnings
    else:
        print(output)
    
    # Step 2: Verify fix is present
    print("\n✅ Step 2: Verifying storage_handler fix...")
    code, stdout, stderr = run_ssh_command("grep -n 'dest_path.parent.mkdir' /opt/editur-ai/backend/storage_handler.py")
    if code == 0:
        print(f"✅ Fix found at: {stdout.strip()}")
    else:
        print(f"⚠️  Fix not found in file!")
        return 1
    
    # Step 3: Set storage type to local
    print("\n🔄 Step 3: Setting storage type to local...")
    code, stdout, stderr = run_ssh_command("sed -i 's/^STORAGE_TYPE=.*/STORAGE_TYPE=local/' /opt/editur-ai/backend/.env")
    if code == 0:
        print("✅ Storage type set to local")
    else:
        print(f"⚠️  Failed to set storage type: {stderr}")
    
    # Step 4: Create storage directory
    print("\n📁 Step 4: Creating storage directory...")
    code, stdout, stderr = run_ssh_command("mkdir -p /opt/editur-ai/backend/storage && chmod 777 /opt/editur-ai/backend/storage")
    if code == 0:
        print("✅ Storage directory created and permissions set")
    else:
        print(f"⚠️  Failed to create storage directory: {stderr}")
    
    # Step 5: Restart services
    print("\n🔄 Step 5: Restarting backend services...")
    code, stdout, stderr = run_ssh_command("sudo systemctl restart editur-api editur-worker 2>&1")
    if code != 0:
        print(f"❌ Service restart failed: {stderr}")
        return 1
    print("✅ Services restart initiated")
    
    # Step 6: Wait for services
    print("\n⏳ Step 6: Waiting 5 seconds for services to initialize...")
    time.sleep(5)
    
    # Step 7: Check service status
    print("\n🔍 Step 7: Checking service status...")
    code, stdout, stderr = run_ssh_command("sudo systemctl is-active editur-api editur-worker 2>&1")
    print(stdout)
    
    if "active" in stdout.lower():
        print("\n✅ Deployment successful!")
        return 0
    else:
        print("\n⚠️  Services may not be active. Check logs on EC2.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
