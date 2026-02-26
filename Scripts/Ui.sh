#!/bin/bash

# =========================================================
# WRT-CI 统一视觉引擎 (Ui.sh) - V8.0 Full-ZH/EN
# =========================================================

# --- 色彩定义 ---
R='\033[0;31m';  BR='\033[1;31m'
G='\033[0;32m';  BG='\033[1;32m'
Y='\033[0;33m';  BY='\033[1;33m'
B='\033[0;34m';  BB='\033[1;34m'
P='\033[0;35m';  BP='\033[1;35m'
C='\033[0;36m';  BC='\033[1;36m'
W='\033[0;37m';  BW='\033[1;37m'
NC='\033[0m';    BOLD='\033[1m'

LANG_CONF="${HOME}/.wrt_ci_lang"
[ -f "$LANG_CONF" ] && CURRENT_LANG=$(cat "$LANG_CONF") || CURRENT_LANG="zh"

RET_IDX=0
RET_VAL=""

T() {
    local key=$1
    case "$CURRENT_LANG" in
        "en")
            case "$key" in
                "main_menu") echo "Main Dashboard :" ;;
                "build") echo "Launch Interactive Build" ;;
                "rebuild") echo "Rebuild Last Session" ;;
                "sync") echo "Sync Assets & Feeds" ;;
                "timer") echo "Timer & Automation" ;;
                "pkg") echo "Package Management" ;;
                "self") echo "Update Framework Script" ;;
                "env") echo "Initialize Build Env" ;;
                "lang") echo "Language (中文)" ;;
                "exit") echo "Exit Console" ;;
                "source") echo "Source Repo" ;;
                "branch") echo "Build Branch" ;;
                "model") echo "Target Model" ;;
                "strategy") echo "Build Strategy" ;;
                "fast") echo "Incremental (Fast)" ;;
                "stable") echo "Standard (Stable)" ;;
                "clean") echo "Full Clean (Deep)" ;;
                "back") echo "Back" ;;
                "cancel") echo "Cancel" ;;
                "manual") echo "Manual Input" ;;
                "info") echo "INFO" ;;
                "done") echo "DONE" ;;
                "fail") echo "FAIL" ;;
                "warn") echo "WARN" ;;
                "load") echo "LOAD" ;;
                "mem") echo "MEM" ;;
                "disk") echo "DISK" ;;
                "step1") echo "Source Sync" ;;
                "step2") echo "Feeds Update" ;;
                "step3") echo "Package Sync" ;;
                "step4") echo "Config Injection" ;;
                "step5") echo "Core Building" ;;
                "step6") echo "Smart Archive" ;;
                "dl_msg") echo "Downloading dependencies..." ;;
                "build_msg") echo "Core engine is building..." ;;
                "hour") echo "Hour (0-23)" ;;
                "min") echo "Min (0-59)" ;;
                "press_enter") echo "Press Enter to continue..." ;;
                "no_history") echo "No previous build record found." ;;
                "set_sched") echo "Setup Cron Schedule" ;;
                "check_task") echo "Check Active Tasks" ;;
                "term_sched") echo "Terminate Schedule" ;;
                "config_pipe") echo "Config Pipeline" ;;
                "view_logs") echo "View Build Logs" ;;
                "view_list") echo "View Package List" ;;
                "add_pkg") echo "Add Custom Package" ;;
                "del_pkg") echo "Delete Package" ;;
                "edit_file") echo "Manual Edit Config" ;;
                "ver_update") echo "Update Pkg Versions" ;;
                "mod_source") echo "Modify Remote Source" ;;
                "mod_branch") echo "Modify Target Branch" ;;
                "manage_model") echo "Manage Build List" ;;
                "config_cache") echo "Cache Retention Policy" ;;
                "save_exit") echo "Save and Return" ;;
                "discard") echo "Discard and Back" ;;
                *) echo "$key" ;;
            esac ;;
        *) # 全量汉化
            case "$key" in
                "main_menu") echo "主菜单控制台 :" ;;
                "build") echo "启动全流程交互编译" ;;
                "rebuild") echo "再次编译上个机型" ;;
                "sync") echo "仅同步代码与插件" ;;
                "timer") echo "自动化调度管理" ;;
                "pkg") echo "扩展插件中心" ;;
                "self") echo "检查系统脚本更新" ;;
                "env") echo "初始化编译环境" ;;
                "lang") echo "切换显示语言 (English)" ;;
                "exit") echo "结束当前会话" ;;
                "source") echo "源码仓库" ;;
                "branch") echo "目标分支" ;;
                "model") echo "目标机型" ;;
                "strategy") echo "选择编译策略" ;;
                "fast") echo "增量快编" ;;
                "stable") echo "标准更新" ;;
                "clean") echo "深度清理" ;;
                "back") echo "返回" ;;
                "cancel") echo "取消并返回" ;;
                "manual") echo "手动输入" ;;
                "info") echo "信息" ;;
                "done") echo "完成" ;;
                "fail") echo "失败" ;;
                "warn") echo "警告" ;;
                "load") echo "负载" ;;
                "mem") echo "内存" ;;
                "disk") echo "磁盘" ;;
                "step1") echo "源码环境同步" ;;
                "step2") echo "更新插件源 (Feeds)" ;;
                "step3") echo "载入自定义补丁与包" ;;
                "step4") echo "生成固件编译配置" ;;
                "step5") echo "启动核心编译引擎" ;;
                "step6") echo "固件智能归档提取" ;;
                "dl_msg") echo "正在下载软件包依赖..." ;;
                "build_msg") echo "核心引擎正在全力运转..." ;;
                "hour") echo "时 (0-23)" ;;
                "min") echo "分 (0-59)" ;;
                "press_enter") echo "按回车键继续..." ;;
                "no_history") echo "未发现历史编译记录。" ;;
                "set_sched") echo "设定周期执行计划" ;;
                "check_task") echo "检查当前活跃计划" ;;
                "term_sched") echo "终止所有计划任务" ;;
                "config_pipe") echo "配置自动化流水线" ;;
                "view_logs") echo "查看实时进程日志" ;;
                "view_list") echo "查看完整插件清单" ;;
                "add_pkg") echo "交互添加自定义插件" ;;
                "del_pkg") echo "删除已有自定义插件" ;;
                "edit_file") echo "手动编辑配置文件" ;;
                "ver_update") echo "检查并更新软件包版本" ;;
                "mod_source") echo "修改远程仓库地址" ;;
                "mod_branch") echo "修改目标编译分支" ;;
                "manage_model") echo "管理待编译机型列表" ;;
                "config_cache") echo "配置缓存保留策略" ;;
                "save_exit") echo "保存配置并返回" ;;
                "discard") echo "放弃修改并返回" ;;
                *) echo "$key" ;;
            esac ;;
    esac
}

