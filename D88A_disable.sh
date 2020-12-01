#!/bin/sh

PATH=$PATH:/bin:/usr/bin
export PATH

ORACLE_SID=D88
ORACLE_HOME=/oracle/11.2.0.3
export ORACLE_SID ORACLE_HOME

log=/home/oracle/scripts/log/D88_disable_`date +%d%m%Y`.log

echo ------------------------------ >> $log
date >> $log
server_name=`uname -n`
#Check database unique name
#db_name=`$ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF |  awk '{print $1;}'
#set heading off
#select db_unique_name from v\\$database;
#exit;
#EOF`

#echo Database unique name is $db_name | tee -a $log

#if [$db_name = "D88C" ];
#  then echo Check Database unique name - OK >> $log
#  else echo Warning!!! This is not D88C database | tee -a $log
#       echo Script cancelled!!! | tee -a $log
#       date >> $log
# exit;
#fi
                         
echo Server name: $server_name | tee -a $log
echo Check dataguard configuration | tee -a $log
$ORACLE_HOME/bin/dgmgrl <<EOF  | tee -a $log
connect sys/ppp@d88c
disable database 'D88A';
remove database 'D88A';
show configuration;
exit;
EOF

#$ORACLE_HOME/bin/sqlplus -s sys/d88sys@d88b as sysdba <<EOF1
#set heading off
#Alter system set log_archive_dest_1=' ' scope=both;
#alter system set log_archive_config='dg_config=(D88B,D88C)' scope=both;
#show parameter log_archive_config;
#show parameter log_archive_dest_1;
#exit;
#EOF1


#$ORACLE_HOME/bin/sqlplus -s sys/d88sys@d88c as sysdba <<EOF2
#set heading off
#Alter system set log_archive_dest_2=' ' scope=both;
#alter system set log_archive_config='dg_config=(D88B,D88C)' scope=both;
#show parameter log_archive_config;
#show parameter log_archive_dest_2;
#exit;
#EOF2

