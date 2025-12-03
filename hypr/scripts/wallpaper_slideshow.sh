#!/bin/bash

# --- 設定 ---
# 壁紙が入っているディレクトリ (自分の環境に合わせて書き換えてください)
DIR="$HOME/Pictures"
# 切り替え間隔 (秒)
INTERVAL=300

# --- 処理 ---
# swww-daemon が起動しているか確認し、なければ起動
if ! pgrep -x "swww-daemon" > /dev/null; then
    swww-daemon &
    sleep 1
fi

while true; do
    # ディレクトリ内の画像ファイルを検索し、ランダムに1つ選ぶ
    # (jpg, png, jpeg, webp に対応)
    RANDOM_IMG=$(find "$DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf -n 1)

    # 画像が見つかった場合のみ実行
    if [ -n "$RANDOM_IMG" ]; then
        # swww で壁紙を変更
        # --transition-type: アニメーションの種類 (simple, fade, left, right, top, bottom, wipe, wave, grow, center, outer, random)
        swww img "$RANDOM_IMG" --transition-type random --transition-step 90 --transition-fps 60
    fi

    # 指定時間待機
    sleep $INTERVAL
done