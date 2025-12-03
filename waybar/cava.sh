#!/bin/bash

# バーの設定
bar_count=20

# 一時設定ファイルの作成
config_file="/tmp/waybar_cava_config"
echo "
[general]
framerate = 60
bars = $bar_count
[input]
method = pulse
source = auto
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
[smoothing]
gravity = 65
integral = 70
" > $config_file

# 実行部
cava -p $config_file | awk '
BEGIN {
    # --- 色設定 (Catppuccin Mocha) ---
    color[0]="#45475a"; char[0]=" ";
    color[1]="#89b4fa"; char[1]="▂";
    color[2]="#89b4fa"; char[2]="▃";
    color[3]="#a6e3a1"; char[3]="▄";
    color[4]="#a6e3a1"; char[4]="▅";
    color[5]="#f9e2af"; char[5]="▆";
    color[6]="#fab387"; char[6]="▇";
    color[7]="#f38ba8"; char[7]="█";
}
{
    out = ""
    len = split($0, arr, "")
    for (i = 1; i <= len; i++) {
        v = arr[i]
        
        # ★追加: セミコロン (;) は区切り文字なので無視する
        if (v == ";") continue
        
        # 想定外の文字が来た場合も無視する
        if (!(v in color)) continue

        out = out "<span color='\''" color[v] "'\''>" char[v] "</span>"
    }
    print out
    fflush()
}
'