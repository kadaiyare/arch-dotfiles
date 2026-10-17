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
PearとThunarもアプリ側の背景透過を使い、その他のアプリは従来の不透明度設定を維持します。
Super+Vは押した時点の画面寸法から論理ピクセルで75%を計算します。
自動起動は `hyprland.start` イベントに登録し、通常の設定リロード時には起動しません。
旧 `.conf` の設定・誤記は、移行前の状態へ戻せるよう変更していません。

## foot・Zedのすりガラス設定

footとZedはHyprland側を `1.0 override 1.0 override` にし、文字とアイコンを
不透明に保ちます。白い背景の不透明度だけをアプリ側で約32%に設定しています。
操作中／非アクティブ時で不透明度は変わりません。

`../foot/foot.ini` の両カラーテーマは `background=ffffff`、`alpha=0.32`、
`alpha-mode=matching`、`blur=yes` です。本文は公式Catppuccin Latteの `#4c4f69`、
ANSI色も公式Latteに揃えています。スクロール倍率は `multiplier=9.0` です。
テーマ切り替え時にもこの配色とalphaを維持します。
恒久的な設定の読み込みには新しいfootウィンドウを開いてください。
既存ウィンドウの背景はOSC 11の `[32]#ffffff` でも変更できます。
Nucleusのドロップダウン端末は `../foot/dropdown.ini` で元のCatppuccin配色と
alpha=1を読み込み、従来のHyprland側の不透明度0.97を維持します。

Zedは `../zed/settings.json` の `theme_overrides` でLatteとMochaの両方に
`background.appearance=transparent` を設定しています。共通背景、タイトルバー
（非アクティブ時も含む）、ステータスバーは `#ffffff52`（約32%の白）です。
エディター、ガター、パネル、タブ、`surface.background`、`panel.overlay_background` は
`#00000000` として白の重なりを避けています。
文字色・構文色も公式Catppuccin Latteに揃え、本文は `#4c4f69`、キーワードは
紫 `#8839ef`、関数は青 `#1e66f5`、文字列は緑 `#40a02b`、数値はオレンジ `#fe640b` です。

foot・Zed専用の `glass-edge-foot-zed` ルールで枠を1px・半透明の白
（`rgba(ffffff80)`）にしています。共有Catppuccinテーマの枠色より優先されます。
共通の `blur-foot-zed` ルールで `no_blur=false`、`xray=false` を明示しています。

共通ブラーは `size=4`、`passes=3`、`noise=0.008`、`vibrancy=0.10` です。
影は範囲18・色 `rgba(1a1a1a4d)`（不透明度約30%）です。
ブラーと影の変更は他のウィンドウにも適用されます。

## Super+Rのアプリランチャー

Super+RはRofi 2.0のWaylandランチャーを起動します。
テーマは `../rofi/glass-launcher.rasi` で、
`~/.config/rofi/glass-launcher.rasi` からリンクしています。
背景は白22%（`#ffffff38`）、枠は半透明の白1pxで、文字とアイコンは不透明です。
Hyprlandの `glass-app-launcher` レイヤールールでブラーを適用します。
`ignore_alpha=0.01` で透明な角を除外し、薄い背景にもブラーをかけます。

中央に720×480px・4列×3行のアイコングリッドを表示します。
アイコンは48px、名前は下部に中央揃えで表示し、左から右へ並べます。
検索欄は入力欄のみで、左側の「アプリ」ラベルは表示しません。
起動履歴を有効にし、未入力時はRofiからの起動頻度が高いアプリを先頭に表示します。
初期履歴には以前のWofiの起動回数を引き継いでいます。履歴のないアプリは名前順です。
履歴は最大50件を保持し、アプリ一覧キャッシュは無効にして並びを毎回反映します。
入力時はあいまい検索とfzf順の並べ替えに対応しています。矢印キーで選択、Enterで起動、
Escで閉じます。アプリ検索専用で、モード切り替えタブは表示しません。
端末内アプリの実行にはfootを使います。
Wofiと既存Rofi設定は保持しています。Super+Shift+Vのクリップボードは引き続きWofiです。
Super+AのNucleusランチャーも引き続き利用できます。
Super+Rを戻す場合は `hyprland.lua` の `local menu` を
`"wofi --show drun"` に戻し、`hyprctl reload` を実行してください。

## 3本指下スワイプのSpotlight風ランチャー

`~/.config/libinput-gestures.conf` の3本指下スワイプは、Rofiの
`~/.config/rofi/spotlight-launcher.rasi` を起動します。
実体は `../rofi/spotlight-launcher.rasi` で、グリッドテーマを読み込んで
表示部分のみ620×380px・1列5行のコンパクトな一覧に変更しています。
アイコンは28px、名前は16ptでアイコンの右側に表示します。
検索欄は入力欄のみで、コマンドタブは表示しません。
起動履歴・あいまい検索・すりガラスの配色はSuper+Rと共通です。
ジェスチャー設定の反映には `libinput-gestures-setup restart` を使います。

## 公式Discordの透過

公式Discord（app ID `discord`）はウィンドウ全体の不透明度を
`0.80 override 0.70 override`（操作中80%、非アクティブ時70%）にしています。
footとZedと同じブラー指定（`no_blur=false`、`xray=false`）を適用し、
共通の強度size=4、passes=3を使います。背景だけに白30%を加える設定は行わず、
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
