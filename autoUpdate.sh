#!/bin/bash
#
# @file autoUpdate.sh
#
# @version 1.0
# @date 2018-03-15
#
# 依赖：expect openssh-clients
# CentOS下 yun install -y expect openssh-clients
#

DIRNAME=`dirname $0`
WHOAMI=`whoami`

#配置文件行格式
cfg_format=" host,port,user,passwd,agent_install_dir"

# 打印使用说明
usage() {
    echo "This script upload an agent zip file and a <srv_script> to all"
    echo "hosts listed in <cfg_file>, and run <srv_script> on all hosts"
    echo "Usage:`basename $0` -f <cfg_file> -a <agent_file> [-r <srv_script>,default:srv.sh] [-h print this help] "
    echo "Each line in <cfgFile> should like: $cfg_format"
    exit $1
}

# debug 打印函数，打印标记sh_dbg设置时打印
sh_dbg=1
dbg_echo(){
  if [ ! -z $sh_dbg  ]; then
    echo "$1"
  fi
}

# 检查文件是否存在
file_check() {
    if [ ! -r $1 ]; then
        echo "$1 can't be accessed! check file!"
        usage 1
    fi
}

# 解析校验配置文件
# 有效主机配置数量
host_num=0

parse_cfgfile() {
    file_check $1

    awk 'BEGIN {FS="[, :]"} /^[^#]/ {if (NF != 5) print "The "NR"th host cfg item is invalid: "$0}' $1
    #awk 'BEGIN {FS="[, :]"} /^[^#]/ {if (NF == 5) {++x;print "host"x"=( "$1,$2,$3,$4,$5" );"}} END {print "host_num="x";"}' $1
    eval $(awk 'BEGIN {FS="[, :]"} /^[^#]/ {if (NF == 5) {++x;print "host"x"=( "$1,$2,$3,$4,$5" );"}}  END {print "host_num="x";"}' $1)

    echo "host1:"${host1[@]}

    echo "Valid config item number:"$host_num

    if [ "$host_num" -eq 0 ];then
        echo "The cfgFile:$cfg_file do not contain valid host config item."
        echo "Please check the config file format!"
        usage 1
    fi
}

while getopts ":f:ha:r:" Option
do
    case $Option in
        f   ) echo "Config file: - $OPTARG -"
            cfg_file=$OPTARG
            parse_cfgfile $cfg_file
            ;;
        a   ) echo "Agent file: - $OPTARG -"
            file_check $OPTARG
            agent_file=$OPTARG
            agent_basename=`basename $OPTARG`
            ;;
        r   ) echo "Remote runScriptFile: - $OPTARG -"
            file_check $OPTARG
            run_on_srv_script=$OPTARG
            ;;
        h   ) usage 0
            ;;
        \?  ) echo "Unimplement option: $Option"
            usage 1
            ;;
    esac
done

# 参数判断
if [ -z $cfg_file ]; then
    usage 1
fi

if [ -z $agent_file ]; then
    usage 1
fi

if [ -z $run_on_srv_script ];then
    run_on_srv_script="$DIRNAME/srv.sh"
    file_check $run_on_srv_script
fi
run_on_srv_basename=`basename $run_on_srv_script`


host_operate() {
    if [ "$#" -ne "5" ]; then
        echo "The host param is invalid: $*"
        return
    fi
    echo "Operate host params:$*"

    lc_host=$1;lc_port=$2;lc_user=$3;lc_passwd=$4;
    lc_dst_dir=$5

    expect_script="$1-$2-$3.exp"

    cat > $expect_script<< end_of_message
# Upload上传
spawn scp -r -P $lc_port -o StrictHostKeyChecking=no $agent_file $run_on_srv_script $lc_user@$lc_host:$lc_dst_dir
set timeout 60
expect {
    # 普通密码登陆
    "*assword*" {
        send "$lc_passwd\n\n"
        expect {
            # 密码错误
            "*assword*" {
                puts "Password error!"
                exit 1
            }

            # 出错
            "*No such file*" {
                puts "The dir:$lc_dst_dir or upload files is no exsist."
                exit 1
            }

            # 传完直接到本地提示符
            "*$WHOAMI@*" {
                send "\n\n"
            }
        }
    }

    # sshkey免密登陆如有ssh-key密码,不考虑作为key密码错误后作为主机密码
    "*passphrase for key*" {
        send "$lc_passwd\n"
        expect {
            # 第一次key密码错误
            "*passphrase for key*" {
                puts "Password error!"
                exit 1
            }
            # 出错
            "*No such file*" {
                puts "The dir:$lc_dst_dir or upload files is no exsist."
                exit 1
            }

            # 免密直接到本地提示符
            "*$WHOAMI@*" {
                send "\n\n"
            }
        }
    }

    # 出错
    "*No such file*" {
        puts "The dir:$lc_dst_dir or upload files is no exsist."
        exit 1
    }

    # 免密直接到本地提示符
    "*$WHOAMI@*" {
        send "\n\n"
    }

    # ip/port 错误
    "No route to host" {
        puts "connecting to $lc_host error: No route, invalid IP/Port"
        exit 1
    }

    # 超时
    timeout {
        puts "time out!"
    }
}

# 登陆执行
spawn ssh -o StrictHostKeyChecking=no -p $lc_port $lc_user@$lc_host

# xxx Redundancy scp校验通过后下列登陆校验均冗余
expect {
    # 普通密码登陆
    "*assword*" {
        send "$lc_passwd\n\n"
        expect {
            # 密码错误
            "*assword*" {
                puts "Password error!"
                exit 1
            }

            # Server登陆提示符
            "*$lc_user@*" {
                send "\n"
            }
        }
    }

    # sshkey免密登陆如有ssh-key 密码
    "*passphrase for key*" {
        send "$lc_passwd\n\n"
        expect {
            # 密码错误
            "*passphrase for key*" {
                puts "Password error!"
                exit 1
            }

            # Server登陆提示符
            "*$lc_user@*" {
                send "\n"
            }
        }
    }

    # 免密登陆直接进入server交互
    "*$lc_user@*" {
        send "\n\n"
    }
    timeout {
        puts "connect $lc_host time out!"
        exit
    }
}

send "sh $lc_dst_dir/$run_on_srv_basename $agent_basename\n"
expect {
    "Final success." {
        send "exit\n\n"
        exit 0
    }
    "Fail:" {
        send "exit\n\n"
        exit 1
    }
    timeout {
        puts "Execute server script timeout!"
        exit 1
    }
}

end_of_message
    expect -f $expect_script
    ret=$?
    if [ "$ret" -eq "0" ];then
        result_msg="$result_msg-update success in host:$lc_host dir:$lc_dst_dir."
    else
        result_msg="$result_msg-update  fail   in host:$lc_host dir:$lc_dst_dir."
    fi
    rm -f $expect_script
}

result_msg="Result:"

for ((i=1; i<=$host_num; i++))
do
    eval value=\${host$i[@]}
    host_operate ${value}
done

echo ""
echo $result_msg | awk 'BEGIN {FS="=";RS="-"} {print $0}'

exit 0

