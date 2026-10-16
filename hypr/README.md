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
footとZed以外のアプリ別の透明度は従来どおり全体の透明度に乗算しています。
Super+Vは押した時点の画面寸法から論理ピクセルで75%を計算します。
自動起動は `hyprland.start` イベントに登録し、通常の設定リロード時には起動しません。
旧 `.conf` の設定・誤記は、移行前の状態へ戻せるよう変更していません。

## footの背景透過の実験

通常のfoot（app ID `foot`）は視認性の実験として、Hyprland側で `0.90 override 0.80 override`、
`~/.config/foot/foot.ini` の両カラーテーマで `background=ffffff`、`alpha=0.2666667`、
`alpha-mode=matching` を指定しています。合成後の白は操作中約24%、非アクティブ時約21.3%で、
従来の24%／21%とほぼ同じです。文字の不透明度は操作中90%、非アクティブ時80%に上げています。
本文色は `#202532` にし、ANSI色も白いガラス向けの濃い配色を両テーマに設定しています。
フォントと共通ブラー（size=3、passes=3）はそのままです。
テーマ切り替え時にもこの配色とalphaを維持します。
Hyprland 0.56の背景効果プロトコルに対応するため、footの両カラーテーマで
`blur=yes` を指定しています。これは新しく起動したfootから反映されます。
footとZedには共通の `blur-foot-zed` ルールで `no_blur=false`、`xray=false` を明示しています。

foot設定の恒久的な反映には新しいウィンドウを開いてください。
Nucleusのドロップダウン端末は `~/.config/foot/dropdown.ini` で元のCatppuccin配色とalpha=1を読み込み、
従来のHyprland側の不透明度0.97を維持します。

## Zedの背景透過

Zedは視認性の調整としてHyprland側を `0.90 override 0.80 override` とし、アプリ側でも背景を透過します。
`~/.config/zed/settings.json` の `theme_overrides` にLatteとMochaの両方を設定し、
`background.appearance` は `transparent` です。共通背景 `background`、
タイトルバー（非アクティブ時も含む）、ステータスバーは `#ffffff44` とし、
約27%の薄い白を加えています。エディター、ガター、パネル、タブ、
`surface.background`、`panel.overlay_background` は `#00000000` とし、
白が重ならず、本文とヘッダー／フッターの透け方が揃うようにしています。
基本の文字とアイコン色を `#202532`、補助色を `#414857`／`#707887` にして、
ライト／ダークテーマの両方で読みやすくしています。シンタックスハイライトの色はテーマのままです。

文字にはHyprland側の不透明度（操作中90%、非アクティブ時80%）がかかります。
共通のブラーはsize=3、passes=3です。sizeを4から3に弱めた変更は他のウィンドウにも適用されます。

## 公式Discordの透過

公式Discord（app ID `discord`）はウィンドウ全体の不透明度を
`0.80 override 0.70 override`（操作中80%、非アクティブ時70%）にしています。
footとZedと同じブラー指定（`no_blur=false`、`xray=false`）を適用し、
共通の強度size=3、passes=3を使います。背景だけに白30%を加える設定は行わず、
Discord自体の配色とVesktopの設定は変更していません。

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

## ワークスペース別の背景

Super+WでNucleus Shellの背景選択画面を開きます。選んだ画像は現在のワークスペースに保存されます。
壁紙はNucleus Shellが表示し、旧 `scripts/wallpaper_slideshow.sh` の自動起動は解除しています。
操作と保存先は `~/.config/quickshell/nucleus-shell/WORKSPACE-WALLPAPERS.md` を参照してください。

## Mocha／Latteの切り替え

バーの月／太陽アイコンで、対応アプリのテーマをまとめて切り替えます。
`catppuccin-theme` コマンドも利用できます。対象と初回設定は `../theme-switch/README.md` を参照してください。
`catppuccin-theme.lua` は選択中の枠の色を保持する小さな設定で、共通スクリプトが更新します。
