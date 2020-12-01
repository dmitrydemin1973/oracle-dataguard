#!/bin/sh

# Start database D88A in PRIMARY role
# 26.02.2015 add - tee logging
# 26.02.2015 add - Are you sure?
# 11.03.2015 add - check service_names and set in to d88.asulr.krw.rzd
# 12.03.2015 Change algorithm:
#            OLD: startup as PRIMARY, check PRIMARY ROLE ...
#            NEW: startup mount, check PRIMARY role, alter database open ...
#

PATH=$PATH:/bin:/usr/bin
export PATH
ORACLE_SID=D88
ORACLE_HOME=/oracle/11.2.0.3
export ORACLE_SID ORACLE_HOME

log=/home/oracle/scripts/log/D88A_PRIMARY_start_`date +%d%m%Y`.log

echo ------------------------ >> $log
date >> $log

echo Starting database D88A as PRIMARY | tee -a $log

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

# startup database mount
echo "Startup database in mount mode" >> $log
$ORACLE_HOME/bin/sqlplus -s / as sysdba << EOF | tee -a $log
startup mount ;
exit;
EOF

#Check database role
db_role=`$ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF |  awk '{print $1;}'
set heading off
select replace(database_role,' ','_') from v\\$database;
exit;
EOF`

echo Database role is $db_role | tee -a $log

if [$db_role = "PRIMARY" ];
  then echo Check Database role - OK >> $log
  else echo Warning!!! Wrong role! Database can not start as PRIMARY | tee -a $log
       echo Script cancelled!!! | tee -a $log
       date >> $log
       exit;
fi

# open database
echo "Open database" >> $log
$ORACLE_HOME/bin/sqlplus -s / as sysdba << EOF | tee -a $log
alter database open;
exit;
EOF

#Check service_names
service_names=`$ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF | grep service_names  |  awk '{print $3;}'
set heading off
show parameter service_names
exit;
EOF`

echo Oracle service_names: $service_names | tee -a $log

if [ $service_names = "d88.asust.krw.rzd" ];
  then echo Check service_names - OK >> $log
  else echo Warning!!! Wrong service_names for PRIMARY database | tee -a $log
       echo Correcting service_names | tee -a $log

$ORACLE_HOME/bin/sqlplus -s / as sysdba << EOF3 | tee -a $log
alter system set service_names='d88.asust.krw.rzd' scope=memory;
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

date >> $log
echo Starting database D88A as PRIMARY complete | tee -a $log

# start listener
echo "Start listener" >> $log
$ORACLE_HOME/bin/lsnrctl  start LS_D88A   | tee -a $log

echo Starting STANDBY  LS_D88A complete | tee -a $log
