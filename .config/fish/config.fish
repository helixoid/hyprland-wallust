if status is-interactive
    # Commands to run in interactive sessions can go here
export TERMINAL=ghostty
starship init fish | source
atuin init fish | source
alias v="nvim"
alias prop="hyprctl clients | grep -i 'class\|title\|xwayland'"
alias ls='eza'
alias la='eza -a'
alias lla='eza -la'
alias lt='eza -la --tree'
alias ytmd='yt-dlp -x --add-metadata'
	# Yazi Integration
function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
		builtin cd -- "$cwd"
	end
	rm -f -- "$tmp"
end
end
