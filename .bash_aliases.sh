# Copyright © 2024 Julien Fischer <julien.fischer@agiledeveloper.net>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# The Software is provided “as is”, without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. In no event shall the authors or copyright holders Julien Fischer be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the Software.
# Except as contained in this notice, the name of the <copyright holders> shall not be used in advertising or otherwise to promote the sale, use or other dealings in this Software without prior written authorization from Julien Fischer.


# This is a straightforward Bash configuration file designed to streamline repetitive tasks and simplify lengthy command lines.
# I’m sharing my personal setup in the hope that it may be beneficial to others. It contains functions and aliases that I have personally used on Kubuntu 24 and Debian 12.
#
# Installation instructions:
# 1. Download this file or clone this repository
#    git clone https://github.com/Julien-Fischer/bash_aliases
# 2. Copy this file to your home directory
#    cp bash_aliases/bash_aliases.sh ~
# 3. Source the file in ~/.bashrc by adding the following lines:
#    if [ -f ~/.bash_aliases.sh ]; then
#        . ~/.bash_aliases.sh
#    fi
# 4. Reload your bash configuration
#    source ~/.bashrc
#
# Notes:
# For further reloads, simply open your CLI and type:
# reload

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
# @param $1 the question to get an answer to
# @example
#   ask "What time is it in London right now?"
ask() {
    local input="$1"
    local query="${input// /%20}"
    firefox "https://www.perplexity.ai/search?q=$query" && disown
}

##############################################################
# Navigation
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

# sort by alphabetical order, grouping directories first
la() {
    local dir="${1:-.}"
    ls "${dir}" -AF --group-directories-first
}

# navigate to the specified directory and print its content
cs() {
    cd "${1}" && ls -A --color -F --group-directories-first
}

# create the specified directory and its ancestors, navigate to it, and print its content
mkcs() {
    mkdir -p "${1}"
    cs "${1}"
}

alias mkp='mkdir -p'
alias ls='ls --color=auto'
alias lt='ls -lhtAF -1' # sort by modification time
alias ~="cs ~"
alias desk='cs ~/Desktop'
alias prog='cs ~/programming'
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

##############################################################
# APT (change as needed when using a different package manager)
##############################################################

alias update='sudo apt update'
alias upgrade='sudo apt update && sudo apt upgrade'
alias sup='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install'
alias remove='sudo apt remove'
alias search='apt search'
alias pls='sudo'

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

alias reboot='systemctl reboot'
alias bye='systemctl poweroff'
alias mem='free -m -l -t'
alias du='du -h --max-depth=1'
alias drives="mount | awk -F' ' '{printf \"%s\t%s\n\",\$1,\$3; }' | column -t | egrep ^/dev/ | sort"

##############################################################
# Network
##############################################################

alias ports='nmap localhost'
alias getip='curl ipinfo.io/ip && echo ""'
alias netstat='netstat -tuln'
