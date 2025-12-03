#!/bin/bash

# ★重要: 音源ファイルの場所 (手順1で確認したパスを指定)
SOUND_DIR="/usr/share/sounds/Borealis/stereo"

# 再生用関数 (paplayを使用)
play_sound() {
    local file="$1"
    # ファイルが存在する場合のみ再生
    if [ -f "$SOUND_DIR/$file.oga" ]; then
        # paplay で再生 (バックグラウンド)
        paplay "$SOUND_DIR/$file.oga" &
    fi
}

# 初期値取得
prev_ws=$(hyprctl activeworkspace -j | jq '.id')

handle() {
  event_str="$1"

  case "$event_str" in
    workspace*)
      new_ws=$(echo "$event_str" | sed 's/workspace>>//' | cut -d',' -f1)

      if [[ ! "$new_ws" =~ ^[0-9]+$ ]] || [[ ! "$prev_ws" =~ ^[0-9]+$ ]]; then
          return
      fi

      if [ "$new_ws" -gt "$prev_ws" ]; then
          # 右移動: ファイル名を指定 (Borealisのファイル名に合わせて調整)
          play_sound "desktop-switch-right"
      elif [ "$new_ws" -lt "$prev_ws" ]; then
          # 左移動
          play_sound "desktop-switch-left"
      fi
      
      prev_ws=$new_ws
      ;;
      
    openwindow*)
      play_sound "window-maximized"
      ;;
      
    closewindow*)
      play_sound "window-maximized"
      ;;
  esac
}

socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done