#!/bin/bash

# =========================================================
# WRT-CI 本地一键编译脚本 (Build.sh) - V12.5 Ultimate Pro
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
LAST_CONF="${CONFIG_DIR}/.last_build.conf"
REPO_LIST_FILE="${CONFIG_DIR}/REPOS.txt"
CORE_PKG_FILE="${CONFIG_DIR}/CORE_PACKAGES.txt"
CUSTOM_PKG_FILE="${CONFIG_DIR}/CUSTOM_PACKAGES.txt"
FIRMWARE_DIR="${ROOT_DIR}/Firmware"

# --- 状态变量 ---
WRT_IP="192.168.1.1"; WRT_NAME="OpenWrt"; WRT_SSID="OpenWrt"; WRT_WORD="12345678"; WRT_THEME="argon"
SEL_REPO=""; SEL_BRANCH=""; SEL_MODEL=""
A_REPO=""; A_BRANCH=""; A_CONFIGS=(); A_KEEP_CACHE="true"; A_ITEMS=()

load_auto_conf() {
    if [ -f "$AUTO_CONF" ]; then
        source "$AUTO_CONF"
        A_REPO="$WRT_REPO"; A_BRANCH="$WRT_BRANCH"; A_KEEP_CACHE="$KEEP_CACHE"
        [[ "$(declare -p WRT_CONFIGS 2>/dev/null)" == "declare -a"* ]] && A_CONFIGS=("${WRT_CONFIGS[@]}") || A_CONFIGS=("$WRT_CONFIGS")
        [[ "$(declare -p CACHE_ITEMS 2>/dev/null)" == "declare -a"* ]] && A_ITEMS=("${CACHE_ITEMS[@]}") || A_ITEMS=()
    else
        A_REPO="https://github.com/immortalwrt/immortalwrt.git"; A_BRANCH="master"; A_CONFIGS=("X86"); A_KEEP_CACHE="true"; A_ITEMS=("dl" "staging_dir")
    fi
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
    echo -e " ${BC}${BOLD}  WRT-CI Dashboard${NC} ${BW}| v12.5 Full${NC}"
    get_sys_info
    local cur_r=$(echo "${SEL_REPO:-$A_REPO}" | sed 's|https://github.com/||; s|.git||')
    echo -e " ${BC}$(T source):${NC} ${BY}${cur_r}${NC} ${BW}[${SEL_BRANCH:-$A_BRANCH}]${NC}"
    draw_line
}

# --- 功能逻辑: 保存与归档 ---
save_last_build() {
    { echo "L_REPO=\"$SEL_REPO\""; echo "L_BRANCH=\"$SEL_BRANCH\""; echo "L_MODEL=\"$SEL_MODEL\""
      echo "L_IP=\"$WRT_IP\""; echo "L_NAME=\"$WRT_NAME\""; echo "L_SSID=\"$WRT_SSID\""
      echo "L_WORD=\"$WRT_WORD\""; echo "L_THEME=\"$WRT_THEME\""; } > "$LAST_CONF"
}

archive_firmware() {
    msg_step "6"; local date=$(date +"%y.%m.%d")
    local target_dir=$(find "$BUILD_DIR/bin/targets/" -type d -mindepth 2 -maxdepth 2 | head -n 1)
    if [ -n "$target_dir" ]; then
        mkdir -p "$FIRMWARE_DIR"
        find "$target_dir" -type f \( -name "*.img.gz" -o -name "*.bin" -o -name "*.tar.gz" \) | while read -r file; do
            local ext="${file##*.}"
            cp "$file" "$FIRMWARE_DIR/WRT-${WRT_CONFIG:-OpenWrt}-${date}.${ext}"
        done
        msg_ok "存档至: $FIRMWARE_DIR"
    fi
}