# --- 视觉组件 ---
msg_info() { echo -e " ${BC}[$(T info)]${NC} ${BW}$1${NC}"; }
msg_ok()   { echo -e " ${BG}[$(T done)]${NC} ${BW}$1${NC}"; }
msg_warn() { echo -e " ${BY}[$(T warn)]${NC} ${BW}$1${NC}"; }
msg_err()  { echo -e " ${BR}[$(T fail)]${NC} ${BW}$1${NC}"; }
draw_line() { echo -e " ${BW}-----------------------------------------------------${NC}"; }
msg_step() { local k="step$1"; echo -e "\n ${BP}--- STEP $1 : $(T $k) ---${NC}"; }

get_sys_info() { 
    local l=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)
    local t=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local f=$(grep MemFree /proc/meminfo | awk '{print $2}')
    local b=$(grep ^Buffers /proc/meminfo | awk '{print $2}')
    local c=$(grep ^Cached /proc/meminfo | awk '{print $2}')
    local mem_pct=$(((t-f-b-c)*100/t))
    local disk=$(df -h / | awk '/\// {print $(NF-1)}' | head -n 1)
    echo -e " ${BC}$(T load): ${BY}$l ${BC}$(T mem): ${BY}$mem_pct% ${BC}$(T disk): ${BY}$disk${NC}"
}

select_menu() { 
    local title=$1; shift; local options=("$@"); local selected=0; local key=""
    RET_IDX=0; tput civis >&2
    while true; do 
        echo -e "  ${BOLD}${title}${NC}" >&2
        for i in "${!options[@]}"; do 
            [ $i -eq $selected ] && echo -e "  ${BC}>> ${BOLD}${options[$i]}${NC}" >&2 || echo -e "     ${W}${options[$i]}${NC}" >&2
        done
        IFS= read -rsn1 key
        if [[ $key == $'\e' ]]; then 
            read -rsn2 -t 0.1 n; [[ $n == "[A" ]] && ((selected--)); [[ $n == "[B" ]] && ((selected++))
            [ $selected -lt 0 ] && selected=$((${#options[@]} - 1)); [ $selected -ge ${#options[@]} ] && selected=0
        elif [[ $key =~ [1-9] ]] && [ "$key" -le "${#options[@]}" ]; then selected=$((key - 1)); break
        elif [[ $key == "q" ]]; then selected=255; break
        elif [[ $key == "" ]]; then break; fi
        tput cuu $((${#options[@]} + 1)) >&2; tput ed >&2
    done
    tput cuu $((${#options[@]} + 1)) >&2; tput ed >&2; tput cnorm >&2; RET_IDX=$selected
}

multi_select_menu() { 
    local title=$1; shift; local options=("$@"); local selected=0; local active=(); for i in "${!options[@]}"; do active[$i]=0; done
    RET_VAL=""; tput civis >&2
    while true; do 
        echo -ne "  ${BOLD}${title}${NC} " >&2; [ "$CURRENT_LANG" == "en" ] && echo -e "${W}(Space:Toggle, Enter:Confirm, q:Back)${NC}" >&2 || echo -e "${W}(空格:勾选, Enter:确定, q:返回)${NC}" >&2
        for i in "${!options[@]}"; do 
            local m="[ ]"; [ "${active[$i]}" -eq 1 ] && m="[${BG}X${NC}]"
            [ $i -eq $selected ] && echo -e "  ${BC}>> $m ${BOLD}${options[$i]}${NC}" >&2 || echo -e "     $m ${W}${options[$i]}${NC}" >&2
        done
        IFS= read -rsn1 key
        case "$key" in 
            $'\e') read -rsn2 -t 0.1 n; [[ $n == "[A" ]] && ((selected--)); [[ $n == "[B" ]] && ((selected++)); [ $selected -lt 0 ] && selected=$((${#options[@]} - 1)); [ $selected -ge ${#options[@]} ] && selected=0 ;;
            " ") [ "${active[$selected]}" -eq 1 ] && active[$selected]=0 || active[$selected]=1 ;;
            "q") RET_VAL="BACK"; tput cuu $((${#options[@]} + 1)) >&2; tput ed >&2; tput cnorm >&2; return ;;
            "") break ;;
        esac
        tput cuu $((${#options[@]} + 1)) >&2; tput ed >&2
    done
    tput cuu $((${#options[@]} + 1)) >&2; tput ed >&2; tput cnorm >&2; local res=""
    for i in "${!active[@]}"; do [ "${active[$i]}" -eq 1 ] && res+="$i "; done; RET_VAL="$res"
}
