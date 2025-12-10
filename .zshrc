# --- Powerlevel10k Instant Prompt ---
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- Oh My Zsh Setup ---
# Oh My Zsh のパス設定 (一般的環境に合わせています)
export ZSH="$HOME/.oh-my-zsh"

# テーマはPowerlevel10k側で管理するので、ここは無効にしておくか "robbyrussell" のままでOK
ZSH_THEME="robbyrussell"

# 標準プラグイン (Oh My Zshに最初から入っているもの)
# ※ zsh-autosuggestions と zsh-syntax-highlighting はここから外して下で読み込みます
plugins=(git aliases copypath history docker github composer laravel brew zsh-completions)

# Oh My Zsh を読み込み (これがないと plugins=(...) は動きません)
# インストール済みであれば、このパスにファイルがあるはずです
source $ZSH/oh-my-zsh.sh

# --- Powerlevel10k Theme Configuration ---
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --- Aliases ---
alias ls='eza --icons --git --group-directories-first'
alias ll='eza --icons --git --group-directories-first -l'
alias la='eza --icons --git --group-directories-first -la'
alias ff='fastfetch'

# --- External Plugins (System Installed) ---
# パッケージマネージャ(/usr/share)に入っているプラグインは、
# Oh My Zshの管理外なので、直接 source して読み込みます。

# 1. Autosuggestions (入力補完)
if [ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# 2. Syntax Highlighting (構文ハイライト)
# ※ 必ずファイルの最後に読み込む必要があります
if [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi