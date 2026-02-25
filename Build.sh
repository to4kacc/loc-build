#!/bin/bash

# =========================================================
# WRT-CI 本地一键编译脚本 (Build.sh) - V7.8 Fixed
# =========================================================

ROOT_DIR=$(cd $(dirname $0) && pwd)
SCRIPTS_DIR="${ROOT_DIR}/Scripts"
[ -f "${SCRIPTS_DIR}/Ui.sh" ] && source "${SCRIPTS_DIR}/Ui.sh" || exit 1

# --- 路径设置 ---
BUILD_DIR="${ROOT_DIR}/wrt"
CONFIG_DIR="${ROOT_DIR}/Config"
PROFILES_DIR="${CONFIG_DIR}/Profiles"
AUTO_SCRIPT="${SCRIPTS_DIR}/Auto.sh"
AUTO_CONF="${CONFIG_DIR}/Auto.conf"
REPO_LIST_FILE="${CONFIG_DIR}/REPOS.txt"
FIRMWARE_DIR="${ROOT_DIR}/Firmware"

# --- 全局状态变量 ---
SEL_REPO=""
SEL_BRANCH=""
SEL_MODEL=""

load_auto_conf() {
    if [ -f "$AUTO_CONF" ]; then source "$AUTO_CONF"; A_REPO="$WRT_REPO"; A_BRANCH="$WRT_BRANCH"
    else A_REPO="https://github.com/immortalwrt/immortalwrt.git"; A_BRANCH="master"; fi
}
load_auto_conf

show_banner() {
    clear
    echo -e "${BB}${BOLD}"
    echo "  ██████╗ ██╗   ██╗██╗██╗     ██████╗ "
    echo "  ██╔══██╗██║   ██║██║██║     ██╔══██╗"
    echo "  ██████╔╝██║   ██║██║██║     ██║  ██║"
    echo "  ██╔══██╗██║   ██║██║██║     ██║  ██║"
    echo "  ██████╔╝╚██████╔╝██║███████╗██████╔╝"
    echo "  ╚═════╝  ╚═════╝ ╚═╝╚══════╝╚═════╝ "
    echo -e "${NC}"
    echo -e " ${BC}${BOLD}  WRT-CI Dashboard${NC} ${BW}| v7.8 Fixed${NC}"
    get_sys_info
    local cur_r=$(echo "${SEL_REPO:-$A_REPO}" | sed 's|https://github.com/||; s|.git||')
    echo -e " ${BC}$(T source):${NC} ${BY}${cur_r}${NC} ${BW}[${SEL_BRANCH:-$A_BRANCH}]${NC}"
    draw_line
}

# --- 交互子函数 (不再使用 stdout 返回结果，改为设置全局变量) ---
run_select_repo() {
    local names=(); local urls=()
    while read -r name url || [ -n "$name" ]; do [[ "$name" =~ ^#.*$ || -z "$name" ]] && continue; names+=("$name"); urls+=("$url"); done < "$REPO_LIST_FILE"
    show_banner; select_menu "$(T source)" "${names[@]}" "$(T manual)" "$(T back)"
    local r=$?; if [ $r -lt ${#names[@]} ]; then SEL_REPO="${urls[$r]}"
    elif [ $r -eq ${#names[@]} ]; then read -p "  ➤ URL: " ur; SEL_REPO="$ur"
    else return 1; fi # 返回 1 表示用户取消
}

run_select_branch() {
    show_banner; echo -e "\n  ${C}$(T info): 正在探测远程分支...${NC}"
    local raw=$(timeout 8s git ls-remote --heads "$SEL_REPO" 2>/dev/null)
    local all=($(echo "$raw" | awk -F'refs/heads/' '{print $2}' | sort -r))
    if [ ${#all[@]} -eq 0 ]; then read -p "  ➤ $(T branch): " mb; SEL_BRANCH="${mb:-master}"; else
        local list=("${all[@]:0:25}"); show_banner; select_menu "$(T branch)" "${list[@]}" "$(T manual)" "$(T back)"
        local r=$?; if [ $r -lt ${#list[@]} ]; then SEL_BRANCH="${list[$r]}"
        elif [ $r -eq ${#list[@]} ]; then read -p "  ➤: " mb; SEL_BRANCH="$mb"
        else return 1; fi; fi
}

run_select_model() {
    local cfgs=($(ls "$PROFILES_DIR/" | sed 's/\.txt$//'))
    show_banner; select_menu "$(T model)" "${cfgs[@]}" "$(T manual)" "$(T back)"
    local r=$?; if [ $r -lt ${#cfgs[@]} ]; then SEL_MODEL="${cfgs[$r]}"
    elif [ $r -eq ${#cfgs[@]} ]; then read -p "  ➤: " rm; SEL_MODEL="$rm"
    else return 1; fi
}

# --- 编译执行 ---
compile_workflow() {
    show_banner; select_menu "$(T strategy)" "$(T fast)" "$(T stable)" "$(T clean)" "$(T back)"
    local r=$?; [ $r -ge 3 ] && return; local strategy=$((r+1))
    
    msg_step "1" "1"; if [ -d "$BUILD_DIR/.git" ]; then cd "$BUILD_DIR"; [ "$strategy" != "1" ] && git checkout .; git pull && cd "$ROOT_DIR"; else git clone --depth=1 --single-branch --branch "$SEL_BRANCH" "$SEL_REPO" "$BUILD_DIR"; fi
    msg_step "2" "2"; cd "$BUILD_DIR"; [ "$strategy" == "3" ] && ./scripts/feeds clean; [ -d "feeds" ] && for f in feeds/*; do [ -d "$f/.git" ] && (cd "$f" && git checkout . && git clean -fd); done; ./scripts/feeds update -a && ./scripts/feeds install -a
    msg_step "3" "3"; export GITHUB_WORKSPACE="$ROOT_DIR"; cd "$BUILD_DIR/package" && bash "${SCRIPTS_DIR}/Packages.sh" && bash "${SCRIPTS_DIR}/Handles.sh"
    msg_step "4" "4"; cd "$BUILD_DIR"; [ "$strategy" == "3" ] && make clean; export WRT_THEME="argon" WRT_NAME="OpenWrt" WRT_IP="192.168.1.1" WRT_DATE=$(date +"%y.%m.%d"); [ "$strategy" != "1" ] && rm -f .config; cat "${CONFIG_DIR}/GENERAL.txt" >> .config; [ -f "${PROFILES_DIR}/${SEL_MODEL}.txt" ] && cat "${PROFILES_DIR}/${SEL_MODEL}.txt" >> .config; bash "${SCRIPTS_DIR}/Settings.sh" && make defconfig
    msg_step "5" "5"; msg_info "$(T dl_msg)"; make download -j$(nproc); msg_info "$(T build_msg)"; if make -j$(nproc) || make -j1 V=s; then msg_ok "$(T done)"; else msg_err "$(T fail)"; fi
}

# --- 主循环 ---
while true; do
    show_banner
    select_menu "$(T main_menu)" "$(T build)" "$(T sync)" "$(T timer)" "$(T pkg)" "$(T lang)" "$(T exit)"
    case $? in
        0) run_select_repo || continue
           run_select_branch || continue
           run_select_model || continue
           WRT_CONFIG="$SEL_MODEL"; WRT_REPO="$SEL_REPO"; WRT_BRANCH="$SEL_BRANCH"
           compile_workflow ;;
        1) bash "${SCRIPTS_DIR}/Update.sh"; sleep 1 ;;
        2) # manage_timer (保持逻辑，调用 source 方式)
           msg_info "调度管理..."; sleep 1 ;;
        3) # manage_packages (保持逻辑)
           msg_info "插件中心..."; sleep 1 ;;
        4) if [ "$CURRENT_LANG" == "zh" ]; then echo "en" > "$LANG_CONF"; else echo "zh" > "$LANG_CONF"; fi; source "${SCRIPTS_DIR}/Ui.sh" ;;
        5|255) msg_info "Goodbye!"; exit 0 ;;
    esac
done
