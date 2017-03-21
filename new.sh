#!/bin/sh

BIND_PORT=65000
L_LISTPORT=2222
R_LISTPORT=2223
SPEC_TUN="-L2223:192.168.11.1:22222"

#Avoid duplicate script run
PIDFILE=/tmp/`basename $0`.pid
if [ -f $PIDFILE ]; then
    if ps -p `cat $PIDFILE` > /dev/null 2>&1; then
        echo $(date +"%F %T") "$0 already running!"
        exit
    fi
fi
echo $$ > $PIDFILE
trap 'rm -f "$PIDFILE" >/dev/null 2>&1' EXIT HUP KILL INT QUIT TERM

killprocess(){
    /bin/kill $PID
}

cmd_exec() {
    ssh -X -g -o ExitOnForwardFailure=yes -N -D $BIND_PORT \
        -L$L_LISTPORT:127.0.0.1:22 $SPEC_TUN \
        -R\*:$R_LISTPORT:127.0.0.1:22 cola &
}

proc_chk() {
    RESULT=$(ps -ef | grep ssh | grep $BIND_PORT)
    if [ "${RESULT:-null}" = null ]; then
        return 1
    else return 0
    fi
}

tun_cmd_chk() {
    RESULT=$(ssh root@localhost -p$L_LISTPORT netstat -an | egrep '^tcp.*:$R_LISTPORT.*LIST')
    if [ "${RESULT:-null}" = null ]; then
        return 1
    else return 0
    fi
}

while :
do
    RESULT=$(ps -ef | grep ssh | grep $BIND_PORT)
    PID=$(ps -ef | grep ssh | grep $BIND_PORT | awk '{print $2}')
    proc_chk
    proc_sta=$?
    tun_cmd_chk
    tun_cmd_sta=$?

    if [[ $proc_sta == 0 ]] && [[ $tun_cmd_sta == 0 ]]; then
        echo $(date +"%F %T")" Tunnel health"
    else echo $(date +"%F %T")" Tunnel not health proc_sta=$proc_sta tun_cmd_sta=$tun_cmd_sta"
        if [[ $proc_sta == 0 ]]; then
          echo $(date +"%F %T")" Process exist, tun_cmd_sta=$tun_cmd_sta Killing Process"
          killprocess
          echo $(date +"%F %T")" Executing SSH tunnel command"
          cmd_exec
        else
          echo $(date +"%F %T")" Executing SSH tunnel command"
          cmd_exec
        fi
    fi

    sleep 10
done
