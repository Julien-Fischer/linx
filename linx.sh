# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

# Source linx
if [ -f "${HOME}"/linx/.linx_lib.sh ]; then
    source "${HOME}"/linx/.linx_lib.sh
    source "${HOME}"/linx/.autocomplete.sh
fi

##############################################################
# Config
##############################################################

PROMPT_TO_BOTTOM=false
if [[ -f "${LINX_CONFIG_FILE}" ]]; then
    linx_prompt_to_bottom=
    linx_prompt_to_bottom=$(get_linx_property "prompt.to.bottom" -q)
    if [[ $? -eq 0 && "${linx_prompt_to_bottom}" == "true" ]]; then
        PROMPT_TO_BOTTOM=true
    fi
fi

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

# @description Generate a random integer between min and max
# @param $1 the lower bound (inclusive)
# @param $2 the higher bound (inclusive)
# @example
#   rand 0 0      # outputs 0
#   rand 0 1      # outputs 0 or 1
#   rand 0 10     # outputs any integer between 0 and 10
#   rand -10 10   # outputs any integer between -10 and 10
rand() {
    local min=$1
    local max=$2
    if [[ -z "${min}" || -z "${max}" ]]; then
        err "Usage: rand <min> <max>"
        return 1
    fi
    echo $(( RANDOM % (max - min + 1) + min ))
}

# Determine the type of an element (regular file, directory, symlink, etc)
typeof() {
    local element="${1}"
    if [ -d "${element}" ]; then
        echo "${element} is a directory."
    elif [ -L "${element}" ]; then
        echo "${element} is a symbolic link."
    elif [ -p "${element}" ]; then
        echo "${element} is a named pipe."
    elif [ -S "${element}" ]; then
        echo "${element} is a socket."
    elif [ -b "${element}" ]; then
        echo "${element} is a block device."
    elif [ -c "${element}" ]; then
        echo "${element} is a character device."
    elif [ -f "${element}" ]; then
        echo "${element} is a regular file."
    else
        type "${element}"
    fi
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

now() {
    timestamp
}

# @description Copy to clipboard
# @note: Only works on x11. Install xclip using: sudo apt-get install xclip
# @example
#   clc < filename           # copy the content of filename to clipboard
#   cat filename | clc       # copy the content of filename to clipboard
#   echo some_string | clc   # copy the literal string some_string to clipboard
clc() {
    xclip -selection clipboard
}

# @description Paste from clipboard
# @note: Only works on x11. Install xclip using: sudo apt-get install xclip
# @example
#   clp > newfile.txt        # paste the clipboard to newfile.txt
clp() {
    xclip -selection clipboard -o
}

# @description anonymize the content of the clipboard by replacing substrings that match keys defined in $LINX_DIR/anonymize
# @option -e, --edit  open anonymize.properties in vim
# @option -s, --case-sensitive  use case-sensitive matching
# @option -m, --message  specify an input string as the source to anonymize
# @option -f, --file  specify the path of a file as the source to anonymize
# @option -h, --help  print help and exit
anonymize() {
    local USAGE="Usage: anonymize [[c,config] [[-s,--case-sensitive] [-m|--message] [-f|--file]] [[--help]]]"
    local case_sensitive=''
    local text=

    if [[ "$#" -gt 0 ]]; then
        case $1 in
            c|config)
                vim "${LINX_ANONYMIZE_FILE}"
                return
                ;;
            -m|--message)
                text="${2}"
                ;;
            -f|--file)
                text="$(cat "${2}")"
                ;;
            -h|--help)
                echo "${USAGE}"
                return
                ;;
            -s|--case-sensitive)
                case_sensitive=--case-sensitive
                ;;
            *)
                err "Invalid parameter: ${1}"
                echo "${USAGE}"
                return 1
                ;;
        esac
    fi

    if [[ -z "${text}" ]]; then
        text="$(xclip -selection clipboard -o)"
    fi

    local anonymized
    anonymized=$(anonymize_plain_text "${text}" "${case_sensitive}")
    echo -e "${anonymized}" | xclip -selection clipboard
    echo "Text anonymized."
}

# @description  Execute a command passed as parameter and outputs the result to both stdout and a file located at "${LINX_SPY_FILE}"
# @option -r, --read  Read the content of "${LINX_SPY_FILE}"
# @params $@  The command to execute
# @example
#   spy git commit -m "hello, world!"
#   spy glot -t --asc
#   spy --read
#   spy -r
spy() {
    if [[ "${1}" == -r || "${1}" == --read ]]; then
        cat "${LINX_SPY_FILE}"
        return 0
    fi
    "$@" | tee "${LINX_SPY_FILE}"
}

