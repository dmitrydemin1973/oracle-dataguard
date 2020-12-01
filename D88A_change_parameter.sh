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



#'LOCATION=/ASUST/flash_recovery_area/D88A/archivelog  VALID_FOR=(ALL_LOGFILES,ALL_ROLES) DB_UNIQUE_NAME=D88C'                         

#Add database D88A to D88A  to transport redolog
$ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF1
set heading off
Alter system set log_archive_dest_1='LOCATION=/ASUST/flash_recovery_area/D88A/archivelog  VALID_FOR=(ALL_LOGFILES,ALL_ROLES) DB_UNIQUE_NAME=D88A' scope=both;
show parameter log_archive_dest_1;
exit;
EOF1



#Add database D88B to D88A  to transport redolog
$ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF1
set heading off
Alter system set log_archive_dest_2='service="D88B"','LGWR ASYNC db_unique_name="D88B"','valid_for=(all_logfiles,primary_role)' scope=both;
show parameter log_archive_dest_2;
exit;
EOF1

#Add database D88C to D88A  to transport redolog
$ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF2
set heading off
Alter system set log_archive_dest_3='service="D88C"','LGWR ASYNC db_unique_name="D88C"','valid_for=(all_logfiles,primary_role)' scope=both;
show parameter log_archive_dest_3;
exit;
EOF2

