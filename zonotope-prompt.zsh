############################################################################
# initialize prompt system                                                 #
############################################################################

## enable the prompt subsystem
setopt PROMPT_SUBST

## enable prompt colors
autoload -U colors && colors

############################################################################
# initialize vcs_info (only git for now)                                   #
############################################################################

## load vcs_info module
autoload -Uz vcs_info

## enable the git vcs_info back end
zstyle ':vcs_info:*' enable git

## check for local changes
zstyle ':vcs_info:*' check-for-changes true

## build the status message before rendering the prompt
precmd() {
    vcs_info
}

# rebuild the status message when changing directories
prompt_chpwd() {
    FORCE_RUN_VCS_INFO=1
}
add-zsh-hook chpwd prompt_chpwd

############################################################################
# vcs theme                                                                #
############################################################################

## show a marker whenever there are either staged or unstaged changes
zstyle ':vcs_info:*:*' unstagedstr "*"
zstyle ':vcs_info:*:*' stagedstr "^"

## set prompt git status message format
zstyle ':vcs_info:git*' formats "(%b%c%u%m)"
zstyle ':vcs_info:git*' actionformats "(%b%c%u%m|%a)"

## show ↑n/↓n when the local branch is ahead/behind remote HEAD
function +vi-git-st() {
    if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]]; then
        local ahead behind
        local -a commits

        # unpushed commits
        ahead=$(git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null |
                    wc -l | tr -d '[:space:]')

        (( $ahead )) && commits+=( "↑${ahead}" )


        # unpulled commits
        behind=$(git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null |
                     wc -l | tr -d '[:space:]')

        (( $behind )) && commits+=( "↓${behind}")


        # commit status
        if [ ${#commits[@]} -gt 0 ]; then
            hook_com[misc]+=" ${(j:/:)commits}"
        fi
    fi
}

## show "_" when there are untracked files
+vi-git-untracked(){
    if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
           git status --porcelain | grep '??' &> /dev/null ; then
        hook_com[unstaged]+='-'
    fi
}

## set the prompt hooks
zstyle ':vcs_info:git*+set-message:*' hooks git-st git-untracked

############################################################################
# prompt                                                                   #
############################################################################

## red username for root, cyan for everyone else
if [ $UID -eq 0 ]; then NCOLOR="red"; else NCOLOR="cyan"; fi

## main prompt. 3 lines:
# 1. dividing line of dashes (-)
# 2. username@hostname:working/directory/ (possible git status)
# 3. %/# >
PROMPT=$'
%{$fg_bold[grey]%}%
-------------------------------------------------------%
%{$reset_color%}
%{$fg[$NCOLOR]%}%n%{$reset_color%}@%{$fg[magenta]%}%m%{$reset_color%}:%
%{$fg[blue]%}%~%{$reset_color%} %
%{$fg_bold[black]%}${vcs_info_msg_0_}%{$reset_color%}
%{$fg_bold[black]%}%# >%{$reset_color%} '

## loop/multi-line command prompt
PROMPT2="%{$fg_bold[black]%}%_> %{$reset_color%}"

## selection prompt
PROMPT3="%{$fg_bold[black]%}...> %{$reset_color%}"