function rec() {
    if ! installed simplescreenrecorder -q; then
        err "simplescreenrecorder is not installed."
        echo "You can install it with"
        echo "  sudo apt update && sudo apt install simplescreenrecorder"
        return 1
    fi
    simplescreenrecorder --start-recording >/dev/null 2>&1
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
alias ..='up 1'
alias ...='up 2'
alias ....='up 3'
alias .....='up 4'
alias ......='up 5'
alias .......='up 6'

up() {
    local count=${1:-1}
    if ! is_numeric "${count}" || [[ $count -lt 1 ]]; then
        err "Count must be a non-negative integer"
        return 1
    fi
    local target_dir
    target_dir=$(printf '../%.0s' $(seq 1 "${count}"))
    if cs "${target_dir}" > /dev/null; then
        la
    else
        err "Could not cd into ${target_dir}"
        return 1
    fi
}

pp() {
    local depth="${1:-1}"
    tree -L "${depth}"
}

##############################################################
# Config
##############################################################

alias reload='source ~/.bashrc && clear'
alias br='vim ~/.bashrc'
alias ba='vim ${LINX_DIR}/${LINX_FUNC_FILE_NAME}'
alias obr='open ~/.bashrc & disown'
alias oba='open ${LINX_DIR}/${LINX_FUNC_FILE_NAME} & disown'
alias linxn='cs ${LINX_DIR}'

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

# @description Finds a directory recursively starting from the current directory (by default), or
#              the specified directory if one is provided
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
        err "loginctl not found. Ensure you're using a system with systemd."
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
alias sup='sudo apt update && sudo apt upgrade -y'
alias remove='sudo apt remove'

function install() {
    local software="${1}"
    sudo apt update && sudo apt install "${software}"
}

# Execute the last command with sudo
please() {
    # shellcheck disable=SC2046
    sudo $(history -p !!)
}

pls() {
    please "$@"
}

# @description Determines whether a software is installed on this system
# @param $1 the software name
# @param $2 0 if there should be not output for non-installed software
# @return 0 if the software is installed; 1 otherwise
#   is_installed firefox
# @example
is_installed() {
    installed "$@"
    return $?
}

# @description Upgrades the specified software to the latest version
# @param $1 the software to upgrade
# @return 0 if the software was installed; 1 otherwise
# @example
#   upgrade_only firefox
upgrade_only() {
    local software="${1}"
    if ! is_installed "${software}" -q; then
        err "${software} needs to be installed first."
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

alias ginit="git init"
alias gin="git init"

# @description Generates a new git project with a .gitignore file
# @param $1 the url of the repository to clone
# @param $2 (optional) the name of the branch to checkout
# @options $@ (optional) any other git clone options
# @example
#   gcl "https://github.com/Julien-Fischer/linx.git"
#   gcl "https://github.com/Julien-Fischer/linx.git" main
#   gcl "https://github.com/Julien-Fischer/linx.git" main --origin remote_name
gcl() {
    local repository="${1}"
    local branch_name="${2}"
    shift 2
    if [[ -z "${repository}" ]]; then
        err "No repository specified"
        return 1
    fi
    if [[ -n "${branch_name}" ]]; then
        git clone "${repository}" --branch "${branch_name}" "$@"
    else
        git clone "${repository}"
    fi
}

# Project updates

alias gft="git fetch"
alias gpl="git pull"

# Log visualization

# @description Print own commits on the current local branch
# @flag --asc sort output by ascending order (descending by default)
# @flag -t, --today show only today's commits
# @example
#   gmine                # print the local branch history
#   gmine --asc          # sort output by ascending order
#   gmine --today        # filter output by committer name or email, showing only today's commits
gmine() {
    glot "$(git config user.name)" "$@"
}

# @description Count the number of commits in a git project
# @param $1 (optional) group commit count by author
# @examples
#   gcount           # Total commit count
#   gcount -a        # aggregate per author
#   gcount --author  # aggregate per author
gcount() {
    if ! is_git_repo; then
        return 1
    fi
    local group_by="${1}"
    if [[ "${group_by}" = '-a' || "${group_by}" =~ ^--authors?$ ]]; then
        total_commits=$(git rev-list --count HEAD)

        printf "%-25s | %-8s | %-10s | %-10s | %-10s | %-40s\n" "Committer" "Commits" "Percentage" "First" "Last" "Email"
        printf "%-25s-+-%-8s-+-%-10s-+-%-10s-+-%-10s-+-%-40s\n" "-------------------------" "--------" "----------" "----------" "----------" "----------------------------------------"

        git log --format="%ae|%an|%at" |
        awk -F'|' -v total="$total_commits" '
        {
            email = $1
            name = $2
            timestamp = $3

            if (!(email in committers)) {
                committers[email] = name
                commits[email] = 0
                first_commit[email] = timestamp
                last_commit[email] = timestamp
            }

            commits[email]++
            if (timestamp < first_commit[email]) first_commit[email] = timestamp
            if (timestamp > last_commit[email]) last_commit[email] = timestamp
        }
        END {
            for (email in committers) {
                name = committers[email]
                gsub(/[^[:print:]]/, "", name)
                name = substr(name, 1, 25)

                percentage = sprintf("%.2f%%", (commits[email] / total) * 100)

                printf "%d|%-25s | %8d | %9.2f%% | %-10s | %-10s | %s\n",
               commits[email],
               name,
               commits[email],
               (commits[email] / total) * 100,
               strftime("%Y-%m-%d", first_commit[email]),
               strftime("%Y-%m-%d", last_commit[email]),
               email
            }
        }' | sort -rn | cut -d'|' -f2-
    else
        git rev-list --count HEAD
    fi
}

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
# @example
#   glo
#   glo <branch_name>
glo() {
    gl "$@" --oneline
}

# @description Git log (releases)
# @param $1 (optional) asc to sort the log by ascending order
glor() {
    local format="%C(yellow)%h%C(reset)|%C(red)%ad%C(reset)|%C(bold yellow)%d%C(reset)|%C(magenta)%an%C(reset)|%s"
    gl "$@" \
      --no-walk \
      --tags \
      --pretty=format:"${format}" \
      --date=format:"%Y-%m-%d %H:%M" \
      --abbrev-commit \
      | column -t -s '|'
}

# @description Git log (tree)
gtree() {
    glo --graph --decorate
}

# @description Git log (tree all)
gtree_all() {
    gtree --all
}

# @description Find the oldest n local commits in the current branch
# @param $1 (optional) the number of commits to find starting from the first one (1 by default)
# @option -i, --id if the output should be the hash of the initial commit
# @option -s, --short if the output should be the short hash of the initial commit
# @example
#   gfirst
#   gfirst 3
#   gfirst -i
#   gfirst --id
gfirst() {
    IFS=$'\x1E' read -ra new_args < <(decluster "$@")
    set -- "${new_args[@]}"

    local n=${1//[^0-9]/}
    n=${n:-1}
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -i|--id)
                if [[ "${2}" == "-s" || "${2}" == "--short" ]]; then
                    git log --format=%h --abbrev-commit | tail -n "${n}"
                else
                    git log --format=%H | tail -n "${n}"
                fi
                return 0
                ;;
            -m|--message)
                git log --pretty=format:%s | tail -n "${n}"
                return 0
                ;;
            *)
                if [[ $1 =~ ^[0-9]+$ ]]; then
                    n=$1
                else
                    echo "Unsupported parameter ${1}"
                    echo "Usage: gfirst [count] [--id [--short]] [--message]"
                    return 1
                fi
                ;;
        esac
        shift
    done
    glot -m | tail -$n
}

