#!/bin/sh

PATH=$PATH:/bin:/usr/bin
export PATH

ORACLE_SID=D88
ORACLE_HOME=/oracle/11.2.0.3
export ORACLE_SID ORACLE_HOME

log=/home/oracle/scripts/log/D88_enable_`date +%d%m%Y`.log

echo ------------------------------ >> $log
date >> $log
server_name=`uname -n`
#Check database unique name
db_name=`$ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF |  awk '{print $1;}'
set heading off
select db_unique_name from v\\$database;
exit;
EOF`

echo Database unique name is $db_name | tee -a $log

if [$db_name = "D88A" ];
  then echo Check Database unique name - OK >> $log
  else echo Warning!!! This is not D88A database | tee -a $log
       echo Script cancelled!!! | tee -a $log
       date >> $log
 exit;
fi


#Add D88C to config Data Guard
echo Server name: $server_name | tee -a $log
echo Enable dataguard configuration D88A| tee -a $log
$ORACLE_HOME/bin/dgmgrl <<EOF  | tee -a $log
connect sys/ppp@d88a
add database 'D88A' as connect identifier is D88A maintained as physical;
enable database 'D88A';
show configuration;
exit;
EOF
