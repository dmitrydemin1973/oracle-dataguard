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

if [$db_name = "D88C" ];
  then echo Check Database unique name - OK >> $log
  else echo Warning!!! This is not D88C database | tee -a $log
       echo Script cancelled!!! | tee -a $log
       date >> $log
 exit;
fi
                         
#Add database D88C to D88A  to transport redolog
$ORACLE_HOME/bin/sqlplus -s sys/ppp@d88a as sysdba <<EOF1
set heading off
Alter system set log_archive_config='dg_config=(D88A,D88B,D88C)' scope=both;
Alter system set log_archive_dest_3='service="D88C"','LGWR ASYNC db_unique_name="D88C"','valid_for=(all_logfiles,primary_role)' scope=both;
show parameter log_archive_config;
show parameter log_archive_dest_3;
exit;
EOF1

#Add database D88C to D88B  to transport redolog
$ORACLE_HOME/bin/sqlplus -s sys/ppp@d88b as sysdba <<EOF2
set heading off
Alter system set log_archive_config='dg_config=(D88A,D88B,D88C)' scope=both;
Alter system set log_archive_dest_3='service="D88C"','LGWR ASYNC db_unique_name="D88C"','valid_for=(all_logfiles,primary_role)' scope=both;
show parameter log_archive_config;
show parameter log_archive_dest_3;
exit;
EOF2

#Add D88C to config Data Guard
echo Server name: $server_name | tee -a $log
echo Enable dataguard configuration D88C| tee -a $log
$ORACLE_HOME/bin/dgmgrl <<EOF  | tee -a $log
connect sys/ppp@d88a
add database 'D88C' as connect identifier is D88C maintained as physical;
enable database 'D88C';
show configuration;
exit;
EOF