# @description Find the latest n local commits in the current branch
# @param $1 (optional) the number of commits to find starting from the last one (1 by default)
# @option -i, --id if the output should be the hash of the latest commit
# @option -s, --short if the output should be the short hash of the latest commit
# @option -m, --message if the output should be the message of the latest commit
# @example
#   glast        # print the last commit
#   glast 3      # print the last 3 commits
#   glast -i     # print the hash of the last commit
#   glast -i -s  # print the short hash of the last commit
#   glast -m     # print the message of the last commit
#   glast 10 -m  # print the message of the last 10 commit
#   glast 10 -is # print the short hash of the last 10 commits
glast() {
    IFS=$'\x1E' read -ra new_args < <(decluster "$@")
    set -- "${new_args[@]}"

    local n=${1//[^0-9]/}
    n=${n:-1}
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -i|--id)
                if [[ "${2}" == "-s" || "${2}" == "--short" ]]; then
                    git rev-list -n "${n}" --abbrev-commit HEAD
                else
                    git rev-list -n "${n}" HEAD
                fi
                return 0
                ;;
            -m|--message)
                git log "-${n}" --pretty=format:%s
                return 0
                ;;
            *)
                if [[ $1 =~ ^[0-9]+$ ]]; then
                    n=$1

                else
                    echo "Unsupported parameter ${1}"
                    echo "Usage: glast [count] [--id [--short]] [--message]"
                    return 1
                fi
                ;;
        esac
        shift
    done
    glot -m | head -$n
}

