if status is-interactive
    # Commands to run in interactive sessions can go here
end

set SPACEFISH_PROMPT_ADD_NEWLINE false

eval "$(/opt/homebrew/bin/brew shellenv)"

starship init fish | source
zoxide init fish | source
fzf --fish | source


function cat
    if defaults read -globalDomain AppleInterfaceStyle &> /dev/null
        bat --theme=default $argv
    else
        bat --theme=Github $argv
    end
end
alias ls="ls -la"
alias ls='eza --icons --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions'
alias cd="z"

set -gx FZF_CTRL_T_OPTS "--style=full --walker-skip=.git,node_modules,target --preview='bat -n --color=always {}' --bind='ctrl-/:change-preview-window(down|hidden|)'"

# set -g fish_greeting "Hello! Ready to code 😎"
set -g fish_greeting

