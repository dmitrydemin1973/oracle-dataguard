#!/bin/sh

# Stop STAND BY database D88A
# 04.12.2015 created
#

PATH=$PATH:/bin:/usr/bin
export PATH
ORACLE_SID=D88
ORACLE_HOME=/oracle/11.2.0.3
export ORACLE_SID ORACLE_HOME

log=/home/oracle/scripts/log/D88A_STANDBY_stop_`date +%d%m%Y`.log

echo ------------------------ >> $log
date >> $log

echo Checking database role | tee -a $log

#Check database role
db_role=`$ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF |  awk '{print $1;}'
set heading off
select replace(database_role,' ','_') from v\\$database;
exit;
EOF`

echo Database role is $db_role | tee -a $log

if [$db_role = "PHYSICAL_STANDBY" ];
  then echo Check Database role - OK >> $log
  else echo Warning!!! Wrong role! Database is not PHYSICAL_STANDBY | tee -a $log
       echo Script cancelled!!! | tee -a $log
       date >> $log
       exit;
fi

echo Stopping PHYSICAL_STANDBY database D88A | tee -a $log

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

# shutdown database
echo "Shutdown database" >> $log
$ORACLE_HOME/bin/sqlplus -s / as sysdba << EOF | tee -a $log
alter database recover managed standby database cancel;
shutdown immediate;
exit;
EOF

echo Stopping STANDBY database D88A complete | tee -a $log

# shutdown listener
echo "Shutdown listener" >> $log
$ORACLE_HOME/bin/lsnrctl  stop LS_D88A  | tee -a $log

echo Stopping STANDBY Listener LS_D88A complete | tee -a $log
