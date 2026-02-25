#!/bin/bash

# =========================================================
# WRT-CI 插件下载引擎 (Packages.sh) - V7.5 Refactored
# =========================================================

SCRIPTS_DIR=$(cd $(dirname $0) && pwd)
ROOT_DIR=$(cd $SCRIPTS_DIR/.. && pwd)
[ -f "${SCRIPTS_DIR}/Ui.sh" ] && source "${SCRIPTS_DIR}/Ui.sh"

UPDATE_PACKAGE() {
	local name=$1 repo=$2 branch=$3 spec=$4 confs=$5
	[ -z "$name" ] || [ -z "$repo" ] && return
	msg_info "Processing: ${name}"
	for item in $name $confs; do
		[ "$item" == "_" ] && continue
		local found=$(find ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$item*" 2>/dev/null)
		[ -n "$found" ] && rm -rf $found
	done
	local target=""
	[[ "$spec" == "name" ]] && target="$name" || target="${repo#*/}"
	target="${target%.git}"
	local url="$repo"
	[[ ! "$url" == "http"* ]] && url="https://github.com/$repo.git"
	rm -rf "$target"
	git clone --depth=1 --single-branch --branch "$branch" "$url" "$target"
	if [[ "$spec" == "pkg" ]]; then
		find ./$target/*/ -maxdepth 3 -type d -iname "*$name*" -prune -exec cp -rf {} ./ \;
		rm -rf ./$target/
	fi
}

PROCESS_FILE() {
	[ ! -f "$1" ] && return
	while read -r n r b s c || [ -n "$n" ]; do
		[[ "$n" =~ ^#.*$ || -z "$n" ]] && continue
		UPDATE_PACKAGE "$n" "$r" "$b" "$s" "$c"
	done < "$1"
}

PROCESS_FILE "${ROOT_DIR}/Config/CORE_PACKAGES.txt"
PROCESS_FILE "${ROOT_DIR}/Config/CUSTOM_PACKAGES.txt"
