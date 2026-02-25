#!/bin/bash

# =========================================================
# WRT-CI 代码更新脚本 (Update.sh)
# =========================================================

ROOT_DIR=$(cd $(dirname $0)/.. && pwd)
SCRIPTS_DIR="$ROOT_DIR/Scripts"
[ -f "${SCRIPTS_DIR}/Ui.sh" ] && source "${SCRIPTS_DIR}/Ui.sh" || exit 1

BUILD_DIR="$ROOT_DIR/wrt"

msg_info "Syncing local scripts..."
cd "$ROOT_DIR" && [ -d ".git" ] && git pull || msg_warn "Not a git repo."

msg_info "Syncing OpenWRT source..."
if [ -d "$BUILD_DIR/.git" ]; then
    cd "$BUILD_DIR" && git checkout . && git pull
else
    msg_err "Source directory missing."
fi

msg_info "Updating feeds..."
if [ -f "$BUILD_DIR/scripts/feeds" ]; then
    cd "$BUILD_DIR"
    for feed in feeds/*; do [ -d "$feed/.git" ] && (cd "$feed" && git checkout . && git clean -fd); done
    ./scripts/feeds update -a && ./scripts/feeds install -a
fi

msg_info "Syncing custom packages..."
export GITHUB_WORKSPACE="$ROOT_DIR"
cd "$BUILD_DIR/package" 2>/dev/null && bash "$SCRIPTS_DIR/Packages.sh"

msg_ok "Sync completed."
