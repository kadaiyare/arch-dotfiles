# Arch desktop dotfiles

Hyprland・Nucleus Shellと、白いすりガラス＋Catppuccin Latteの設定です。
2026-10-18時点の利用中の設定を保存しています。

## 配置先

| リポジトリ内 | 配置先 |
| --- | --- |
| `.zshrc` | `~/.zshrc` |
| `hypr/` | `~/.config/hypr/`（この環境ではリンク済み） |
| `foot/` | `~/.config/foot/` |
| `zed/settings.json` | `~/.config/zed/settings.json` |
| `starship.toml` | `~/.config/starship.toml` |
| `starship/context.py` | `~/.config/starship/context.py` |
| `rofi/` | `~/.config/rofi/` |
| `gtk-3.0/` | `~/.config/gtk-3.0/` |
| `libinput-gestures.conf` | `~/.config/libinput-gestures.conf` |
| `pear/themes/` | `~/.config/YouTube Music/themes/` |
| `quickshell/nucleus-shell/` | `~/.config/quickshell/nucleus-shell/` に上書きする変更部分 |

リンクしていない項目は現在の設定のコピーです。再保存するときは対応するファイルをコピーします。
`/home/taka` の指定があるファイルは、別のユーザー環境ではパスを変更してください。
既存ファイルは配置前にバックアップしてください。

## 外観

- foot・Zed・Pear: 白32%の背景と、公式Catppuccin Latteの文字色。
- foot: フォントサイズ20、マウススクロール倍率9.0。ドロップダウン端末は従来の配色を維持。
- Starship: Latte Powerline。フォルダー・プロジェクト・言語の記号、Git差分、実行時間、ジョブ・終了状態を表示。Git操作状態は非表示。
- Rofi: Super+Rはアイコングリッド、3本指下スワイプはSpotlight風の一覧。検索欄のラベルやモードタブは非表示、起動履歴順を使用。
- Thunar: GTKの背景だけを透過し、文字とアイコンは不透明。白32%を基調にファイル一覧を少し白くし、選択色はラベンダー。
- Nucleus: 上部バーと左右パネルを白60%のすりガラスに。左パネルのタブはOverview・Codex・背景。

GTKテーマは `catppuccin-latte-lavender-standard+default`、アイコンは `Papirus-Light` を使用しています。
ZedにはCatppuccin拡張、端末にはNerd Font対応フォント、プロンプトにはStarshipが必要です。

## PearとNucleusの設定断片

`pear/config.fragment.json` は `~/.config/YouTube Music/config.json` に、
`nucleus-shell/style.fragment.json` は `~/.config/nucleus-shell/config/configuration.json` に
**オブジェクトのキー単位でマージ**します。設定ファイル全体を置き換えるものではありません。
Pearのテーマは再起動時に読み込まれます。

NucleusのQMLは、利用中のdesktop-tools版（BuildInfoのupstreamCommitは
`8d214d5292df863da42a9e4a5f28a9e355f3379d`）への変更部分です。
単独では起動できません。既存のNucleusインストールに対応するファイルを配置してください。
認証情報・起動履歴・キャッシュ・アプリのセッションデータは保存していません。

Hyprlandの詳細は [hypr/README.md](hypr/README.md)、明暗切り替えは
[theme-switch/README.md](theme-switch/README.md) を参照してください。
