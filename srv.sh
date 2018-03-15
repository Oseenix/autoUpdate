#!/bin/bash
#
# @file autoUpdate.sh
#
# @version 1.0
# @date 2018-03-15
# server 上执行的默认脚本：删除lib，解压覆盖旧版本文件
#

fail_log() {
    echo "Fail:$1"
    echo "Usage:`basename $0` <agent_file_name>"
    exit 1
}

# 自动升级程序依赖log中"Final success"关键字判断成功
success_log() {
    echo "Final success."
    exit 0
}

dir_name=`dirname $0`

if [ "$#" -lt "1" ]; then
    fail_log "Please pass the agent file name, like: bonree-v**.zip"
fi

agent_file="$dir_name/$1"

if [ ! -f $agent_file ]; then
    fail_log "$agent_file is not a valid file"
fi

if [ ! -r $agent_file ]; then
    fail_log "$agent_file is not a readable file"
fi

rm -rf $dir_name/lib
unzip -o $dir_name/$1 -d $dir_name

success_log

exit 0

