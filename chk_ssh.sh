#!/bin/sh

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
    sleep 10
done  
