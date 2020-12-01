#!/bin/sh
# Start and recovery database D88A in STANDBY role
# 26.02.2015 add - tee logging 
# 26.02.2015 add - Are you sure? 
# 03.03.2015 check service_names
#

PATH=$PATH:/bin:/usr/bin
export PATH

log=/home/oracle/scripts/log/D88A_STANDBY_start_`date +%d%m%Y`.log

ORACLE_SID=D88
ORACLE_HOME=/oracle/11.2.0.3
export ORACLE_SID ORACLE_HOME

echo ------------------------ >> $log
date >> $log

echo Starting database D88A as STANDBY | tee -a $log

###########################
# Confirmation block
###########################
read -p "Are you sure to continue(y/n)? " -n 1 -r
echo | tee -a $log
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Are you sure to continue(y/n). Not sure!" >> $log
    echo Script cancelled by user! | tee -a $log
    exit;
fi
###########################

$ORACLE_HOME/bin/sqlplus -s / as sysdba << EOF1 | tee -a $log
startup mount ;
exit;
EOF1

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

#Check database role
db_role=`$ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF |  awk '{print $1;}'
set heading off
select replace(database_role,' ','_') from v\\$database;
exit;
EOF`

echo Database role is $db_role | tee -a $log

if [$db_role = "PHYSICAL_STANDBY" ];
  then echo Check database role - OK >> $log
  else echo Warning!!! Database can not start in PHYSICAL_STANDBY role | tee -a $log
       echo Script cancelled!!! | tee -a $log
       date >> $log
       exit;
fi

#Check current switchover status
db_status1=`$ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF2 |  awk '{print $1;}'
set heading off
select replace(switchover_status,' ','_') from v\\$database;
exit;
EOF2`

echo Switchover status check1: $db_status1 | tee -a $log

#Check service_names
service_names=`$ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF | grep service_names  |  awk '{print $3;}'
set heading off
show parameter service_names
exit;
EOF`

echo Oracle service_names: $service_names | tee -a $log

if [ $service_names = "d88s.asust.krw.rzd" ];
  then echo Check service_names - OK >> $log
  else echo Warning!!! Wrong service_names for STANDBY database | tee -a $log
       echo Correcting sevice_names | tee -a $log

$ORACLE_HOME/bin/sqlplus -s / as sysdba << EOF3 | tee -a $log
alter system set service_names='d88s.asust.krw.rzd' scope=both;
exit;
EOF3

#Check service_names
service_names=`$ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF | grep service_names  |  awk '{print $3;}'
       set heading off
       show parameter service_names
       exit;
EOF`
       echo Oracle service_names: $service_names | tee -a $log
fi

echo Start getting redo-logs | tee -a $log

$ORACLE_HOME/bin/sqlplus -s / as sysdba << EOF3 | tee -a $log
alter database recover managed standby database using current logfile disconnect;
exit;
EOF3

echo "wait 15 second please..." | tee -a $log
sleep 15

#Check switchover status once more
db_status2=`$ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF4 |  awk '{print $1;}'
set heading off
select replace(switchover_status,' ','_') from v\\$database;
exit;
EOF4`

echo Switchover status check2: $db_status2 | tee -a $log
date >> $log
echo Starting database D88A as STANDBY complete | tee -a $log

#echo Stopping STANDBY database D88A complete | tee -a $log

# start listener
echo "Start listener" >> $log
$ORACLE_HOME/bin/lsnrctl  start LS_D88A   | tee -a $log

echo Starting STANDBY Listener LS_D88A complete | tee -a $log

