
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/akimotoritsuki/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/akimotoritsuki/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/akimotoritsuki/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/akimotoritsuki/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(rbenv init -)"

# Added by Windsurf
export PATH="/Users/akimotoritsuki/.codeium/windsurf/bin:$PATH"

