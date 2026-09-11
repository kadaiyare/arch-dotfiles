# Hyprland設定

通常の編集先は `hyprland.lua`。Hyprland **0.56.2** で検証したLua設定です。
`hyprland.conf` は移行前の状態を保った復旧用で、Lua設定からは読み込みません。
`hypridle.conf` と `hyprlock.conf` は従来形式のまま使います。

## 適用

この環境では `~/.config/hypr` が `/home/taka/arch-dotfiles/hypr` への
シンボリックリンクです。追加のコピーやリンク作成は不要です。

作業を保存してログアウトし、Hyprlandへログインし直してください。
通常起動時は `hyprland.lua` が旧 `.conf` より優先されます。
起動コマンドで `--config` / `-c` を指定している場合は、その参照先もLuaへ変更してください。
設定形式の切り替えは、通常の `hyprctl reload` だけで済ませずセッションを再起動します。
移行作業ではログアウト・実行中セッションのリロードは行っていません。

## 検証

リポジトリのルートで実行します。

```sh
luac -p hypr/hyprland.lua
Hyprland --verify-config -c "$PWD/hypr/hyprland.lua"
```

2026-09-11、Hyprland `0.56.2-2` で両方を実行し、`config ok` を確認しました。
旧 `.conf` も同じHyprlandの検証を通過しています。

追加で、実際の画面操作・アプリ起動を抑止した検証用Luaからコールバックを呼び出し、
Super+Vの実行順、画面サイズの75%計算（通常・HiDPI・回転）、
アクティブウィンドウ／モニターがない場合、自動起動の登録内容を確認しました。
これらは実機の描画や入力操作の検証を代替するものではありません。

再ログイン後はターミナルから `hyprctl configerrors` を確認し、次を試してください。

- 内蔵画面60Hz・HDMI画面120Hzと左右配置（`hyprctl monitors`）。
- 日本語入力、3本指横スワイプ、タッチパッドのタップ。
- Super+数字／Super+Shift+数字、スクラッチパッド、マウスによる移動・リサイズ。
- Super+Vのフロート切り替え・75%リサイズ・中央配置、長押しによるリサイズ。
- 音量・輝度・メディアキー、Print／Shift+Print、クリップボード履歴。
- アプリ別透明度、通知・Wofiのぼかし、壁紙・効果音・Quickshellの起動。

## 移行時に修正した点

- `QR_IM_MODULE` の誤記を `QT_IM_MODULE` に修正。
- `dbus-update-activation-environment --systed` を `--systemd` に修正。
- Fcitx5の二重起動指定を `fcitx5 -d` に統一。
- 重複するSuper+左クリックの移動バインドを1件に整理。
- Shift+Printの `date + '…'` を `date +'…'` に修正し、保存先を引用符で囲む。
  保存名の `Screenshot=` プレフィックスは維持。

既存のモニター・見た目・アニメーション・入力・ルールの値を引き継いでいます。
アプリ別の透明度は従来どおり全体の透明度に乗算し、`override` は追加していません。
Super+Vは押した時点の画面寸法から論理ピクセルで75%を計算します。
自動起動は `hyprland.start` イベントに登録し、通常の設定リロード時には起動しません。
旧 `.conf` の設定・誤記は、移行前の状態へ戻せるよう変更していません。

## 旧設定へ戻す

この手順は **旧Hyprlang形式をサポートするHyprland 0.56.2での復旧用**です。
将来、旧形式のサポートが削除されたバージョンでは使えません。

端末、またはGUIに入れない場合はCtrl+Alt+F3などでTTYへ入り、次を実行します。

```sh
cd /home/taka/arch-dotfiles
mv -i hypr/hyprland.lua hypr/hyprland.lua.disabled
```

その後Hyprlandへログインし直すと、通常起動では残してある `hyprland.conf` を読み込みます。
`-c` でLuaを指定して起動している場合は、その指定を外すか `.conf` へ戻してください。
Luaへ再度切り替える場合はファイル名を戻して再ログインします。

```sh
mv -i hypr/hyprland.lua.disabled hypr/hyprland.lua
```

## 参照

- [公式のLua移行告知](https://hypr.land/news/26_lua/)
- [0.56.2の公式サンプル](https://github.com/hyprwm/Hyprland/blob/v0.56.2/example/hyprland.lua)
- [0.56のディスパッチャー仕様](https://wiki.hypr.land/0.56.0/Configuring/Basics/Dispatchers/)
- [0.56のウィンドウルール](https://wiki.hypr.land/0.56.0/Configuring/Basics/Window-Rules/)
- ローカルの公式サンプル: `/usr/share/hypr/hyprland.lua`
- エディター補完用の型定義: `/usr/share/hypr/stubs/`
