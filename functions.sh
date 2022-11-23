#!/usr/bin/env bash

cs_deploy_hash_file()
{
  cs_push ALL $CSS_BUILD_OUTPUT_DIR/hash_2oo3.bin /system/baseline/parameters/hash_2oo3.bin
}


find_usb()
{
    # rasp_ip=10.65.201.100
    # sshpass -p ubnt ssh ubnt@${VPN_SERVERS[conv1]} "echo dev|ssh
    # dev@$rasp_ip"

    lsblk_file=/tmp/lsblk.txt
    ls_usb_file=/tmp/lsusb.txt

    mv "$lsblk_file" "$lsblk_file.old"
    mv "$ls_usb_file" "$ls_usb_file.old"

    for rack in ${!VPN_SERVERS[@]}
    do
        cs_reserverack $rack -o
        for chan in A B C
        do
            echo "############################### $rack $chan
            ###############################" >> $lsblk_file
            echo "############################### $rack $chan
            ###############################" >> $ls_usb_file
            cs_ssh $chan lsblk >> $lsblk_file
            cs_ssh $chan lsusb >> $ls_usb_file
        done
        cs_freerack
    done
}

_is_usb_key_plugged()
{
  channel=$1

  if [ -z "$2" ]; then
    usb_dev="$2"
  else
    usb_dev="/dev/sda1"
  fi;

  cs_ssh "$channel" "test -e $usb_dev"
  return $?
}

cs_deploy_usb_key()
{
    usb_dir="/tmp/usb_tree/"
    usb_dev="/dev/sda1"

    for ch in $(_cs_local_get_enabled_channels)
    do
        _is_usb_key_plugged $ch $usb_dev
        if [[ $? -eq 0 ]]; then
            sshpass -p admin ssh admin@"$ch" "echo admin | sudo -S bash -c 'mkdir $usb_dir ; umount $usb_dev ; mount $usb_dev $usb_dir -o umask=000'"
            sshpass -p admin rsync -ruv "$usb_dir" "admin@$ch:$(dirname $usb_dir)"
        else
            error "No usb key found on channel $ch"
        fi;
    done
}

cs_restart_on_mmc()
{
  cs_restart_in_uboot;
  _parallel_run_for_all_channels "_cs_run_boot_mmc";
  echo "Waiting for all mmc boot end";

  _parallel_run_for_all_channels "cs_ssh" "true";
  if [[ $? -ne 0 ]]; then
      error "An error occured, at least one channel is not reachable";
      return 1;
  fi;
  success "All channels are reachable and booted from mmc"
}

cs_restart_on_usb()
{
    cs_restart_in_uboot;
    _parallel_run_for_all_channels "_cs_run_boot_usb";
    echo "Waiting for all usb boot end";

    _parallel_run_for_all_channels "cs_ssh" "true";
    if [[ $? -ne 0 ]]; then
        error "An error occured, at least one channel is not reachable";
        return 1;
    fi;
    success "All channels are reachable and booted from usb"
}

_cs_run_boot_mmc()
{
    channel="$1";
    _cs_run_bootcmd $channel "bootmmc"
    return $?
}

_cs_run_boot_usb()
{
    channel="$1";
    _cs_run_bootcmd $channel "bootusb"
    return $?
}

_cs_run_bootcmd()
{
    channel="$1";
    bootcmd="$2";

    _cs_get_serial_id "${channel^^}" || return 1;
    rasp_command="
    echo \"run $bootcmd\" > \"$serial_id\";
    echo \"\" > \"$serial_id\";
    sleep 5;
    echo \"run $bootcmd\" > \"$serial_id\";
    echo \"\" > \"$serial_id\";
    ";
    cs_ssh $COMPUTER "$rasp_command";
    if [[ $? -ne 0 ]]; then
        error "Error in cs_ssh of ${FUNCNAME[0]} of channel $channel";
        return 1;
    fi;
    success "kernel $bootcmd has started on channel $channel";
    return 0
}


rb2 ()
{
    CURRENT_SHA=$(git rev-parse HEAD);
    CURRENT_BRA=`git rev-parse --abbrev-ref HEAD`;
    reviewboard $@ -g auto $(git merge-base $CURRENT_BRA 2.0.x)..$CURRENT_SHA
}

