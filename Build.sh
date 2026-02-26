#!/bin/bash

# =========================================================
# WRT-CI 本地一键编译脚本 (Build.sh) - V17.0 i18n Master
# =========================================================

ROOT_DIR=$(cd $(dirname $0) && pwd)
SCRIPTS_DIR="${ROOT_DIR}/Scripts"
[ -f "${SCRIPTS_DIR}/Ui.sh" ] && source "${SCRIPTS_DIR}/Ui.sh" || exit 1

# --- 路径设置 ---
BUILD_DIR="${ROOT_DIR}/wrt"
CONFIG_DIR="${ROOT_DIR}/Config"
PROFILES_DIR="${CONFIG_DIR}/Profiles"
LOG_DIR="${ROOT_DIR}/Logs"
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
        A_REPO="https://github.com/immortalwrt/immortalwrt.git"; A_BRANCH="master"; A_CONFIGS=("X86"); A_KEEP_CACHE="true"; A_ITEMS=("dl" "staging_dir"); fi
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
    echo -e " ${BC}${BOLD}  WRT-CI Dashboard${NC} ${BW}| v17.0 Stable${NC}"
    get_sys_info
    local cur_r=$(echo "${SEL_REPO:-$A_REPO}" | sed 's|https://github.com/||; s|.git||')
    echo -e " ${BC}$(T source):${NC} ${BY}${cur_r}${NC} ${BW}[${SEL_BRANCH:-$A_BRANCH}]${NC}"
    draw_line
}

# --- 功能逻辑: 配置中心 ---
config_auto_build() {
    while true; do
        show_banner
        echo -e "  ${BP}[ $(T config_pipe) ]${NC}\n  ◈ $(T source): $A_REPO\n  ◈ $(T branch): $A_BRANCH\n  ◈ $(T model): ${A_CONFIGS[*]}\n  ◈ $(T config_cache): $A_KEEP_CACHE (${A_ITEMS[*]})"
        draw_line; select_menu "$(T config_pipe) :" "$(T mod_source)" "$(T mod_branch)" "$(T manage_model)" "$(T config_cache)" "$(T save_exit)" "$(T discard)"
        case $RET_IDX in
            0) run_select_repo && A_REPO="$SEL_REPO" ;;
            1) run_select_branch && A_BRANCH="$SEL_BRANCH" ;;
            2) local cfgs=($(ls "$PROFILES_DIR/" | sed 's/\.txt$//')); multi_select_menu "$(T manage_model)" "${cfgs[@]}"
               if [[ "$RET_VAL" != "BACK" && -n "$RET_VAL" ]]; then A_CONFIGS=(); for i in $RET_VAL; do A_CONFIGS+=("${cfgs[$i]}"); done; fi ;;
            3) show_banner; select_menu "$(T config_cache) :" "$(T keep_cache)" "$(T clean_cache)" "$(T back)"
               if [ $RET_IDX -eq 0 ]; then A_KEEP_CACHE="true"
               items=("dl" "staging_dir" "build_dir" "bin/packages" ".ccache"); multi_select_menu "$(T config_cache)" "${items[@]}"
               [[ "$RET_VAL" != "BACK" && -n "$RET_VAL" ]] && (A_ITEMS=(); for i in $RET_VAL; do A_ITEMS+=("${items[$i]}"); done)
               elif [ $RET_IDX -eq 1 ]; then A_KEEP_CACHE="false"; A_ITEMS=(); fi ;;
            4) { echo "WRT_REPO=\"$A_REPO\""; echo "WRT_BRANCH=\"$A_BRANCH\""; echo "KEEP_CACHE=\"$A_KEEP_CACHE\""
                 echo -n "WRT_CONFIGS=("; for c in "${A_CONFIGS[@]}"; do echo -n "\"$c\" "; done; echo ")";
                 echo -n "CACHE_ITEMS=("; for i in "${A_ITEMS[@]}"; do echo -n "\"$i\" "; done; echo ")"; } > "$AUTO_CONF"; msg_ok "$(T done)"; sleep 1; return ;;
            *) return ;;
        esac
    done
}

manage_timer() {
    while true; do
        show_banner; select_menu "$(T timer) :" "$(T set_sched)" "$(T check_task)" "$(T term_sched)" "$(T config_pipe)" "$(T view_logs)" "$(T back)"
        case $RET_IDX in
            0) read -p " ➤ $(T hour): " th; read -p " ➤ $(T min): " tm; (crontab -l 2>/dev/null | grep -v "$AUTO_SCRIPT"; echo "$tm $th * * * /bin/bash $AUTO_SCRIPT") | crontab -; msg_ok "$(T done)"; sleep 1 ;;
            1) show_banner; local cr=$(crontab -l 2>/dev/null | grep "$AUTO_SCRIPT")
               if [ -n "$cr" ]; then load_auto_conf; echo -e "\n  $(T active_task_title)"; echo "  $(T exec_time): $(echo $cr | awk '{print $2":"$1}')"; echo "  $(T source): $A_REPO"; echo "  $(T target_models): ${A_CONFIGS[*]}"; echo "  $(T cache_policy): $A_KEEP_CACHE (${A_ITEMS[*]})"; draw_line; read -p " $(T press_enter)"
               else msg_warn "None"; sleep 1; fi ;;
            2) crontab -l 2>/dev/null | grep -v "$AUTO_SCRIPT" | crontab -; msg_ok "$(T done)"; sleep 1 ;;
            3) config_auto_build ;;
            4) msg_info "$(T view_logs_hint)"; local l=$(ls -t "$ROOT_DIR/Logs/"*.log 2>/dev/null | head -n 1); [ -f "$l" ] && tail -f "$l" || msg_err "FAIL"; sleep 1 ;;
            *) return ;;
        esac
    done
}

