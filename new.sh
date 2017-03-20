#!/bin/sh

BIND_PORT=65000
R_LISTPORT=2222
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
    proc_chk &&

    if proc_chk && tun_cmd_chk; then
        echo $(date +"%F %T")" Tunnel health"
    else echo $(date +"%F %T")" Tunnel not health"
      if
    fi

    sleep 10
done
