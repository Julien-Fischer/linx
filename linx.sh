# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

# Source linx
if [ -f ~/.linx_lib.sh ]; then
    source "${HOME}"/.linx_lib.sh
fi

##############################################################
# Config
##############################################################

export PROMPT_TO_BOTTOM=1

##############################################################
# Misc
##############################################################

datetime() {
    timestamp
}

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
    firefox "https://www.perplexity.ai/search?q=${query}" &
}

# @description Search keywords with Firefox default search engine
# @param $1 the keywords to lookup
# @example
#   ask "Debian 13 release date"
search() {
    firefox -search "${1}"
}

# @description Translate the following word
# @param $1 the word to translate
# @param $2 (optional) the source language (French by default)
# @param $3 (optional) the target language (English by default)
# @example
#   command                output
#   translate salut        hi
#   translate schön de en  nice
translate() {
    local query="${1}"
    local src="${2:-fr}"
    local dest="${3:-en}"
    curl -s "https://api.mymemory.translated.net/get?q=${query}&langpair=${src}|${dest}" | jq '.responseData.translatedText'
}

##############################################################
# Visualization
##############################################################

# @description display the content of the specified directory using long format,
# sort by alphabetical order
# @param $1 (optional) the directory to inspect; pwd by default
ll() {
    local dir="${1:-.}"
    ls "${dir}" -lhAF
}

# @description display the content of the specified directory using short format,
# sort by alphabetical order, grouping directories first
# @param $1 (optional) the directory to inspect; pwd by default
# shellcheck disable=SC2120
la() {
    local dir="${1:-.}"
    ls "${dir}" -AF --group-directories-first
}

# @description display the content of the specified directory using long format,
# sort by alphabetical order, grouping directories first
# @param $1 (optional) the directory to inspect; pwd by default
ld() {
    local dir="${1:-.}"
    ls "${dir}" -lhAF --group-directories-first
}

# @description display the content of the specified directory using short format,
# sort by modification time
# @param $1 (optional) the directory to inspect; pwd by default
lt() {
    local dir="${1:-.}"
    ls "${dir}" -lhAFt -1
}

alias ls='ls --color=auto'

##############################################################
# Navigation
##############################################################

# toggle between the current and the last visited directory.
-() {
    cd - > /dev/null && pwd && la
}

# navigate to the previous directory and print its content
--() {
    popd > /dev/null || echo "No previous directory to navigate to"
}

# navigate to the specified directory and print its content
cs() {
    pushd "${1}" > /dev/null && pwd && la
}

# Create the specified directory and its ancestors if they do not exist yet, then change
# to that directory and print its content
mkcs() {
    mkdir -p "${1}"
    cs "${1}"
}

mkp() {
    mkdir -p "${1}"
}

desk() {
    cs "$(xdg-user-dir DESKTOP)"
}

dev() {
    request_dir "${DEV}" "DEV"
}

foss() {
    request_dir "${FOSS}" "FOSS"
}

alias ,="cs /"
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

pp() {
    local depth="${1:-1}"
    tree -L "${depth}"
}

##############################################################
# Config
##############################################################

alias reload='source ~/.bashrc && clear'
alias br='vim ~/.bashrc'
alias ba='vim ~/linx.sh'
alias obr='open ~/.bashrc & disown'
alias oba='open ~/linx.sh & disown'

# @description Prompts the user for approval
# @param $1 The action to be confirmed
# @param $2 The prompt message for the user
# @return 0 if user confirms, 1 otherwise
# @example
#  # Abort on anything other than y or yes (case insensitive)
#  prompt "Installation" "Proceed?" --abort
#
#  # Use return status
#  if [[ prompt "Installation" "Proceed?"]]; then
#    # on abort
#  else
#    # on confirm...
#  fi
function prompt() {
    confirm "$@"
}