git_merge(){
  BRANCH=$1

  swint_branch="2.0.x"
  git_c_run
  git stash
  # check if branch exists
  git c "$BRANCH"
  git c $swint_branch
  git pull origin $swint_branch
  git merge --no-ff -
  info "On branch: " $swint_branch
  git log -n 1
  #git push

  # merge sur master
  git c master
  git pull origin master
  git c -b "$BRANCH"_master
  # Be careful, merge-base is not the previous merge, use the commit before the last merge with '^'
  git cherry-pick --abort
  git cherry-pick $(git merge-base $BRANCH $swint_branch^)..$BRANCH
  git c master
  git merge --no-ff -
  info "On branch: master"
  git log -n 1
  #git push
  git stash pop
}

cd_conf_dir()
{
  cd $(_cs_get_conf_dir)
}

################################################################################
# For test execution
###
PYTEST_DIR="$CSS_ROOT/swint/functions/inputs_outputs"
ADATEST_DIR="$CSS_ROOT/appli/csw/src/inputs_outputs"

swint() {
    cmd=$1
    shift # shift function parameters ($1:=$2, $2:=$3, etc..)

    case "$cmd" in
        rectify)
            list=$(grep -hoe "TC_CSS_Manage_${1^^}_[0-9][0-9][0-9][0-9]" $2 | sort | uniq)
            for tc in $list; do

                if ! grep -re $tc $PYTEST_DIR/automatisation/TS*.py &> /dev/null; then
                    echo $tc not implemented
                fi
            done
            ;;
        search)
            grep -iE $* -- $CSS_ROOT/appli/swint_test_index.csv
            ;;
        check)
            if [ "$1" == "stimuli" ]; then
                _check_stimuli_swint;
                return $?;
            fi;
            ;;
        *)
            error "swint (search) pattern_of_test"
            return 1
    esac
}

log() {
    cmd=$1
    shift # shift function parameters ($1:=$2, $2:=$3, etc..)

    case "$cmd" in
        show)
            _show_log $*
            ;;
        analyze)
            _analyze_log $*
            ;;
        save)
            _save_log $*
            ;;
        restore)
            _restore_log $*
            ;;
        extract)
            _extract_log $*
            ;;
        *)
            error "log  (show | analyze | save | restore) pattern_of_test"
            return 1
    esac
}

_check_stimuli_swint() {
    res=""

    for i in {A..C};
    do
        {
            cs_ssh $i "umount /dev/mmcblk0p1";
            cs_ssh $i "mount -o sync /dev/mmcblk0p1 /mnt";
            cs_pull $i /mnt/swint_stimulis.bin /tmp/tmp_stimuli.bin;
            cs_ssh $i "umount /dev/mmcblk0p1";
            diff /tmp/tmp_stimuli.bin $STIMULI_BIN &> /dev/null
            if [ $? ]; then
                res=$(echo $res"[WARNING] STIMULI_FILE different on channel $i !\n");
            fi;
        } #2> /dev/null;
    done;

    if [ "$res" == "" ]; then
        return 0;
    else
        echo -e $res | sed '$ d';
        return 1;
    fi;
}

catlog() {
    CHANNEL_FOR_EXE=${2:-"a"}
    LOOP_FOR_EXE=${3:-"short_loop"}
    UNSTRIPPED_EXE="$CSS_ROOT/dist/css-pool/pikeos-native/object/${CHANNEL_FOR_EXE,,}/${LOOP_FOR_EXE}.unstripped";
    head -n -0 $1 | awk -v unstripped_exe=$UNSTRIPPED_EXE -f $AWK_CONFIG_FILE | sed 's/^.* \[//g' | less -R
}