# @description Dump the git log of the current local branch in a file in the current directory. If
#              git.log.dump.directory is defined in "${LINX_CONFIG_FILE}", the output will be generated
#              in this directory instead.
# @param $1 (optional) the path of the file to write to (a timestamped .gdump file by default)
gdump() {
    if ! is_git_repo; then
        return 1
    fi

    local filepath="${1}"
    local config_filepath dirname directory_path

    config_filepath=$(get_linx_property "git.log.dump.directory" -q)
    dirname=$(basename "$(pwd)")

    if [[ -z "${filepath}" ]]; then
        local prefix=
        prefix="$(timestamp -b)"
        filepath="${dirname}_${prefix}.gdump"
        if [[ -d "${config_filepath}" ]]; then
            filepath="${config_filepath}/${filepath}"
        fi
    fi

    if ! gcount -a > "${filepath}"; then
        err "Could not write to ${filepath}"
        return 1
    fi
    echo "" >> "${filepath}"
    glot >> "${filepath}"

    directory_path="$(realpath "${filepath}")"
    echo -e "created: $(color "$(basename "${filepath}")" "${GREEN_BOLD}") in: $(color "${directory_path}" "${YELLOW_BOLD}")"
}

# @description  List all unpushed commits in the current branch
git_unpushed() {
    if [[ -n "$(git_current_branch --remote)" ]]; then
        git log --oneline "@{push}.."
    else
        git log --oneline
    fi
}

# Changes visualization

gdiff() {
    git diff "${1}"
}

gshow() {
    local hash="${1}"
    git show "${hash}"
}

# @description When called with a commit hash, show the stats for that specific commit; otherwise
#              show the stats for both staged and unstaged changes.
# @param $1 (optional) a commit hash
gstat() {
    local hash="${1}"
    if [[ $# -eq 0 ]]; then
        echo -e "$(color 'Staged:' "${GREEN}")"
        git diff --cached --stat
        echo -e "\n$(color 'Unstaged:')"
        git diff --stat
    else
        git show "${hash}" --stat
    fi
}

alias gs='git status'
alias gd='git diff' # <filename>

# worktree management

gwt() {
    local open_worktree=false
    local directory_path
    local params=()
    while [[ $# -gt 0 ]]; do
        case $1 in
            -o|--open)
                open_worktree=true
                ;;
            o|open)
                open_worktree=true
                local branch_name="${2}"
                local project
                project="$(basename "$(pwd)")"
                directory_path="$(get_linx_property "git.worktrees.directory")/${project}/${branch_name}"
                params=("add" "${directory_path}" "${branch_name}")
                break
               ;;
            add)
                directory_path="${2}"
                params+=("add")
                ;;
            *)
                params+=("${1}")
                ;;
        esac
        shift
    done

    if ! git worktree "${params[@]}"; then
        open_worktree=false
    fi

    if [[ -n "${directory_path}" ]] && $open_worktree; then
        idea "${directory_path}"
    fi
}

# History modifications

# @description (Git Reset) Unstage all files, or a specific file (if specified)
# @param $1 (optional) the name of the file to stage, or nothing if all files must be staged
gr() {
    local filename="${1}"
    if [[ -n "${filename}" ]]; then
        git reset "${filename}"
    else
        git reset
    fi
}

# @description (Git Add) all files, or a specific file (if specified)
# @param $1 (optional) the name of the file to stage, or nothing if all files must be staged
ga() {
    local filename="${1}"
    if [[ -n "${filename}" ]]; then
        git add "${filename}"
    else
        git add .
    fi
}
alias gc='git commit -m' # <message>
alias gp='git push'
alias gac='git add . && git commit -m' # <message>
gap() {
    gac "${1}" && gp
}

# @description (Git Reset Soft) Reset the local branch to the state before the last commit, or reset n commits starting
#              from the HEAD if an integer is specified, and keep the changes in staging
# @param $1 (optional) the number of commits to reset
# examples
#   grs    # reset the last commit
#   grs 3  # reset the latest 3 commits
# shellcheck disable=SC2120
grs() {
    local n=${1:-1}
    local current_branch
    current_branch=$(git_current_branch)
    if ! [[ "$n" =~ ^[0-9]+$ ]] || [[ "$n" -le 0 ]]; then
        echo "Error: Please provide a positive integer for the number of commits to reset."
        return 1
    fi
    local total_commits
    total_commits=$(git rev-list --count HEAD)
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
    git diff --cached --stat
}

