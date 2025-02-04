# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

_linx_autocomplete() {
    local cur prev words cword
    _init_completion || return

    local verbs="config cron backup sync"

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

complete -F _linx_autocomplete linx
