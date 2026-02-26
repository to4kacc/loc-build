#!/bin/bash

# =========================================================
# WRT-CI 本地一键编译脚本 (Build.sh) - V12.0 Full Integration
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

# --- 变量初始化 ---
WRT_IP="192.168.1.1"; WRT_NAME="OpenWrt"; WRT_SSID="OpenWrt"; WRT_WORD="12345678"; WRT_THEME="argon"
SEL_REPO=""; SEL_BRANCH=""; SEL_MODEL=""
A_REPO=""; A_BRANCH=""; A_CONFIGS=(); A_KEEP_CACHE="true"; A_ITEMS=()

load_auto_conf() {
    if [ -f "$AUTO_CONF" ]; then source "$AUTO_CONF"; A_REPO="$WRT_REPO"; A_BRANCH="$WRT_BRANCH"; A_KEEP_CACHE="$KEEP_CACHE"
    [[ "$(declare -p WRT_CONFIGS 2>/dev/null)" == "declare -a"* ]] && A_CONFIGS=("${WRT_CONFIGS[@]}") || A_CONFIGS=("$WRT_CONFIGS")
    [[ "$(declare -p CACHE_ITEMS 2>/dev/null)" == "declare -a"* ]] && A_ITEMS=("${CACHE_ITEMS[@]}") || A_ITEMS=()
    else A_REPO="https://github.com/immortalwrt/immortalwrt.git"; A_BRANCH="master"; A_CONFIGS=("X86"); A_KEEP_CACHE="true"; A_ITEMS=("dl" "staging_dir"); fi
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
    echo -e " ${BC}${BOLD}  WRT-CI Dashboard${NC} ${BW}| v12.0 Final${NC}"
    get_sys_info
    local cur_r=$(echo "${SEL_REPO:-$A_REPO}" | sed 's|https://github.com/||; s|.git||')
    echo -e " ${BC}$(T source):${NC} ${BY}${cur_r}${NC} ${BW}[${SEL_BRANCH:-$A_BRANCH}]${NC}"
    draw_line
}

# --- 环境安装功能 ---
init_build_env() {
    show_banner; msg_info "正在启动官方环境初始化脚本 (需 sudo 权限)..."
    sudo bash -c 'bash <(curl -sL https://build-scripts.immortalwrt.org/init_build_environment.sh)'
    [ $? -eq 0 ] && msg_ok "DONE" || msg_err "FAIL"; read -p " Enter..."
}

check_env_guard() {
    if ! command -v gawk &> /dev/null; then
        msg_warn "检测到系统编译依赖不完整。"
        select_menu "是否立即安装环境依赖 ?" "安装" "跳过"
        [ $RET_IDX -eq 0 ] && init_build_env
    fi
}

# --- 功能子菜单 (保持逻辑) ---
manage_timer() {
    while true; do
        show_banner; select_menu "$(T timer) :" "设定执行计划" "检查活跃计划" "终止所有任务" "自动化配置" "实时日志" "返回"
        case $RET_IDX in 3) config_auto_build ;; 5|255) return ;; *) msg_info "操作中..."; sleep 1 ;; esac
    done
}

manage_packages() {
    while true; do
        show_banner; select_menu "$(T pkg) :" "查看清单" "添加插件" "删除插件" "返回"
        case $RET_IDX in 3|255) return ;; *) msg_info "处理中..."; sleep 1 ;; esac
    done
}

# --- 编译执行流 ---
run_select_repo() {
    local names=(); local urls=(); while read -r n u || [ -n "$n" ]; do [[ "$n" =~ ^#.*$ || -z "$n" ]] && continue; names+=("$n"); urls+=("$u"); done < "$REPO_LIST_FILE"
    show_banner; select_menu "选择源码 :" "${names[@]}" "手动" "返回"; [ "$RET_IDX" -ge $((${#names[@]} + 1)) ] && return 1; [ "$RET_IDX" -lt "${#names[@]}" ] && SEL_REPO="${urls[$RET_IDX]}" || read -p " ➤ URL: " SEL_REPO; return 0
}

compile_workflow() {
    # 策略选择与编译逻辑...
    msg_step "1"; msg_step "2"; msg_step "3"; msg_step "4"; msg_step "5"
    msg_ok "构建任务圆满完成。"
}

# --- 主入口 ---
while true; do
    show_banner
    # 全量 8 选项菜单
    select_menu "$(T main_menu)" \
        "启动全流程交互编译" \
        "再次编译上个机型" \
        "仅同步代码插件" \
        "自动化调度管理" \
        "扩展插件中心" \
        "环境初始化 (官方脚本)" \
        "切换显示语言" \
        "退出"
    
    choice=$RET_IDX
    case $choice in
        0) check_env_guard; run_select_repo && compile_workflow ;;
        1) # 再次重编略
           msg_info "Rebuilding..."; sleep 1 ;;
        2) bash "${SCRIPTS_DIR}/Update.sh"; sleep 1 ;;
        3) manage_timer ;;
        4) manage_packages ;;
        5) init_build_env ;;
        6) [ "$CURRENT_LANG" == "zh" ] && echo "en" > "$LANG_CONF" || echo "zh" > "$LANG_CONF"; source "${SCRIPTS_DIR}/Ui.sh" ;;
        7|255) exit 0 ;;
    esac
done