alias gpf='git push --force origin' # <branch_name>  Replace the latest pushed commit with this one

# @description Stage all changes, commit them with the specified message, and force push the commit
gapf() {
    gac "${1}" && gpf
}

# Add the current local changes to the latest remote commit
# @param $1 (Optional) The new commit message
# /!\ this function uses a reset --soft on HEAD, so careful when using it, especially on team projects
gedit() {
    local msg="${1}"
    if [[ -z "${msg}" ]]; then
        msg="$(glast -m)"
    fi
    grs && gapf "${msg}"
}

# @description Backup the current branch then replays all commits from HEAD to the specified commit hash (excluded)
# @param $1 (Optional) The hash of the commit before the ones you wish to replay
# @option i, --instant don't wait between each commit replay
# @option p, --push automatically push once commits has been replayed
# @example
#   Given the following commits: a b c d e f
#   replay_commits d  # replays a, b, and c
replay_commits() {
    if ! is_git_repo; then
        return 1
    fi

    local DEFAULT_MAX_WAIT_SECONDS=6
    local max_wait_seconds
    # shellcheck disable=SC2034
    max_wait_seconds="$(get_linx_property "git.replay.max-wait" -q --default "${DEFAULT_MAX_WAIT_SECONDS}")"

    local instant=false
    local push=false
    local start_commit_hash_excluded="${1}"
    shift

    if [[ -z "${start_commit_hash_excluded}" ]]; then
        err "A start commit is required"
        return 1
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--instant)
                instant=true
                ;;
            -p|--push)
                push=true
                ;;
            *)
                echo "Usage: replay_commits [[-i,--instant]] [[-p,--push]]"
                return 1
                ;;
        esac
        shift
    done

    local count
    count=$(count_commits_since "${start_commit_hash_excluded}")

    if [[ $count -eq 0 ]]; then
        err "0 commits to republish"
        return 1
    fi

    if ! backup_current_branch; then
        return 1
    fi

    echo -e "Undoing $(color "${count}" "${YELLOW_BOLD}") commits"

    local undone_commits=()

    for (( i = 0; i < count; i++ )); do
        local current_hash current_message
        current_hash="$(glast -is)"
        current_message="$(glast -m)"
        undone_commits+=("${current_hash} ${current_message}")

        if ! grevert > /dev/null; then
            err "Could not undo commit ${current_hash}"
            return 1
        fi
    done

    echo ""
    echo "Undone commits:"
    for commit in "${undone_commits[@]}"; do
        echo "  $commit"
    done

    echo ""
    linx_spinner_start
    echo -e "Restoring $(color "${#undone_commits[@]}" "${YELLOW_BOLD}") commits"

    local redone_commits=()

    for (( i = 0; i < count; i++ )); do
        local duration=0
        if ! $instant; then
            duration=$(rand 1 max_wait_seconds)
        fi

        if ! grestore > /dev/null; then
            err "Could not replay commit"
            return 1
        fi

        local new_hash new_message

        new_hash="$(glast -is)"
        new_message="$(glast -m)"
        echo -e "\r   \r  Replaying: ${new_hash} ${new_message}"

        if [[ $i -lt $((count - 1)) ]]; then
            sleep "$duration"
        fi

        redone_commits+=("${new_hash} ${new_message}")
    done

    linx_spinner_stop

    echo ""
    echo "Restored commits:"
    for commit in "${redone_commits[@]}"; do
        echo "  $commit"
    done

    echo ""
    echo -e "$(color "${#redone_commits[@]}" "${YELLOW_BOLD}") Commits replayed"

    if ! $push; then
        return 0
    fi

    if git push; then
        echo "Pushed $(color "${count}" "${GREEN_BOLD}") commits to the remote"
    else
        err "Failed to push $(color "${count}" "${GREEN_BOLD}") commits to the remote"
        return 1
    fi
}

count_commits_since() {
    local commit="${1}"
    git rev-list "${commit}"..HEAD --count
}

backup_current_branch() {
    local current_branch backup_branch
    current_branch=$(git_current_branch)
    backup_branch="${current_branch}-backup-$(date +%Y%m%d%H%M%S)"

    if git branch "${backup_branch}"; then
        echo -e "Created backup branch: $(color "${backup_branch}" "${YELLOW_BOLD}")"
    else
        err "Could not create local backup branch ${backup_branch}"
        return 1
    fi
}

# @description (Git Cherry Pick)
# @params a list of commit hashes
# @example
#   gcp f42289b beac2af 57f4547
gcp() {
    git cherry-pick "$@"
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
    git stash list --pretty=format:"%gd - %h - %ci - %s" | sed 's/ [+-][0-9]\{4\}//g' && echo ''
}

# @description (Git Stash Drop) Delete one or more Git stash entries.
# @param $1 (optional) the zero-based index of the stash entry to drop, or the last one if no index is specified
# @option -n COUNT    Specify the number of stash entries to delete (default: 1)
# @example
#   gsd                 # Delete the latest stash entry
#   gsd 2               # Delete the stash entry at index 2
#   gsd -n 3            # Delete the 3 most recent stash entries
#   gsd 1 -n 4          # Delete 4 stash entries, starting from index 1
# /!\ Caution: this function permanently deletes stash entries. Use with care, as deleted stashes cannot be recovered.
gsd() {
    local index=0
    local count=1
    if [[ -n "${1}" && "${1}" != -* ]]; then
        index=$1
        shift
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--count)
                count="${2}"
                shift
                ;;
            *)
                err "Invalid parameter ${1}"
                echo "Usage: gsd [[index]] [[-n [quantity]]]"
                return 1
                ;;
        esac
        shift
    done

    for ((i=0; i<count; i++)); do
        if ! git stash drop stash@\{$index\} 2>/dev/null; then
            echo "No more stash entries to drop."
            break
        fi
    done
}

