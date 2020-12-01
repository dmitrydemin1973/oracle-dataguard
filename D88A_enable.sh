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

#Add database D88A to D88A  to transport redolog
$ORACLE_HOME/bin/sqlplus -s sys/d88sys@d88b as sysdba <<EOF1
set heading off
Alter system set log_archive_config='dg_config=(D88A,D88B,D88C)' scope=both;
show parameter log_archive_config;
exit;
EOF1
                         
#Add database D88C to D88A  to transport redolog
$ORACLE_HOME/bin/sqlplus -s sys/d88sys@d88b as sysdba <<EOF1
set heading off
Alter system set log_archive_config='dg_config=(D88A,D88B,D88C)' scope=both;
Alter system set log_archive_dest_1='service="D88A"','LGWR ASYNC db_unique_name="D88A"','valid_for=(all_logfiles,primary_role)' scope=both;
show parameter log_archive_config;
show parameter log_archive_dest_1;
exit;
EOF1

#Add database D88C to D88B  to transport redolog
$ORACLE_HOME/bin/sqlplus -s sys/d88sys@d88c as sysdba <<EOF2
set heading off
Alter system set log_archive_config='dg_config=(D88A,D88B,D88C)' scope=both;
Alter system set log_archive_dest_2='service="D88B"','LGWR ASYNC db_unique_name="D88B"','valid_for=(all_logfiles,primary_role)' scope=both;
show parameter log_archive_config;
show parameter log_archive_dest_2;
exit;
EOF2

#Add D88C to config Data Guard
echo Server name: $server_name | tee -a $log
echo Enable dataguard configuration D88A| tee -a $log
$ORACLE_HOME/bin/dgmgrl <<EOF  | tee -a $log
connect sys/d88sys@d88c
add database 'D88A' as connect identifier is D88A maintained as physical;
enable database 'D88A';
show configuration;
exit;
EOF
