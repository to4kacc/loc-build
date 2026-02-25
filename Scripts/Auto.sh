#!/bin/bash

# =========================================================
# WRT-CI 本地定时编译脚本 (Auto.sh) - V7.5 Refactored
# =========================================================

ROOT_DIR=$(cd $(dirname $0)/.. && pwd)
BUILD_DIR="${ROOT_DIR}/wrt"
LOG_DIR="${ROOT_DIR}/Logs"
RELEASE_DIR="${ROOT_DIR}/bin/auto-builds"
CONFIG_DIR="${ROOT_DIR}/Config"
PROFILES_DIR="${CONFIG_DIR}/Profiles"
CONFIG_FILE="${CONFIG_DIR}/Auto.conf"
DATE=$(date +"%Y%m%d-%H%M")

# --- 加载配置 ---
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    KEEP_CACHE="true"; CACHE_ITEMS=("dl" "staging_dir")
    WRT_REPO="https://github.com/immortalwrt/immortalwrt.git"
    WRT_BRANCH="master"; WRT_CONFIGS=("X86")
fi

mkdir -p "$LOG_DIR" "$RELEASE_DIR"
LOG_FILE="$LOG_DIR/build-$DATE.log"
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

log "🚀 Pipeline Start (Cache: $KEEP_CACHE)"

# 执行颗粒度清理
if [ -d "$BUILD_DIR" ]; then
    cd "$BUILD_DIR"
    if [ "$KEEP_CACHE" == "false" ]; then
        make dirclean >> "$LOG_FILE" 2>&1
    else
        all_items=("dl" "staging_dir" "build_dir" "bin/packages" ".ccache")
        for item in "${all_items[@]}"; do
            [[ ! " ${CACHE_ITEMS[*]} " =~ " ${item} " ]] && rm -rf "$item"
        done
    fi
fi

# 1. 源码同步
if [ ! -d "$BUILD_DIR/.git" ]; then
    git clone --depth=1 --single-branch --branch "$WRT_BRANCH" "$WRT_REPO" "$BUILD_DIR" >> "$LOG_FILE" 2>&1
else
    cd "$BUILD_DIR" && git checkout . && git pull origin "$WRT_BRANCH" >> "$LOG_FILE" 2>&1
fi

# 2. 循环编译
for CONFIG in "${WRT_CONFIGS[@]}"; do
    log "📦 Building: $CONFIG"
    cd "$BUILD_DIR"; rm -rf "./bin/targets/"
    [ -f "${CONFIG_DIR}/GENERAL.txt" ] && cat "${CONFIG_DIR}/GENERAL.txt" > .config
    [ -f "${PROFILES_DIR}/${CONFIG}.txt" ] && cat "${PROFILES_DIR}/${CONFIG}.txt" >> .config
    export WRT_THEME="argon" WRT_NAME="OpenWrt" WRT_MARK="Auto" WRT_DATE=$(date +"%y.%m.%d")
    bash "${ROOT_DIR}/Scripts/Settings.sh" >> "$LOG_FILE" 2>&1
    make defconfig >> "$LOG_FILE" 2>&1
    make download -j$(nproc) >> "$LOG_FILE" 2>&1
    make -j$(nproc) >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
        TARGET_RELEASE="${RELEASE_DIR}/${CONFIG}-${DATE}"
        mkdir -p "$TARGET_RELEASE"
        find ./bin/targets/ -type f \( -name "*.img.gz" -o -name "*.bin" \) -exec cp {} "$TARGET_RELEASE/" \;
        log "✅ Success: $CONFIG"
    else log "❌ Failure: $CONFIG"; fi
done
log "🏁 Finished."
