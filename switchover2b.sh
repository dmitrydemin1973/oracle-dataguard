#!/bin/sh
## Switchover PRIMARY from D88C to D88B database
## by Oracle data guard
##

PATH=$PATH:/bin:/usr/bin
export PATH

ORACLE_SID=D88
ORACLE_HOME=/oracle/11.2.0.3
export ORACLE_SID ORACLE_HOME

log=/home/oracle/scripts/log/switchover2a_`date +%d%m%Y`.log

server_name=`uname -n`
echo Server name: $server_name | tee -a $log

/bin/date >> $log
echo "Check info (see D88_info*****.log file)"
/home/oracle/scripts/D88_info.sh > /dev/null

$ORACLE_HOME/bin/dgmgrl <<EOF  | tee -a $log
connect /
show configuration;
exit;
EOF

echo Switchover PRIMARY from D88A to D88B database? | tee -a $log

###########################
# Confirmation block
###########################
read -p "Are you sure to continue(y/n)? " -n 1 -r
echo | tee -a $log
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Are you sure to continue(y/n). Not sure!" >> $log
    echo "Script cancelled by user!" | tee -a $log
    exit;
fi
###########################

echo Stopping job queue | tee -a $log
$ORACLE_HOME/bin/sqlplus -s / as sysdba << EOF3 | tee -a $log
alter system set job_queue_processes=0 scope=memory;
exit;
EOF3

echo "sleep 15 seconds" | tee -a $log
sleep 15

$ORACLE_HOME/bin/dgmgrl <<EOF  | tee -a $log
connect sys/ppp
switchover to 'D88B';
show configuration;
exit;
EOF