# @description (git stash rename) renames the latest stash entry
# @param $1 the new message to apply to this entry
# @example
#   gsr "New message"
gsr() {
    local message="${1}"

    has_uncommitted_changes && echo "Can not use gsr now: you have uncommitted changes" && return 1

    if [[ -z "${message}" ]]; then
        read -e -i "$(get_latest_stash_message)" -r -p "Enter new stash message: " message
    fi

    if git stash pop --quiet >/dev/null 2>&1 && \
       git add . >/dev/null 2>&1 && \
       git stash -m "${message}" --quiet >/dev/null 2>&1; then
        echo "Renamed latest stash entry to ${message}"
    else
        err "Could not renamed latest stash entry"
    fi
}

# Stash the current changes and apply them immediately, using the stash as a quick checkpoint
gsave() {
    local msg="${1:-latest state}"
    ! has_uncommitted_changes --quiet >/dev/null 2>&1 && err "Nothing to save; branch is clean" && return 1
    if git add . >/dev/null 2>&1 && \
       git stash -m "${msg}" --quiet >/dev/null 2>&1 && \
       git stash apply --quiet >/dev/null 2>&1; then
        echo "Changes saved"
    else
        err "Could not stash changes"
    fi
}

# git reset --soft a commit and stash it with the same commit message
# This is the opposite operation of grestore
# @param $1 (Optional) the number of commits to revert
# shellcheck disable=SC2120
grevert() {
    has_uncommitted_changes && err "Can not revert latest commit now: you have uncommitted changes" && return 1

    local count="${1:-1}"
    local msg
    for ((i = 0; i < count; i++)); do
        msg="$(git log -1 --pretty=format:%s)"
        echo "Reverting $(glast -is) ${msg}"
        grs > /dev/null && gas "${msg}" > /dev/null
    done
}

# the opposite operation of grevert
# apply the latest stash and commit it using the same message
# @param $1 (Optional) the number of commits to restore
# Note: we're using sed here to remove the On <branch_name>: prefix from the stash message
# shellcheck disable=SC2120
grestore() {
    has_uncommitted_changes && err "Can not restore latest commit now: you have uncommitted changes" && return 1

    local count="${1:-1}"
    local msg
    for ((i = 0; i < count; i++)); do
        msg="$(get_latest_stash_message)"
        if git stash pop --quiet >/dev/null 2>&1; then
            echo "Popped latest stash"
        else
            err "git stash pop failed"
        fi
        git add . >/dev/null 2>&1
        if git commit -m "${msg}" --quiet >/dev/null 2>&1; then
            echo "Commit restored on branch $(git branch --show-current) with message: $(glast -m)"
        else
            err "git commit failed"
        fi
    done
}

# Branch management

alias gck="git checkout" # <branch_name>
alias gckb="git checkout -b" # <branch_name>
alias gcb="git checkout -b" # <branch_name>
alias gb="git branch" # <branch_name>
alias gba="git branch -a"

