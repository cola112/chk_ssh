#!/bin/sh

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
    ssh -X -g -o ExitOnForwardFailure=yes -N -D 65000 \
        -L2222:127.0.0.1:22 -L2223:192.168.11.1:22222 \
        -R\*:2222:127.0.0.1:22 cola &
}

proc_chk() {
    RESULT=$(ps -ef | grep ssh | grep 65000)
    if [ "${RESULT:-null}" = null ]; then
        return 0
    else return 1
    fi
}

tun_cmd_chk() {
    RESULT=$(ssh root@localhost -p2222 netstat -an | egrep '^tcp.*:2221.*LIST')
    if [ "${RESULT:-null}" = null ]; then
        return 0
    else return 1
    fi
}

while :
do
    RESULT=$(ps -ef | grep ssh | grep 65000)
    PID=$(ps -ef | grep ssh | grep 65000 | awk '{print $2}')

    if [ "${RESULT:-null}" = null ]; then
        echo $(date +"%F %T") "PROCESS not running, starting " #$PROCANDARGS
        ssh -X -g -o ExitOnForwardFailure=yes -N -D 65000 -L2222:127.0.0.1:22 -L2223:192.168.11.1:22222 -R\*:2222:127.0.0.1:22 cola &
    else
        echo $(date +"%F %T") "running"
    fi

    if proc_chk && tun_cmd_chk; then
        echo "Tunnel health"
    else echo " Tunnel not health"
    fi
    sleep 10
done