_show_log() {
    log_dir="$PYTEST_DIR/automatisation/results"

    if [ -z $1 ] || [ -z $2 ] ; then
        echo $*
        error "Usage: show_result <Chaine_Name> <LoopName> [savedir]"
        error "       Chaine_Name : A, B, C"
        error "       LoopName: sl, ml"
        error "       savedir: savedlog directory:"
        return 1
    fi

    if [ $3 ] ; then
        log_dir=/tmp/savedlog/$3
    fi

    log_name=$(find $log_dir/*${1^^}_var_log_css_${2,,}.log | sed "s/.*\///")
    head -n -0 $log_dir/$log_name | awk -f $AWK_CONFIG_FILE | less -R
    return 0;
}

_analyze_log() {
    analyze_dir="analyze"

    if [ -z $1 ] ; then
        error "Usage: analyze_test patterne_of_test"
        return 1
    fi

    _pushd $PYTEST_DIR

    _save_log $analyze_dir
    make hwsw_ts TESTS="-k $1 -s ${2:-'--runxfail'}" LOGS_SAVED=/tmp/savedlog/$analyze_dir

    _popd
    return 0
}

_save_log() {
    savedlog_dir=/tmp/savedlog/$1

    _pushd $PYTEST_DIR/automatisation/results
    mkdir -p $savedlog_dir

    # look for *.log files
    find *.log &> /dev/null
    if [ $? -eq 0 ]; then
        cp *.log $savedlog_dir
    fi

    _popd
}

_restore_log() {
    _pushd /tmp/savedlog/$1

    # look for *.log files
    find *.log &> /dev/null
    if [ $? -eq 0 ]; then
        cp *.log $PYTEST_DIR/automatisation/results/
    fi

    _popd
}

_extract_log() {
    extract_dir="/tmp/extrat_log"
    file=$(readlink -f $1)

    rm -rf $extract_dir && mkdir -p $extract_dir

    ( cd $extract_dir && tar -xf $file && tar -xf $extract_dir/*.tar.gz )
    rm -rf $PYTEST_DIR/automatisation/results/*.log
    cp $extract_dir/*.log $PYTEST_DIR/automatisation/results/
}


_try_ping_rack() {
    ret=0

    for channel in a b c; do
        _cs_ping $channel
        ret=$(($ret + $?))
    done

    if [ $ret -eq 0 ]; then
        return $ret
    fi

    echo "Do you want restart the rack (all channels) ?"
    select ans in "yes" "no"; do
        case $ans in
            yes)
                cs_reset
                echo wait for 55s
                sleep 55
                _try_ping_rack
                return $?
                ;;
            no)
                return $ret
                ;;
        esac
    done
}

run_test() {

    if ! _try_ping_rack; then
        return 1
    fi

    if [ -z "$RACK_NAME" ] || [ -z "$RACK_TYPE" ]; then
        _cs_set_rack_type
    fi

    cd $PYTEST_DIR
    make hwsw_run TESTS="-k $1 -s" NO_CONF=1 ${2:-}
    cd -

}

rm_proxy_env() {
    export HTTP_PROXY=""
    export HTTPS_PROXY=""
    export http_proxy=""
    export https_proxy=""
}

################################################################################
# Wait for a free rack
###

_misc_print_all_bash() {
    for i in $(ps hf -opid -C bash) ; do
        if [ "$i" != "$$" ]; then
            echo $1 > /proc/$i/fd/0;
        fi;
    done;
}

cs_be_alone()
{
    _cs_remote_free_rack $RACK_NAME
}

cs_waitfor () {
    # [VARIABLES]
    rack=$1;

    # [START]
    if [ -z $rack ]; then
        echo "Usage: cs_waitfor rackName [sleepFrequency]" 1>&2
        return 1;
    fi;

    while [ "$(cs_whogotrack | grep "$rack " | sed -e "s/$rack//" -e 's/ \+//' | awk '{ print $1 }')" != "" ]; do
        sleep ${2:-"1"};
    done;

    # [END]
    return 0
}


cs_getfreerack() {
    # [VARIABLES]
    racklist=$(cs_whogotrack | sed -e 's/ [^ ]*//4g' -e 's/ *//')
    found=""

    # [START]
    for rack in $racklist ; do
        if [ "$(cs_whogotrack | grep "$rack " | sed -e "s/$rack//" -e 's/ \+//' | awk '{ print $1 }')" == "" ] ; then
            found=$rack
        fi
    done

    echo -n $found

    # [END]
    return 0
}

cs_shotgun() {
    # [VARIABLES]
    rack=$1

    # [START]
    if [ -z $rack ] ; then
        while [ "$rack" == "" ] ; do
            rack=$(cs_getfreerack)
            sleep ${2:-"1"}
        done
    else
        cs_waitfor $rack &> /dev/null
    fi

    _misc_print_all_bash "[NOTE] $rack is available !"
    cs_reserverack $rack

    # [END]
    return 0
}

cs_update_core_main_pb() {
    cd ~/Documents/ouroboros/css/src/pikeos/middleware/pikeosal_highpriv/
    make update_vmit_mod
    cd -
    # [END]
    return 0
}

cs_make_and_deploy_stimuli_file() {
    cs_make_stimuli_file $1 && cs_deploy_stimuli_file
}

cs_switch() {
    rdu_tag="rdu"
    vsv_tag="vsv"


    if [[ "$1" != "$rdu_tag" && "$1" != "$vsv_tag" ]]; then
        echo -e "usage:\tcs_switch <tag>"
        echo -e "\tallowed tags: 'vsv' & 'rdu'"
        return 1
    fi

    if [[ ! $(diff ~/.gitconfig.$1 ~/.gitconfig) ]]; then
        echo "The current configuration is already set for $1"
        return 0
    fi

    pkill ssh-agent
    if [[ "$1" == "$rdu_tag" ]]; then
        . ~/Documents/ouroboros/.envrc css
        ssha &> /dev/null
        ssha
    else
        . ~/sandbox/vsv/.envrc css
        ssha_vsv &> /dev/null
        ssha_vsv
    fi

    cp ~/.rbtools-cookies.$1 ~/.rbtools-cookies
    cp ~/.gitconfig.$1 ~/.gitconfig

    return 0


}

cs_clean_css() {
    GO2APPLI="cd ${CSS_ROOT}/appli/top"
    GO2DEMO="cd ${CSS_ROOT}/demo/top"
    GO2MW="cd ${CSS_ROOT}/src/pikeos/middleware/core_main"

    ($GO2APPLI && make clean)
    ($GO2DEMO && make clean)
    ($GO2MW && make clean_custom_pike)
    ($GO2MW && make full-clean)
    (cs_poky && cd ${CSS_ROOT}/src/linux && make clean)
}

################################################################################
# Joris Less
###
# 1)fetch and analyze log locally
cs_less(){
    if [ -z "$1"  ] || [ -z "$2" ]
    then
        error "Usage : ${FUNCNAME[0]} [A, B, C] [sl, ml,...]";
        return;
    fi
    ####### one channel analyze
    if [ $1 = "A" ] || [ $1 = "B"  ] || [ $1 = "C" ]; then
        _cs_fetch_css $1 $2;
        cs_local_analyze $1 $2;
    else
        error "Usage : ${FUNCNAME[0]} [A, B, C]";
    fi;
}

# 2) fetch the short loop log into ~/local_log
_cs_fetch_css(){
    if [ -z "$1"  ]
    then
        error "Usage : ${FUNCNAME[0]} [A, B, C] [sl, ml,...]";
        return;
    fi
    mkdir -p /tmp/local_log;
    rm  -f /tmp/local_log/css_$2.log.lastrun.$1;
    _cs_ping $1 && cs_pull $1 /var/log/css_$2.log /tmp/local_log/css_$2.log.lastrun.$1 || continue;
}

# 3) analyze log locate into ~/local_log with less
cs_local_analyze(){
    if [ -z "$1"  ]
    then
        error "Usage : ${FUNCNAME[0]} [A, B, C, /path/to/log] [sl, ml,...]";
        return;
    fi
    if [ $1 = "A" ] || [ $1 = "B"  ] || [ $1 = "C" ]; then
        head -n -0 /tmp/local_log/css_$2.log.lastrun.$1  | awk -f $AWK_CONFIG_FILE | less -R;
    else
        head -n -0 $1  | awk -f $AWK_CONFIG_FILE | less -R;
    fi;
}

greprei() {
    grep -re $1 --include="${2:-*}"
}

################################################################################
# Misc
###
_pushd() {
    pushd $* > /dev/null
}
_popd() {
    popd $* > /dev/null
}

