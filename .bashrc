# .bashrc

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

alias gitlg="git log --decorate --graph --oneline"
alias gitla="git log --decorate --graph --oneline --all"

alias gitlgm="git log --decorate --graph --oneline --author=david.letinaud-ext@alstomgroup.com"
alias gitlam="git log --decorate --graph --oneline --all --author=david.letinaud-ext@alstomgroup.com"
alias git_clean_dist="git checkout /home/dev/ouroboros/css/dist"

alias gita="git a -u && git reset $CSS_ROOT/dist"

alias gps_csw="(cd /home/dev/ouroboros/css/appli/top/ && make gps)"
alias gps_mw="(cd /home/dev/ouroboros/css/src/pikeos/middleware/core_main/ && make gps)"
alias cd_func="cd /home/dev/ouroboros/css/swint/functions/"
alias cd_csw="cd /home/dev/ouroboros/css/appli/top/"
alias cd_mw="cd /home/dev/ouroboros/css/src/pikeos/middleware/core_main/"
alias s_desinhib="cs_desinhib && cs_make_stimuli_file No_Test && cs_deploy_stimuli_file && cs_reset"
alias cs_who="cs_whogotrack | cut -b1-67"

alias cs_r="cs_reset"

stty -ixon
stty -ixoff

TEST_INDEX_CSV=/home/dev/ouroboros/css/appli/TRVRDZ105001526_Convergence_CSS_swint_test_index.csv

alias clear_all="clear && cs_tmux clear-history -t $TMUX_PANE"
alias pingrack="while true; do cs_ping_rack; done"
 
alias cs_all_clean_css="(cd_mw && make clean && make all clean) && (cd_csw && make clean) && (find ~/ -name '*.ali' -delete)"
# :n pou passer au suivant
alias fix='(cd $CSS_ROOT && vim $(git diff --name-only --diff-filter=U))'
alias tobeta1="cs_build_and_deploy_cs_common && cs_build_and_deploy_css && cs_build_and_deploy_css_gtw && cs_deploy_parameters_all && cs_deploy_fpga_bitstreams && cs_make_and_deploy_stimuli_file Btom_Fast_Fpga_Reload && cs_r && sleep 100 && cs_r && sleep 100 && cs_r"