# @description Switch to a specified Terminator profile. If no parameter is provided, list the available profiles
# @param $1  (optional) the name of the profile to switch to
# @example
#   # List available profiles
#   profiles
#   # Switch to the specified profile
#   profiles profile_name
profiles() {
    local profile_name="${1}"
    if [[ -z "${profile_name}" ]]; then
        list_profiles
        return 0
    fi
    if set_profile "$@"; then
        echo "Switched to ${profile_name} profile. Restart Terminator to apply the theme."
        return 0
    fi
    echo -e "$(color "E:") Could not switch to ${profile_name} profile."
    return 1
}

# @description Although this function could be invoked directly, it is usually executed via the profiles function
# @example
#  # The following function calls are strictly equivalent:
#  profiles
#  print_profile
list_profiles() {
    if [[ ! -f "${TERMINATOR_CONFIG_FILE}" ]]; then
        echo "Configuration file not found at ${TERMINATOR_CONFIG_FILE}"
        return 1
    fi
    local reading_profiles=1
    local profiles=()
    while IFS= read -r line; do
        if is_comment "${line}"; then
            continue;
        fi
        if [[ "${line}" == "[profiles]" ]]; then
            reading_profiles=0
            continue
        fi
        if [[ "${line}" =~ ^\[[^\]]+\]$ && "${line}" != "[profiles]" ]]; then
            reading_profiles=1
        fi
        if [[ $reading_profiles -eq 0 && "${line}" =~ \[\[([^\]]+)\]\] ]]; then
            profiles+=("${BASH_REMATCH[1]}")
        fi
    done < "${TERMINATOR_CONFIG_FILE}"
    echo "${#profiles[@]} available profiles:"
    local current_theme=
    if [[ -f "${CURRENT_THEME_FILE}" ]]; then
        current_theme=$(cat "${CURRENT_THEME_FILE}")
    fi
    for profile in "${profiles[@]}"; do
        if [[ -n "${current_theme}" && "${profile}" == "${current_theme}" ]]; then
            echo -e "$(color profile)"
        else
            echo "- ${profile}"
        fi
    done
}

##############################################################
# Bash
##############################################################

alias clr='clear'
alias cls='clear'
alias c='clear'
alias grep="grep --color=auto"
alias gh='history | grep'
alias greph='history | grep'
alias grepa='alias | grep'

# @description Finds a file recursively in the specified directory, or the current directory by default
# @param $1 the name of the file to look for
# @param $2 (optional) the current directory
# @example
#   findf ".bash"
#   findf ".bash" "/"
findf() {
    local name="${1}"
    local directory="${2:-.}"
    sudo find "${directory}" -type f -name "*${name}*" 2>/dev/null | grep "${name}"
}

# @description Finds a directory recursively starting from the current directory (by default), or the specified directory if one is provided
# @param $1 the name of the file to look for
# @param $2 (optional) the current directory
# @example
#   findf ".bash"
#   findf ".bash" "/"
findd() {
    local name="${1}"
    local directory="${2:-.}"
    sudo find "${directory}" -type d -name "*${name}*" 2>/dev/null | grep "${name}"
}

##############################################################
# Accounts
##############################################################

# @description Prints the list of users in this system as newline-separated list of usernames
# @param $1 (optional) --detailed to pretty print a human-readable ASCII table of usernames and their privileges
# @example
#   list_users
#   list_users --detailed
list_users() {
    local detailed="${1}"
    if [[ "${detailed}" == "--detailed" ]]; then
        print_line() {
            printf '+-%*s-+-%*s-+-%*s-+\n' 20 '' 15 '' 15 '' | tr ' ' '-'
        }
        # Print table header
        print_line
        printf "| %-20s | %-15s | %-15s |\n" "Username" "Privilege" "Can Login"
        print_line
        # Process and print user information
        while IFS=: read -r username _ uid gid _ _ shell; do
            # Determine user privilege level
            if [[ $uid -eq 0 || $gid -eq 0 ]]; then
                privilege="Admin (root)"
            elif groups "$username" 2>/dev/null | grep -qE "\b(sudo|admin|wheel)\b"; then
                privilege="Sudoer"
            else
                privilege="Regular user"
            fi
            # Determine login status based on shell
            if [[ "$shell" == "/sbin/nologin" || "$shell" == "/usr/sbin/nologin" || "$shell" == "/bin/false" ]]; then
                login_status="No"
            else
                login_status="Yes"
            fi
            # Print user information
            printf "| %-20s | %-15s | %-15s |\n" "${username:0:20}" "${privilege:0:15}" "${login_status:0:15}"
        done < <(getent passwd)
        print_line
    else
        while IFS=: read -r username _; do echo "$username"; done < <(getent passwd)
    fi
}