# --- 功能逻辑: 交互选择 ---
run_select_repo() {
    local names=(); local urls=(); while read -r n u || [ -n "$n" ]; do [[ "$n" =~ ^#.*$ || -z "$n" ]] && continue; names+=("$n"); urls+=("$u"); done < "$REPO_LIST_FILE"
    show_banner; select_menu "$(T source)" "${names[@]}" "手动" "返回"; [ "$RET_IDX" -ge $((${#names[@]} + 1)) ] && return 1
    [ "$RET_IDX" -lt "${#names[@]}" ] && SEL_REPO="${urls[$RET_IDX]}" || read -p " ➤ URL: " SEL_REPO; return 0
}

run_select_branch() {
    show_banner; msg_info "正在探测远程分支..."
    local raw=$(timeout 8s git ls-remote --heads "$SEL_REPO" 2>/dev/null); local all=($(echo "$raw" | awk -F'refs/heads/' '{print $2}' | sort -r))
    if [ ${#all[@]} -eq 0 ]; then read -p " ➤ Branch: " SEL_BRANCH; return 0; else
    local list=("${all[@]:0:20}"); select_menu "Branch :" "${list[@]}" "手动" "返回"; [ "$RET_IDX" -ge $((${#list[@]} + 1)) ] && return 1
    [ "$RET_IDX" -lt "${#list[@]}" ] && SEL_BRANCH="${list[$RET_IDX]}" || read -p " ➤: " SEL_BRANCH; return 0; fi
}

run_select_model() {
    local cs=($(ls "$PROFILES_DIR/" | sed 's/\.txt$//')); show_banner; select_menu "Model :" "${cs[@]}" "手动" "返回"; [ "$RET_IDX" -ge $((${#cs[@]} + 1)) ] && return 1
    [ "$RET_IDX" -lt "${#cs[@]}" ] && SEL_MODEL="${cs[$RET_IDX]}" || read -p " ➤ Name: " SEL_MODEL; return 0
}

# --- 功能逻辑: 子菜单 ---
manage_packages() {
    while true; do
        show_banner; select_menu "$(T pkg) :" "查看插件清单" "添加自定义插件" "删除自定义插件" "手动编辑文件" "检查更新版本" "返回"
        case $RET_IDX in
            0) show_banner; msg_info "Core"; grep -v "^#" "$CORE_PKG_FILE" | awk '{printf " - %-18s %s\n", $1, $2}'; draw_line; read -p " Enter..." ;;
            1) read -p " ➤ Name: " pn; read -p " ➤ Repo: " pr; echo "$pn $pr master _ _" >> "$CUSTOM_PKG_FILE"; msg_ok "OK"; sleep 1 ;;
            2) read -p " ➤ Name: " dn; sed -i "/^$dn /d" "$CUSTOM_PKG_FILE"; msg_ok "OK"; sleep 1 ;;
            3) ${EDITOR:-vi} "$CUSTOM_PKG_FILE" ;;
            4) bash "${SCRIPTS_DIR}/Packages.sh" ver; read -p " Enter..." ;;
            *) return ;;
        esac
    done
}

config_auto_build() {
    while true; do
        show_banner; echo -e "  ◈ Source: $A_REPO\n  ◈ Model: ${A_CONFIGS[*]}\n  ◈ Cache: $A_KEEP_CACHE"; draw_line
        select_menu "Pipeline Config :" "修改仓库" "管理机型" "配置缓存" "保存并返回" "取消"
        case $RET_IDX in
            0) run_select_repo && A_REPO="$SEL_REPO" ;;
            1) local cfgs=($(ls "$PROFILES_DIR/" | sed 's/\.txt$//')); multi_select_menu "Models :" "${cfgs[@]}"
               if [[ "$RET_VAL" != "BACK" && -n "$RET_VAL" ]]; then A_CONFIGS=(); for i in $RET_VAL; do A_CONFIGS+=("${cfgs[$i]}"); done; fi ;;
            2) select_menu "Cache :" "Keep" "Clean"; [ $RET_IDX -eq 0 ] && A_KEEP_CACHE="true" || A_KEEP_CACHE="false" ;;
            3) { echo "WRT_REPO=\"$A_REPO\""; echo "WRT_BRANCH=\"$A_BRANCH\""; echo "KEEP_CACHE=\"$A_KEEP_CACHE\""
                 echo -n "WRT_CONFIGS=("; for c in "${A_CONFIGS[@]}"; do echo -n "\"$c\" "; done; echo ")"; } > "$AUTO_CONF"; return ;;
            *) return ;;
        esac
    done
}

manage_timer() {
    while true; do
        show_banner; select_menu "$(T timer) :" "设定计划" "检查活跃计划" "自动化流水线配置" "查看实时日志" "返回"
        case $RET_IDX in
            0) read -p " ➤ H: " th; read -p " ➤ M: " tm; (crontab -l 2>/dev/null | grep -v "$AUTO_SCRIPT"; echo "$tm $th * * * /bin/bash $AUTO_SCRIPT") | crontab -; msg_ok "OK"; sleep 1 ;;
            1) local c=$(crontab -l 2>/dev/null | grep "$AUTO_SCRIPT"); [ -n "$c" ] && msg_ok "Active: $c" || msg_warn "None"; read -p " Enter..." ;;
            2) config_auto_build ;;
            3) local l=$(ls -t "$ROOT_DIR/Logs/"*.log 2>/dev/null | head -n 1); [ -f "$l" ] && tail -f "$l" || msg_err "None"; sleep 1 ;;
            *) return ;;
        esac
    done
}

