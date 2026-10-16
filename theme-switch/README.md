# Mocha／Latteの一括切り替え

バーの月／太陽アイコンをクリックすると、対応するアプリをまとめて切り替えます。
Nucleus Settings → Appearanceの明暗ボタンも同じ処理を使います。
現在の選択を保存し、新しく起動するアプリにも適用します。

```sh
catppuccin-theme          # 切り替え
catppuccin-theme light    # Catppuccin Latte
catppuccin-theme dark     # Catppuccin Mocha
catppuccin-theme status
catppuccin-theme light --dry-run
```

## 対応範囲

- Nucleus Shell、バー、サイドバー、ロック画面: Catppuccinの固定パレット。壁紙による色の自動生成は無効にします。
- GTK2／GTK3: 公式GTKテーマのMocha／Latte LavenderとPapirusの明暗アイコン。
- GTK4／libadwaita: 公式パレットを使ったCSS変数を、システムの明暗設定に連動して切り替えます。
- Qt5ct／Qt6ct、Dolphinなど: Fusionスタイルと公式Catppuccin配色。Qt6ctでの起動中の変更も検証済みです。
- Foot、Kitty、Konsole: 両方の配色を保存し、起動中の端末もシグナル・OSCで更新します。シェルは再起動しません。
- VS Code、Zed: Catppuccin Mocha／Latte。Zedのアイコンも対応します。
- Wofi、Rofi、Waybar、SwayNC、Hyprlandの枠: 同じパレットに合わせます。通知サーバーがNucleusの場合、SwayNCの起動は行いません。
- Firefox: システム追従設定とMocha／LatteのChrome／内部ページCSSを用意します。
- システム追従に対応するブラウザー・アプリ・Webサイトには、デスクトップポータル経由で明暗の希望を伝えます。

## 初回の注意

Firefoxは設定を起動時に読み込むため、初回だけ再起動してください。
以前の固定CSSを読み込んだままのGTKアプリも、初回だけ再起動が必要な場合があります。
それ以降は、テーマ切り替えのたびに再起動する必要はありません。

独自のテーマを固定しているアプリやWebサイトは、その設定が優先されます。
Discordなどの設定に「OSと同期」「システムに従う」がある場合は、有効にすると共通の明暗設定に追従します。
アプリ固有の外観設定・拡張機能・Flatpakのサンドボックスによる制約を無条件に上書きするものではありません。

## 保存とバックアップ

フォント、ウィンドウ設定、壁紙の指定、エディターのその他の設定は保持します。
footでalphaが1未満の配色を指定している場合、文字色・ANSI色・背景色・alphaを保持し、
実行中の通常のfootにも反映します。ドロップダウン端末は元の配色を使います。
エディターのJSONCは対象キーだけを変更し、コメントを保持します。
既存のGTK3の固定色インポートとcolorreloadモジュールは、システム追従を妨げるため解除します。
GTK4の旧CSSリンクはリンク自体を置き換え、`/usr/share/themes`の元ファイルは変更しません。

切り替え状態は `$XDG_STATE_HOME/catppuccin-theme/current.json`、元の設定は同じディレクトリの
`original-backup` に保存します。`files.json`が元のファイル／リンクとの対応表です。
バーから切り替える場合は、Nucleus自身に設定を書き戻させて、外部スクリプトとの書き込み競合を避けます。

## 構成と検証

`theme_switch.py`と`assets`が実装です。`~/.local/bin/catppuccin-theme`がこのスクリプトを呼び出します。
配色リソースは `~/.local/share/catppuccin-switch` にコピーしています。
GTKのLatte Lavenderテーマはユーザー用 `~/.local/share/themes` にインストールしています。
GTK Mochaは既存のシステムテーマを使います。どちらもv1.0.3の配色を使用します。

```sh
python3 -m unittest discover -s theme-switch -v
foot --check-config
```

GTK3・GTK4・Qtの検証ウィンドウを起動したまま、月／太陽ボタンと同じIPCで
Mocha → Latte → Mochaを実行し、再起動せず配色が変わることを確認しています。

## 出典

素材の出典とハッシュは `assets/SOURCES.json`、ライセンスは `assets/*-LICENSE` に保存しています。

- [Catppuccin palette](https://github.com/catppuccin/palette)
- [GTKテーマ v1.0.3](https://github.com/catppuccin/gtk/releases/tag/v1.0.3)
- [Qt5ct／Qt6ct配色](https://github.com/catppuccin/qt5ct)
- [KDE配色](https://github.com/catppuccin/kde)
- [GTK4のメディアクエリー](https://docs.gtk.org/gtk4/css-properties.html#media-queries)
- [libadwaitaのCSS変数](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1.10/css-variables.html)