##############################################################
# System
##############################################################

bye() {
    if command -v loginctl &> /dev/null; then
        loginctl lock-session
    else
        echo -e "$(color 'E:') loginctl not found. Ensure you're using a system with systemd."
    fi
}
alias byebye='systemctl poweroff'
alias reboot='systemctl reboot'
alias mem='free -m -l -t'
alias du='du -h --max-depth=1'
alias hardware='neofetch' # or any other tool or custom function that fits your needs

drives() {
    mount | awk -F' ' '{printf \"%s\t%s\n\",\$1,\$3; }' | column -t | grep -E ^/dev/ | sort
}

cpu_usage() {
    grep 'cpu' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage "%"}'
}

bat_capacity() {
    cat /sys/class/power_supply/BAT0/capacity
}

bat() {
    bat_capacity
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
alias upgrades='sudo apt update && apt list --upgradable'
alias upgrade='sudo apt update && sudo apt upgrade'
alias sup='sudo apt update && sudo apt upgrade -y && autorem'
alias install.sh='sudo apt install.sh'
alias remove='sudo apt remove'
alias pls='sudo'

# Execute the last command with sudo
please() {
    sudo $(history -p !!)
}

# @description Determines whether a software is installed on this system
# @param $1 the software name
# @param $2 0 if there should be not output for non-installed software
# @return 0 if the software is installed; 1 otherwise
#   is_installed firefox
# @example
is_installed() {
    return $(installed "$@")
}

# @description Upgrades the specified software to the latest version
# @param $1 the software to upgrade
# @return 0 if the software was installed; 1 otherwise
# @example
#   upgrade_only firefox
upgrade_only() {
    local software="${1}"
    if ! is_installed "${software}" -q; then
        echo -e "$(color "E:") ${software} needs to be installed first."
        echo "Looking for ${software} on APT:"
        apt search "${software}"
        return 1
    fi
    sudo apt update && sudo apt install.sh --only-upgrade "${software}"
}

##############################################################
# Git
##############################################################

# Project initialization

gproject() {
    local name="${1}"
    mkcs "${name}" && git init
    echo ".idea" > .gitignore
}
alias gin="git init"
alias gcl="git clone"

# Log visualization

# @description Traditional git log
# @param $1 (optional) asc to sort the log by ascending order
gl() {
    local sort_direction="${1}"
    if [[ "${sort_direction}" == "asc" ]]; then
        shift
        git log --reverse "$@" --color=always
        return 0
    fi
    git log "$@" --color=always
}

# @description Git log (one-line)
# @param $1 (optional) asc to sort the log by ascending order, or the name of the branch
glo() {
    gl "$@" --oneline
}

# @description Git log (time)
# @param $1 (optional) asc to sort the log by ascending order
glot() {
    gl "$@" --pretty=format:"%C(yellow)%h%C(reset) %C(red)%ad%C(reset) %C(cyan)%an%C(reset) %s" --date=format:"%Y-%m-%d %H:%M" --abbrev-commit
}

# @description Git log (releases)
# @param $1 (optional) asc to sort the log by ascending order
glor() {
    gl "$@" --no-walk --tags --pretty=format:"%C(yellow)%h%C(reset)|%C(red)%ad%C(reset)|%C(bold yellow)%d%C(reset)|%C(magenta)%an%C(reset)|%s" --date=format:"%Y-%m-%d %H:%M" --abbrev-commit | column -t -s '|'
}

# @description Git log (tree)
gtree() {
    glo --graph --decorate
}

# @description Git log (tree all)
gtree_all() {
    gtree --all
}

# @description Find the first commit in the log
# @param $1 (optional) the number of commits to find starting from the first one (1 by default)
gfirst() {
    local n=${1:-1}
    glot asc | head -$n
}

# @description Find the last commit in the log
# @param $1 (optional) the number of commits to find starting from the last one (1 by default)
glast() {
    local n=${1:-1}
    glot | head -$n
}

gshow() {
    local hash="${1}"
    git show "${hash}"
}

gstat() {
    local hash="${1}"
    git show "${hash}" --stat
}

# Changes visualization

alias gs='git status'
alias gd='git diff' # <filename>

# History modifications

alias ga='git add .'
alias gc='git commit -m' # <message>
alias gp='git push'
alias gac='git add . && git commit -m' # <message>
gap() {
  gac "${1}" && gp
}

# @description Reset the local branch to the state before the last commit, or reset n commits starting from the HEAD if an integer is specified
# @param $1 (optional) the number of commits to reset
# examples
#   gr    # reset the last commit
#   gr 3  # reset the latest 3 commits
gr() {
  local n=${1:-1}
  local current_branch=$(git branch --show-current)
  if ! [[ "$n" =~ ^[0-9]+$ ]] || [[ "$n" -le 0 ]]; then
      echo "Error: Please provide a positive integer for the number of commits to reset."
      return 1
  fi
  local total_commits=$(git rev-list --count HEAD)
  if [[ "$total_commits" -eq 1 ]]; then
      echo "Error: Cannot reset to the previous commit since there is only one commit in ${current_branch}"
      return 1
  fi
  if [[ "$n" -ge "$total_commits" ]]; then
      echo "Error: Cannot reset $n commits since there are only $total_commits commits in ${current_branch}"
      return 1
  fi
  git reset --soft HEAD~$n
  echo "Successfully reset $n commits in ${current_branch}"
}

alias gpf='git push --force origin' # <branch_name>  Replace the latest pushed commit with this one

# @description Stage all changes, commit them with the specified message, and force push the commit
gapf() {
    gac "${1}" && gpf
}

# @description Stashes all changes
# @param $1 (optional) an optional message
# @example
#   gas
#   gas "wip"
gas() {
    local msg="${1:-''}"
    git add .
    if [[ -z "${1}" ]]; then
        git stash
    else
        git stash -m "${msg}"
    fi
}

alias gsp="git stash pop"
alias gsa="git stash apply"

gsl() {
    git stash list
}

# @description drops a stash entry
# @param $1 (optional) the zero-based index of the stash entry to drop, or the last one if no index is specified
# @example
#   gsd
#   gsd 1
#   gsd 5
gsd() {
    local index="${1:-0}"
    if [[ -n $index ]]; then
        git stash drop stash@\{"${index}"\}
    fi
}

# Branch management

alias gck="git checkout" # <branch_name>
alias gcb="git checkout -b" # <branch_name>
alias gb="git branch" # <branch_name>

# Permanently remove old, unreferenced commits
# /!\ Be cautious when using this command, as it permanently removes commits from your repository.
alias gclear='git reflog expire --expire=now --all && git gc --prune=now'

##############################################################
# Docker
##############################################################

alias dps="docker ps"
alias dpsa="docker ps -a"
alias dim="docker images"
alias dima="docker images -a"

##############################################################
# Custom ENV variables
##############################################################

if [[ $PROMPT_TO_BOTTOM -eq 0 ]]; then
    prompt_to_bottom() {
        tput cup $LINES
    }
    PROMPT_COMMAND=prompt_to_bottom
fi
