# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

##############################################################
# Helper
##############################################################

_list_tag_names() {
    git for-each-ref --sort=creatordate --format='%(refname:short)' refs/tags | tr '\n' ' ' | sed 's/ $//'
}

##############################################################
# Autocomplete
##############################################################

_linx_autocomplete() {
    local cur prev words cword
    _init_completion || return

    local verbs="config cron backup sync --help"

    if [[ $cword -eq 1 ]]; then
        local opts="--commands --dir --info --version --help"
        COMPREPLY=($(compgen -W "${verbs} ${opts}" -- "${cur}"))
    elif [[ ${words[1]} == "cron" && $cword -eq 2 ]]; then
        if [[ ! ${words[*]} =~ --clear|--delete|--help ]]; then
            local opts="--clear --delete --help"
            COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
        fi
    elif [[ ${words[1]} == "sync" && $cword -eq 2 ]]; then
        if [[ ! ${words[*]} =~ --backup|--help ]]; then
            local opts="--backup --help"
            COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
        fi
    elif [[ ${words[1]} == "backup" && $cword -eq 2 ]]; then
        if [[ ! ${words[*]} =~ --help ]]; then
            local opts="--help"
            COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
        fi
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

    if [[ $cword -eq 1 ]]; then
        local verbs="create delete"
        local opts="--help"
        COMPREPLY=($(compgen -W "${verbs} ${opts}" -- "${cur}"))
    elif [[ ${words[1]} == "create" && $cword -eq 2 ]]; then
        if [[ ! ${words[*]} =~ --* ]]; then
            local opts="$(_list_tag_names) --help"
            COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
        fi
    elif [[ ${words[1]} == "delete" && $cword -eq 2 ]]; then
        if [[ ! ${words[*]} =~ --* ]]; then
            local opts="$(_list_tag_names) --help"
            COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
        fi
    fi
}

_mkf_autocomplete() {
    local cur prev words cword
    _init_completion || return

    if [[ $cword -eq 1 ]]; then
        local verbs="config template"
        local opts="--basic --content --extension --name --open --time --template --help"
        COMPREPLY=($(compgen -W "${verbs} ${opts}" -- "${cur}"))
    elif [[ ${words[1]} == "config" && $cword -eq 2 ]]; then
        if [[ ! ${words[*]} =~ --* ]]; then
            local verbs="read put"
            local opts="--list --path --help"
            COMPREPLY=($(compgen -W "${verbs} ${opts}" -- "${cur}"))
        fi
    elif [[ ${words[1]} == "template" && $cword -eq 2 ]]; then
        if [[ ! ${words[*]} =~ --* ]]; then
            local verbs="read put rm"
            local opts="--list --path --help"
            COMPREPLY=($(compgen -W "${verbs} ${opts}" -- "${cur}"))
        fi
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

complete -F _rename_autocomplete rename
complete -F _cpv_autocomplete cpv
complete -F _port_autocomplete port
complete -F _mkf_autocomplete mkf
complete -F _gtag_autocomplete gtag
complete -F _timestamp_autocomplete timestamp
complete -F _linx_autocomplete linx