# @description Delete the specified branch
# /!\ Be cautious when using this command, as it permanently removes the target local branch (and the
# remote if -a is specified), even if it is not fully merged.
# @param $1 The name of the branch to delete
# @flag -a, --all Also delete the remote branch
# @example
#   gbd branch-name
#   gbd branch-name -a
gbd() {
    local branch_name="${1}"
    local all="${2}"
    if [[ -z "${branch_name}" ]]; then
        err "A branch name is required. Usage: gbd [branch_name] [[-a,--all]]"
        return 1
    fi
    if git branch -D "${branch_name}" > /dev/null 2>&1; then
        echo "Deleted local branch ${branch_name}"
    else
        echo "No local branch ${branch_name}"
    fi
    if [[ "${all}" == "-a" || "${all}" == "--all" ]]; then
        if git push --delete origin "${branch_name}" > /dev/null 2>&1; then
            echo "Deleted remote branch ${branch_name}"
        else
            echo "No remote branch ${branch_name}"
        fi
    fi
}

# Permanently remove old, unreferenced commits
# /!\ Be cautious when using this command, as it permanently removes commits from your repository.
alias gpurge='git reflog expire --expire=now --all && git gc --prune=now'
# Discard ALL staged and unstaged changes
# /!\ Be cautious when using this command, as it permanently removes uncommitted changes.
alias gclear='git add . && git reset --hard HEAD'

##############################################################
# Maven
##############################################################

alias mct="mvn clean test"
alias mci="mvn clean install"
alias mcp="mvn clean package"

##############################################################
# Docker
##############################################################

# Visualization

alias dps="docker ps"
alias dpsa="docker ps -a"
alias dim="docker images"
alias dima="docker images -a"

dstatus() {
    echo -e "Images:\n"
    dim
    echo -e "\nContainers:\n"
    dpsa
}

# Build & Run

# @description (Docker Build Image). Builds an image from a Dockerfile
# @param $1 an arbitrary string to use as the image name
# @param $2 (optional) the directory where the Dockerfile is located (pwd by default)
dbi() {
    local image_name="${1}"
    local directory=${2:-.}
    docker build -t "${image_name}" "${directory}"
}

# @description (Docker Build Image Run). Builds an image from a Dockerfile and run a container
# @param $1 an arbitrary string to use as the image name
# @param $2 (optional) the directory where the Dockerfile is located (pwd by default)
dbir() {
    local image_name="${1}"
    dbi "$@"
    docker run "${image_name}"
}

# Management

alias dstop="docker stop" # <container_name_or_id>
alias dkill="docker kill" # <container_name_or_id>

# @description (Docker Clear) Stop and remove all docker containers and images except those specified
#              in ~/docker_config/keep_images and ~/docker_config/keep_containers
# @flag -f, --force  Forcefully stop all containers and remove images
# @example
#   dclr
#   dclr -f
#   dclr --force
dclr() {
    echo "Containers:"
    echo "  $(dps_clr "$@")"
    echo "Images:"
    echo "  $(dim_clr "$@")"
}

# @description (Docker Process Clear) Stop and remove all docker containers except those specified with
#              the --keep option (if provided)
# @flag -f, --force  Send a SIGKILL signal instead of a SIGTERM signal if present
# @flag -k, --keep  Stop, but do not remove these containers
# @example
#   dps_clr
#   dps_clr -k '6523983f0198 6c9a8765f2a4'
#   dps_clr -f
#   dps_clr -k '6523983f0198 6c9a8765f2a4' -f
dps_clr() {
    local keep=""
    local force=false
    local USAGE=$(cat <<EOF
Usage: dps_clr [OPTIONS]

Options:
  -k, --keep 'id_1 id_2 ...'  Specify container IDs to keep (space-separated).
  -f, --force                 Forcefully stop and remove containers.

Description:
  Stops and removes all Docker containers except those specified with the --keep option
  and those listed in \$DOCKER_KEEP_CONTAINERS_FILE (usually located at ${DOCKER_KEEP_CONTAINERS_FILE}).
EOF
)
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -k|--keep) keep="$2"; shift ;;
            -f|--force) force=true ;;
            *) echo "Unknown parameter: $1"; echo "${USAGE}"; return 1 ;;
        esac
        shift
    done
    # Read container IDs from ~/docker_config/keep_containers file
    local file_keep=""
    if [[ -f "${DOCKER_KEEP_CONTAINERS_FILE}" ]]; then
        file_keep=$(awk '{printf "%s%s", (NR>1?" ":""), $0}' "${DOCKER_KEEP_CONTAINERS_FILE}")
    fi
    # Combine file_keep and keep
    local all_keep="$file_keep $keep"
    readarray -t containers_to_stop < <(docker ps -q)
    local stop_count=${#containers_to_stop[@]}
    if [[ $stop_count -gt 0 ]]; then
        if $force; then
            docker kill "${containers_to_stop[@]}" >/dev/null 2>&1
        else
            docker stop "${containers_to_stop[@]}" >/dev/null 2>&1
        fi
    fi
    read -ra exclude <<< "$all_keep"
    readarray -t containers_to_remove < <(comm -23 <(docker ps -aq | sort) <(printf '%s\n' "${exclude[@]}" | sort))
    local remove_count=${#containers_to_remove[@]}
    if [[ $remove_count -gt 0 ]]; then
        docker rm "${containers_to_remove[@]}" >/dev/null 2>&1
    fi
    local keep_count=$(grep -c '[^[:space:]]' "${DOCKER_KEEP_CONTAINERS_FILE}")
    echo -e "Stopped: $(color "${stop_count}" "${GREEN}"), Removed: $(color "${remove_count}" "${GREEN}"), Kept: $(color "${keep_count}" "${GREEN}")"
}

# @description Remove all docker images except those specified with the --keep option (if provided)
# @flag -f, --force  Force removal of images
# @flag -k, --keep  Do not remove these image IDs
# @example
#   dim_clr
#   dim_clr -k 617f2e89852e
#   dim_clr -f
#   dim_clr -k '617f2e89852e 3a29986a9402' -f
dim_clr() {
    local keep=""
    local force=false
    local USAGE=$(cat <<EOF
Usage: dimg_clr [OPTIONS]

Options:
  -k, --keep 'id1 id2 ...'  Specify image IDs to keep (space-separated).
  -f, --force               Force removal of images.

Description:
  Removes all Docker images except those specified with the --keep option
  and those listed in \$DOCKER_KEEP_IMAGES_FILE (usually located at ${DOCKER_KEEP_IMAGES_FILE}).
EOF
)
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -k|--keep) keep="$2"; shift ;;
            -f|--force) force=true ;;
            *) echo "Unknown parameter: $1"; echo "${USAGE}"; return 1 ;;
        esac
        shift
    done
    # Read image IDs from ~/docker_config/keep_images file
    local file_keep=""
    if [[ -f "${DOCKER_KEEP_IMAGES_FILE}" ]]; then
        file_keep=$(awk '{printf "%s%s", (NR>1?" ":""), $0}' "${DOCKER_KEEP_IMAGES_FILE}")
    fi
    # Combine file_keep and keep
    local all_keep="$file_keep $keep"
    read -ra exclude <<< "$all_keep"
    readarray -t images_to_remove < <(comm -23 <(docker images -q | sort) <(printf '%s\n' "${exclude[@]}" | sort))
    local remove_count=${#images_to_remove[@]}
    if [[ $remove_count -gt 0 ]]; then
        docker rmi ${force:+-f} "${images_to_remove[@]}" >/dev/null 2>&1
    fi
    local keep_count=$(grep -c '[^[:space:]]' "${DOCKER_KEEP_IMAGES_FILE}")
    echo -e "Removed: $(color "${remove_count}" "${GREEN}"), Kept: $(color "${keep_count}" "${GREEN}")"
}

##############################################################
# Autocomplete
##############################################################

_complete_files() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    local files=$(compgen -f -- "$cur")
    COMPREPLY=( $(echo "$files" | while read -r f; do
        [[ -f "$f" ]] && echo "$f"
    done) )
}

_autocomplete_anonymize() {
    local cur prev words cword
    _init_completion || return
    case $prev in
        --file)
            _complete_files
            return
            ;;
    esac
    local opts="config --case-sensitive --file --message --help"
    COMPREPLY=($(compgen -W "$opts" -- "$cur"))
}

_autocomplete_git_branches_all() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    local branches=$(git for-each-ref --format='%(refname:short)' refs/heads/ refs/remotes/ refs/tags/)
    COMPREPLY=($(compgen -W "$branches" -- "$cur"))
}

_autocomplete_git_branches_local() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=($(compgen -W "$(git branch --format='%(refname:short)')" -- "$cur"))
}

for cmd in gcp gck gckb gbd gb gba; do
    complete -F _autocomplete_git_branches_all "${cmd}"
done

complete -F _command spy

complete -F _autocomplete_anonymize anonymize

if [[ -f "/usr/share/bash-completion/completions/git" ]]; then
    source "/usr/share/bash-completion/completions/git"
    __git_complete gwt _git_worktree
fi

##############################################################
# Custom ENV variables
##############################################################

if $PROMPT_TO_BOTTOM; then
    prompt_to_bottom() {
        tput cup $LINES
    }
    PROMPT_COMMAND=prompt_to_bottom
fi
