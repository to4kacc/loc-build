#!/bin/bash

# =========================================================
# WRT-CI 一键部署与同步脚本 (Install.sh)
# =========================================================

C='\033[0;36m'; G='\033[0;32m'; NC='\033[0m'
GITHUB_USER="breeze303"
REPO_NAME="loc-build"

if [[ "$(basename "$(pwd)")" != "$REPO_NAME" ]]; then
    TARGET_DIR="$(pwd)/$REPO_NAME"
else
    TARGET_DIR="$(pwd)"
fi

echo -e "${C}>>> Syncing $REPO_NAME ...${NC}"
if ! command -v git &> /dev/null; then
    sudo apt update && sudo apt install -y git
fi

if [ ! -d "$TARGET_DIR" ]; then
    git clone "https://github.com/$GITHUB_USER/$REPO_NAME.git" "$TARGET_DIR"
else
    cd "$TARGET_DIR" && git pull
fi

cd "$TARGET_DIR"
chmod +x Build.sh Scripts/*.sh 2>/dev/null
echo -e "${G}>>> Done. Starting Dashboard...${NC}"
sleep 1
./Build.sh
