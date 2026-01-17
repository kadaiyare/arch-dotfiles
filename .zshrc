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
alias zed='zeditor'
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

export PATH="$HOME/bin:$PATH"

# 1〜6世代からランダムにIDを決める
POKE_GEN=$(shuf -i 1-6 -n 1)

# 1/4096 の確率で色違いにする (512はお好みで変えてください)
if [ $(shuf -i 1-100 -n 1) -eq 1 ]; then
    # 当たり！色違いオプション(-s)をつける
    pokemon-colorscripts --random $POKE_GEN -s
else
    # ハズレ...通常色
    pokemon-colorscripts --random $POKE_GEN
fi
# Rust (Cargo) のパスを通す
export PATH="$HOME/.cargo/bin:$PATH"

# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
[[ ! -r '/home/taka/.opam/opam-init/init.zsh' ]] || source '/home/taka/.opam/opam-init/init.zsh' > /dev/null 2> /dev/null
# END opam configuration