# --- 核心流水线 ---
compile_workflow() {
    save_last_build
    local strategy="2"; if [ -d "$BUILD_DIR/bin" ]; then show_banner; select_menu "Strategy :" "Fast" "Standard" "Clean" "Back"; [ $RET_IDX -ge 3 ] && return; strategy=$((RET_IDX+1)); fi
    msg_step "1"; if [ -d "$BUILD_DIR/.git" ]; then cd "$BUILD_DIR"; [ "$strategy" != "1" ] && git checkout .; git pull && cd "$ROOT_DIR"; else git clone --depth=1 --single-branch --branch "$SEL_BRANCH" "$SEL_REPO" "$BUILD_DIR"; fi
    msg_step "2"; cd "$BUILD_DIR"; [ "$strategy" == "3" ] && ./scripts/feeds clean; [ -d "feeds" ] && for f in feeds/*; do [ -d "$f/.git" ] && (cd "$f" && git checkout . && git clean -fd); done; ./scripts/feeds update -a && ./scripts/feeds install -a
    msg_step "3"; export GITHUB_WORKSPACE="$ROOT_DIR"; cd "$BUILD_DIR/package" && bash "${SCRIPTS_DIR}/Packages.sh" && bash "${SCRIPTS_DIR}/Handles.sh"
    msg_step "4"; cd "$BUILD_DIR"; [ "$strategy" == "3" ] && make clean; [ "$strategy" != "1" ] && rm -f .config; cat "${CONFIG_DIR}/GENERAL.txt" >> .config; [ -f "${PROFILES_DIR}/${SEL_MODEL}.txt" ] && cat "${PROFILES_DIR}/${SEL_MODEL}.txt" >> .config; bash "${SCRIPTS_DIR}/Settings.sh"; make defconfig
    msg_step "5"; msg_info "$(T dl_msg)"; make download -j$(nproc); msg_info "$(T build_msg)"; if make -j$(nproc) || make -j1 V=s; then msg_ok "$(T done)"; archive_firmware; else msg_err "$(T fail)"; fi
}

# --- 主程序入口 ---
while true; do
    show_banner
    select_menu "$(T main_menu)" "启动全流程交互编译" "再次重编上个机型" "仅同步代码与插件" "调度任务管理中心" "插件管理与维护" "系统脚本自更新" "初始化编译环境" "切换显示语言" "结束当前会话"
    case $RET_IDX in
        0) run_select_repo && run_select_branch && run_select_model && compile_workflow ;;
        1) if [ -f "$LAST_CONF" ]; then source "$LAST_CONF"; SEL_REPO="$L_REPO"; SEL_BRANCH="$L_BRANCH"; SEL_MODEL="$L_MODEL"; compile_workflow; else msg_warn "None"; sleep 1; fi ;;
        2) bash "${SCRIPTS_DIR}/Update.sh"; sleep 1 ;;
        3) manage_timer ;;
        4) manage_packages ;;
        5) msg_info "Updating..."; git pull && (msg_ok "Updated!"; exit 0) || msg_err "Failed"; sleep 1 ;;
        6) sudo bash -c 'bash <(curl -sL https://build-scripts.immortalwrt.org/init_build_environment.sh)'; read -p " Enter..." ;;
        7) [ "$CURRENT_LANG" == "zh" ] && echo "en" > "$LANG_CONF" || echo "zh" > "$LANG_CONF"; source "${SCRIPTS_DIR}/Ui.sh" ;;
        8|255) exit 0 ;;
    esac
done
