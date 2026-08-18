#!/bin/bash

popup_class=cliphist_fzf

(
    coproc socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" 2>/dev/null
    trap 'kill "$COPROC_PID" 2>/dev/null' EXIT

    armed=
    [[ $(hyprctl repl '(hl.get_active_window() or {}).class or ""' 2>/dev/null) == "$popup_class" ]] && armed=1

    while IFS= read -r -u "${COPROC[0]}" line; do
        [[ $line == activewindow\>\>* ]] || continue
        if [[ $line == "activewindow>>$popup_class,"* ]]; then
            armed=1
        elif [[ $armed ]]; then
            hyprctl dispatch 'hl.dsp.window.close({ window = "class:^cliphist_fzf$" })' >/dev/null 2>&1
            break
        fi
    done
) &
focus_watcher_pid=$!
trap 'kill "$focus_watcher_pid" 2>/dev/null; wait "$focus_watcher_pid" 2>/dev/null' EXIT

delete_entries() { printf '%s\n' "$@" | cliphist delete; }

preview_entry() (
    [[ $1 ]] || return
    printf '\x1b_Ga=d,d=A\x1b\\'
    local temp_file decoded_path
    temp_file=$(mktemp) || return
    trap 'rm -f "$temp_file"' EXIT
    cliphist decode "$1" >"$temp_file"
    IFS= read -r decoded_path <"$temp_file"; decoded_path=${decoded_path%$'\r'}
    case $decoded_path in file://*) decoded_path=${decoded_path#file://};; "~/"*) decoded_path=$HOME/${decoded_path:2};; /*);; *) decoded_path=;; esac
    if [[ -f $decoded_path ]]; then head -n 100 -- "$decoded_path"
    elif [[ $(file --mime-type -b "$temp_file") == image/* ]]; then
        kitten icat --transfer-mode=memory --stdin=no --place="${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}@0x0" "$temp_file" </dev/null 2>/dev/null
    else head -n 100 -- "$temp_file"
    fi
)

export -f delete_entries preview_entry

mapfile -t selection_output < <(
    cliphist list | awk -F'\t' '
        BEGIN{reset="\033[0m";image="\033[38;2;211;134;155m";url="\033[38;2;250;189;47m";file="\033[38;2;69;133;136m"}
        NR>50{exit}{text=$2;if(text~/<img src=/||text~/\[\[ binary data /)text=image text reset;else if(text~/^file:\/\//||text~/^\//||text~/^~\//)text=file text reset;
        else gsub(/https?:\/\/[^[:space:]]+|www\.[^[:space:]]+/,url "&" reset,text);printf "%s\t%s\n",text,$1}' |
    SHELL=$BASH fzf --ansi -d'\t' --with-nth=1 --cycle --reverse --tiebreak=index \
        --color='bg:-1,bg+:-1,fg:-1,fg+:-1,gutter:238,border:7,separator:7,scrollbar:#32302f,hl:12,hl+:12,info:12,prompt:12,pointer:12,header:12,label:12,marker:#fb4934,spinner:12' \
        --pointer='▌' --marker='▌' -m --info=hidden --input-border=line \
        --bind='load,result,focus:transform-prompt:printf "(%02d/%02d)  " "$FZF_POS" "$FZF_MATCH_COUNT"' \
        --bind='space:transform:[[ -z $FZF_QUERY ]] && echo toggle+down || echo put' \
        --bind='ctrl-r:transform:(( FZF_SELECT_COUNT )) && echo "execute-silent(delete_entries \{+2})+exclude-multi"' \
        --bind='tab:ignore,shift-tab:ignore' --expect='ctrl-l' \
        --preview='preview_entry {2}' --preview-window='top:50%:wrap:border-none'
)

case ${selection_output[0]} in
    ctrl-l) cliphist wipe; wl-copy --clear; wl-copy --primary --clear ;;
    *) [[ ${selection_output[1]} ]] && cliphist decode "${selection_output[1]##*$'\t'}" | wl-copy ;;
esac
