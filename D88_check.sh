#!/bin/sh

PATH=$PATH:/bin:/usr/bin
export PATH

ORACLE_SID=D88
ORACLE_HOME=/oracle/11.2.0.3
export ORACLE_SID ORACLE_HOME

log=/home/oracle/scripts/log/D88_check_`date +%d%m%Y`.log

echo ------------------------------ >> $log
date >> $log
server_name=`uname -n`
echo Server name: $server_name | tee -a $log
echo Check dataguard configuration | tee -a $log
$ORACLE_HOME/bin/dgmgrl <<EOF  | tee -a $log
connect sys/d88sys
show configuration;
exit;
EOF