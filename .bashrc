# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific aliases and functions# Run twolfson/sexy-bash-prompt
. ~/.bash_prompt
shopt -s direxpand
source ~/ouroboros/.envrc css
source ~/functions.sh
export DISPLAY=localhost:10.0

# Gagner du temps sur les compilations
export FAST_GENERATION=1
export DISABLE_DIVERSIFICATION=1

alias full_reset='exec -c env HOME=/home/dev TERM=screen bash -il'
alias gita='git add -u && git reset ~/ouroboros/css/dist/'

alias gitlg="git log --decorate --graph --oneline --pretty=format:%C(yellow)%h%C --date=short"
alias gitla="git log --decorate --graph --oneline --all"

alias gitlgm="git log --decorate --graph --oneline --author=david.letinaud-ext@alstomgroup.com"
alias gitlam="git log --decorate --graph --oneline --all --author=david.letinaud-ext@alstomgroup.com"


alias gps_csw="(cd /home/dev/ouroboros/css/appli/top/ && make gps)"
alias gps_mw="(cd /home/dev/ouroboros/css/src/pikeos/middleware/core_main/ && make gps)"
alias cd_func="cd /home/dev/ouroboros/css/swint/functions/"
alias cd_csw="cd /home/dev/ouroboros/css/appli/top/"
alias cd_mw="cd /home/dev/ouroboros/css/src/pikeos/middleware/core_main/"
alias cd_reprog_func='cd /home/dev/ouroboros/reprog/swint/functions/'

alias git_c_run='git c /home/dev/ouroboros/css/dist/integration'
alias clear_all='clear && tmux clear-history -t $TMUX_PANE'
export PROMPT_COMMAND="echo -n \[$(date +%H:%M:%S)\]"
RB_TOKEN_BASHRC="ebde88f1ebaedad9d2ee7a8899435bba7230d46a"

#git config --global alias.lad "log --all --graph --pretty=format:'%Cgreen%ad%Creset %C(auto)%h%d %s %C(bold black)<%aN>%Creset' --date=format-local:'%Y-%m-%d %H:%M (%a)'"

alias cs_who="cs_whogotrack | cut -b1-67"
alias cs_r="cs_reset"

TEST_INDEX_CSV=/home/dev/ouroboros/css/appli/TRVRDZ105001526_Convergence_CSS_swint_test_index.csv

alias clear_all="clear && cs_tmux clear-history -t $TMUX_PANE"
alias pingrack="while true; do cs_ping_rack; done"

alias cs_all_clean_css="(cd_mw && make clean && make all clean) && (cd_csw &&
    make clean) && (find ~/ -name '*.ali' -delete)"
# :n pou passer au suivant
alias fix='(cd $CSS_ROOT && vim $(git diff --name-only --diff-filter=U))'
