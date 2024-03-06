if status is-interactive
    # Commands to run in interactive sessions can go here
macchina
starship init fish | source
alias v="nvim"
alias hx="helix"
alias prop="hyprctl clients | grep -i 'class\|title\|xwayland'"
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
export TERM=kitty
end
