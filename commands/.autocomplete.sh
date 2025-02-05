# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

##############################################################
# Helper
##############################################################

_list_tag_names() {
    git for-each-ref --sort=creatordate --format='%(refname:short)' refs/tags | tr '\n' ' ' | sed 's/ $//'
}

_linx_autocomplete_tags() {
    local opts="$(_list_tag_names) --help"
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
}

_git_contributors_matching() {
  local subject="${1}"
  git log --format='%aN <%aE>' | awk -F'[<>]' -v substring="${subject}" '
BEGIN { IGNORECASE = 1 }
{
    name = $1; email = $2;
    if (tolower(name) ~ "^" tolower(substring) || tolower(email) ~ "^" tolower(substring)) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", name);  # Trim whitespace
        print name;
    } else if (tolower(name) ~ "^" tolower(substring)) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", name);  # Trim whitespace
        print name;
    } else if (tolower(email) ~ "^" tolower(substring)) {
        print email;
    }
}' | sort -u
}

##############################################################
# Autocomplete
##############################################################

_linx_autocomplete() {
    local cur prev words cword
    _init_completion || return

    case $prev in
        cron)
            local opts="--clear --delete --help"
            COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
            return
            ;;
        sync)
            local opts="--backup --help"
            COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
            return
            ;;
        backup)
            local opts="--help"
            COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
            return
            ;;
    esac

    if [[ $cword -eq 1 ]]; then
        local verbs="config cron backup sync --help"
        local opts="--commands --dir --info --version --help"
        COMPREPLY=($(compgen -W "${verbs} ${opts}" -- "${cur}"))
    fi
}

_timestamp_autocomplete() {
    local cur prev words cword
    _init_completion || return

    local opts="--iso --basic --readable --separators --help"

    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
}

_gtag_autocomplete() {
    local cur prev words cword
    _init_completion || return

    case $prev in
        create)
            _linx_autocomplete_tags
            return
            ;;
        delete)
            _linx_autocomplete_tags
            return
            ;;
    esac

    if [[ $cword -eq 1 ]]; then
        local verbs="create delete"
        local opts="--help"
        COMPREPLY=($(compgen -W "${verbs} ${opts}" -- "${cur}"))
    fi
}

_mkf_autocomplete() {
    local cur prev words cword
    _init_completion || return

    case $prev in
        config)
            local verbs="read put"
            local opts="--list --path --help"
            COMPREPLY=($(compgen -W "${verbs} ${opts}" -- "${cur}"))
            return
            ;;
        template)
            local verbs="read put rm"
            local opts="--list --path --help"
            COMPREPLY=($(compgen -W "${verbs} ${opts}" -- "${cur}"))
            return
            ;;
    esac

    if [[ $cword -eq 1 ]]; then
        local verbs="config template"
        local opts="--basic --content --extension --name --open --time --template --help"
        COMPREPLY=($(compgen -W "${verbs} ${opts}" -- "${cur}"))
    fi
}

_port_autocomplete() {
    local cur prev words cword
    _init_completion || return

    local opts="kill --pid --pname --port --help"

    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
}

_cpv_autocomplete() {
    local cur prev words cword
    _init_completion || return

    local opts="--quiet --help"

    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
}

_rename_autocomplete() {
    local cur prev words cword
    _init_completion || return

    case $prev in
        --mode)
            local values="dry-run execute interactive"
            COMPREPLY=($(compgen -W "${values}" -- "${cur}"))
            return
            ;;
        --as)
            local values="c m t i d"
            COMPREPLY=($(compgen -W "${values}" -- "${cur}"))
            return
            ;;
        --sort)
            local values="c m n t s"
            COMPREPLY=($(compgen -W "${values}" -- "${cur}"))
            return
            ;;
    esac

    if [[ $cword -eq 1 ]]; then
        local opts="--as --sort --ignore-extension --recursive --mode --help"
        COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    fi
}

_backup_autocomplete() {
    local cur prev words cword
    _init_completion || return

    if [[ $cword -eq 1 ]]; then
        COMPREPLY=( $(compgen -f -- "$cur") )
    elif [[ "${prev}" =~ "--destination" ]]; then
        COMPREPLY=( $(compgen -d -- "$cur") )
    else
        local a="--destination --basic --reverse --time --only-compact --no-extension"
        local b="--no-name --cron --verbose --erase --instantly --quiet --help"
        local opts="${a} ${b}"

        COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    fi
}

_term_autocomplete() {
    local cur prev words cword
    _init_completion || return

    case $prev in
        p|profiles)
            local values="--get --set"
            COMPREPLY=($(compgen -W "${values}" -- "${cur}"))
            return
            ;;
        l|layouts)
            local values="--get --set"
            COMPREPLY=($(compgen -W "${values}" -- "${cur}"))
            return
            ;;
    esac

    if [[ $cword -eq 1 ]]; then
        local verbs="profiles layouts"
        local opts="--help"
        COMPREPLY=($(compgen -W "${verbs} ${opts}" -- "${cur}"))
    fi
}

_glot_autocomplete() {
    local cur prev words cword
    _init_completion || return

    if [[ "${prev}" == --branch || "${prev}" == -b ]]; then
        local branches=$(git for-each-ref --format='%(refname:short)' refs/heads/ refs/remotes/ refs/tags/)
        COMPREPLY=($(compgen -W "$branches" -- "$cur"))
    elif [[ "${prev}" == --filter || "${prev}" == -f ]]; then
        cur="${COMP_WORDS[COMP_CWORD]}"
        local values=()
        mapfile -t values < <(_git_contributors_matching "${cur}")

        if [[ ${#values[@]} -eq 0 ]]; then
            COMPREPLY=()
        else
            local matches=()
            for value in "${values[@]}"; do
                if [[ "${value,,}" == "${cur,,}"* ]]; then
                    if [[ "$value" == *" "* ]]; then
                        matches+=("\"$value\"")
                    else
                        matches+=("$value")
                    fi
                fi
            done

            if [[ ${#matches[@]} -gt 0 ]]; then
                COMPREPLY=("${matches[@]}")
            else
                COMPREPLY=("${values[@]}")
            fi

            if [[ ${#COMPREPLY[@]} -gt 1 ]]; then
                compopt -o nospace
                COMPREPLY=("${COMPREPLY[@]/%/ }")
            fi
        fi
    else
        local opts="--filter --branch --asc --today --minimal --help"
        COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    fi
}

complete -F _glot_autocomplete glot
complete -F _term_autocomplete term
complete -F _backup_autocomplete backup
complete -F _rename_autocomplete rename
complete -F _cpv_autocomplete cpv
complete -F _port_autocomplete port
complete -F _mkf_autocomplete mkf
complete -F _gtag_autocomplete gtag
complete -F _timestamp_autocomplete timestamp
complete -F _linx_autocomplete linx
