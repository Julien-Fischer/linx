# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information.

##############################################################
# Misc
##############################################################

# @description A command line calculator
# @param $1 a mathematical expression
# @return the expression result
# @example
#   calc 1+1     #  2
#   calc 1-2     # -1
#   calc 3*2     #  6
#   calc 6/2     #  3.00000000000000000000
#   calc "3 * 2" #  6
#   calc 2^4     # 16
#   calc 0.1+0.2 # .3
calc() {
    bc -l <<< "$@"
}

# Determine the type of an element (regular file, directory, symlink, etc)
typeof() {
    local element="${1}"
    if [ -d "$element" ]; then
        echo "$element is a directory."
    elif [ -L "$element" ]; then
        echo "$element is a symbolic link."
    elif [ -p "$element" ]; then
        echo "$element is a named pipe."
    elif [ -S "$element" ]; then
        echo "$element is a socket."
    elif [ -b "$element" ]; then
        echo "$element is a block device."
    elif [ -c "$element" ]; then
        echo "$element is a character device."
    elif [ -f "$element" ]; then
        echo "$element is a regular file."
    else
        echo "$element is of an unknown type."
    fi
}

# @description Ask a question to perplexity.ai
# @param $1 the question to be answered
# @example
#   ask "What time is it in London right now?"
ask() {
    local input="$1"
    local query="${input// /%20}"
    firefox "https://www.perplexity.ai/search?q=$query" && disown
}

##############################################################
# Visualization
##############################################################

# display the content of the specified directory using long format,
# sort by alphabetical order
function ll {
    local dir="${1:-.}"
    ls "${dir}" -lhAF
}

# display the content of the specified directory using long format,
# sort by alphabetical order, grouping directories first
ld() {
    local dir="${1:-.}"
    ls "${dir}" -lhAF --group-directories-first
}

# display the content of the specified directory using short format,
# sort by alphabetical order, grouping directories first
la() {
    local dir="${1:-.}"
    ls "${dir}" -AF --group-directories-first
}

# display the content of the specified directory using short format,
# sort by modification time
lt() {
    local dir="${1:-.}"
    ls -lhtAF -1 "${dir}"
}
alias ls='ls --color=auto'

##############################################################
# Navigation
##############################################################

# navigate to the specified directory and print its content
cs() {
    echo "${1}"
    cd "${1}" && ls -A --color -F --group-directories-first
}

# Create the specified directory and its ancestors if they do not exist yet, then change
# to that directory and print its content
mkcs() {
    mkdir -p "${1}"
    cs "${1}"
}

mkp() {
    mkdir -p
}

desk() {
    cs "$(xdg-user-dir DESKTOP)"
}

prog() {
    cs ~/programming
}

alias ~="cs ~"
alias u1="cs .."
alias u2="cs ../.."
alias u3="cs ../../.."
alias u4="cs ../../../.."
alias u5="cs ../../../../.."
alias u6="cs ../../../../../.."
alias ..='u1'
alias ...='u2'
alias ....='u3'
alias .....='u4'
alias ......='u5'
alias .......='u6'

##############################################################
# Config
##############################################################

alias reload='source ~/.bashrc && clear'
alias br='vim ~/.bashrc'
alias ba='vim ~/.bash_aliases.sh'
alias obr='open ~/.bashrc & disown'
alias oba='open ~/.bash_aliases.sh & disown'

# Automate aliases / functions upgrades
# This function installs the latest version of .bash_aliases.sh from the remote repository
upgrade_aliases() {
    git clone https://github.com/Julien-Fischer/bash_aliases
    mv ~/.bash_aliases.sh ~/.bash_aliases.bak
    cp bash_aliases/.bash_aliases.sh ~
    rm -rf bash_aliases
    reload
    echo "Upgrade successful."
}

##############################################################
# Bash
##############################################################

alias clr='clear'
alias cls='clear'
alias c='clear'
alias grep="grep --color=auto"
alias findf='find . -type f -name'
alias findd='find . -type d -name'
alias gh='history | grep'

# @description Copy files with a progress bar
# @param $1 the file or directory to copy
# @param $2 the destination
# @return 0 if the operation completed successfully; 1+ otherwise
# @example
#   cpv projects dirA  # copies projects into dirA
#   cpv projects/ dirA  # copies all files and directories from projects into dirA
cpv() {
    rsync -ah --info=progress2
}

##############################################################
# System
##############################################################

# Debian
# dbus-send --type=method_call --print-reply --dest=org.gnome.ScreenSaver /org/gnome/ScreenSaver org.gnome.ScreenSaver.Lock
# Kubuntu
alias bye='dbus-send --print-reply --dest=org.freedesktop.ScreenSaver /org/freedesktop/ScreenSaver org.freedesktop.ScreenSaver.Lock'
alias byebye='systemctl poweroff'
alias reboot='systemctl reboot'
alias mem='free -m -l -t'
alias du='du -h --max-depth=1'

drives() {
    mount | awk -F' ' '{printf \"%s\t%s\n\",\$1,\$3; }' | column -t | grep -E ^/dev/ | sort
}

##############################################################
# Network
##############################################################

alias ports='nmap localhost'
alias getip='curl ipinfo.io/ip && echo ""'
alias netstat='netstat -tuln'

##############################################################
# APT (change as needed when using a different package manager)
##############################################################

alias autorem='sudo apt autoremove'
alias update='sudo apt update'
alias upgrade='sudo apt update && sudo apt upgrade'
alias sup='sudo apt update && sudo apt upgrade -y && autorem'
alias install='sudo apt install'
alias remove='sudo apt remove'
alias search='apt search'
alias pls='sudo'

# Execute the last command with sudo
please() {
    sudo $(history -p !!)
}

##############################################################
# Git
##############################################################

alias gl='git log'
alias glo='git log --oneline'
alias glot='git log --pretty=format:"%C(yellow)%h%C(reset) %C(red)%ad%C(reset) %C(cyan)%an%C(reset) %s" --date=format:"%Y-%m-%d %H:%M" --abbrev-commit'
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m' # <message>
alias gp='git push'
alias gr='git reset --soft HEAD~1' # Reset local branch to the state before the last commit
alias gpf='git push --force origin' # <branch_name>  Replace the latest pushed commit with this one
alias gac='git add . && git commit -m' # <message>
gap() {
  gac "${1}" && gp
}
alias gtree='git log --oneline --graph --decorate'
alias gtree_all='gtree --all'
alias gstash='git add . && git stash'
# Permanently remove old, unreferenced commits
# /!\ Be cautious when using this command, as it permanently removes commits from your repository.
alias gclear='git reflog expire --expire=now --all && git gc --prune=now'