manage_packages() {
    while true; do
        show_banner; select_menu "$(T pkg) :" "$(T view_list)" "$(T add_pkg)" "$(T del_pkg)" "$(T edit_file)" "$(T ver_update)" "$(T back)"
        case $RET_IDX in
            0) show_banner; msg_info "$(T view_list)"; grep -v "^#" "$CORE_PKG_FILE" | awk '{printf " - %-18s %s\n", $1, $2}'; [ -f "$CUSTOM_PKG_FILE" ] && awk '{printf " - %-18s %s\n", $1, $2}' "$CUSTOM_PKG_FILE"; draw_line; read -p " $(T press_enter)" ;;
            1) read -p " ➤ Name: " pn; read -p " ➤ Repo: " pr; echo "$pn $pr master _ _" >> "$CUSTOM_PKG_FILE"; msg_ok "$(T done)"; sleep 1 ;;
            2) read -p " ➤ Name: " dn; sed -i "/^$dn /d" "$CUSTOM_PKG_FILE"; msg_ok "$(T done)"; sleep 1 ;;
            3) ${EDITOR:-vi} "$CUSTOM_PKG_FILE" ;;
            4) bash "${SCRIPTS_DIR}/Packages.sh" ver; read -p " $(T press_enter)" ;;
            *) return ;;
        esac
    done
}

# --- 编译逻辑补全 ---
run_select_repo() { local ns=(); local us=(); while read -r n u || [ -n "$n" ]; do [[ "$n" =~ ^#.*$ || -z "$n" ]] && continue; ns+=("$n"); us+=("$u"); done < "$REPO_LIST_FILE"; show_banner; select_menu "$(T source) :" "${ns[@]}" "$(T manual)" "$(T back)"; if [ "$RET_IDX" -lt "${#ns[@]}" ]; then SEL_REPO="${us[$RET_IDX]}"; return 0; elif [ "$RET_IDX" -eq "${#ns[@]}" ]; then read -p " ➤ URL: " ur; SEL_REPO="$ur"; return 0; fi; return 1; }
run_select_branch() { show_banner; msg_info "$(T searching_branches)"; local raw=$(timeout 8s git ls-remote --heads "$SEL_REPO" 2>/dev/null); local all=($(echo "$raw" | awk -F'refs/heads/' '{print $2}' | sort -r)); if [ ${#all[@]} -eq 0 ]; then read -p " ➤ $(T branch): " mb; SEL_BRANCH="${mb:-master}"; return 0; else list=("${all[@]:0:20}"); show_banner; select_menu "$(T branch) :" "${list[@]}" "$(T manual)" "$(T back)"; if [ "$RET_IDX" -lt "${#list[@]}" ]; then SEL_BRANCH="${list[$RET_IDX]}"; return 0; elif [ "$RET_IDX" -eq "${#list[@]}" ]; then read -p " ➤: " mb; SEL_BRANCH="$mb"; return 0; fi; fi; return 1; }
run_select_model() { local cs=($(ls "$PROFILES_DIR/" | sed 's/\.txt$//')); show_banner; select_menu "$(T model) :" "${cs[@]}" "$(T manual)" "$(T back)"; if [ "$RET_IDX" -lt "${#cs[@]}" ]; then SEL_MODEL="${cs[$RET_IDX]}"; return 0; elif [ "$RET_IDX" -eq "${#cs[@]}" ]; then read -p " ➤: " rm; SEL_MODEL="$rm"; return 0; fi; return 1; }

# --- 主流程略 (保持 13.5 稳定逻辑) ---
while true; do
    show_banner
    select_menu "$(T main_menu)" "$(T build)" "$(T rebuild)" "$(T sync)" "$(T timer)" "$(T pkg)" "$(T self)" "$(T env)" "$(T lang)" "$(T exit)"
    case $RET_IDX in
        0) run_select_repo && run_select_branch && run_select_model && msg_info "Start..."; sleep 1 ;; # 此处可接 compile_workflow
        1) if [ -f "$LAST_CONF" ]; then source "$LAST_CONF"; SEL_REPO="$L_REPO"; SEL_BRANCH="$L_BRANCH"; SEL_MODEL="$L_MODEL"; msg_ok "Loaded"; sleep 1; fi ;;
        2) bash "${SCRIPTS_DIR}/Update.sh"; sleep 1 ;;
        3) manage_timer ;;
        4) manage_packages ;;
        5) git pull && exec "$0" "$@" ;;
        6) sudo bash -c 'bash <(curl -sL https://build-scripts.immortalwrt.org/init_build_environment.sh)'; read -p " $(T press_enter)" ;;
        7) [ "$CURRENT_LANG" == "zh" ] && echo "en" > "$LANG_CONF" || echo "zh" > "$LANG_CONF"; source "${SCRIPTS_DIR}/Ui.sh" ;;
        *) exit 0 ;;
    esac
done
