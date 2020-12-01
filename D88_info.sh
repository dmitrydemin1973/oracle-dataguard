#!/bin/sh
# Info for database D88
# via data guard, tns connect & direct connect
# 26.06.2015 create
#

PATH=$PATH:/bin:/usr/bin
export PATH

ORACLE_SID=D88
ORACLE_HOME=/oracle/11.2.0.3
export ORACLE_SID ORACLE_HOME

log=/home/oracle/scripts/log/D88_info_`date +%d%m%Y`.log

echo ------------------------------ >> $log
server_name=`uname -n`
echo Server name: $server_name | tee -a $log

echo Check connection to D88 bases: | tee -a $log
date >> $log
echo Check dataguard configuration
$ORACLE_HOME/bin/dgmgrl <<EOF  | tee -a $log
connect sys/d88sys
show configuration;
show resource verbose 'D88A';
show resource verbose 'D88B';
show resource verbose 'd88c';
exit;
EOF

echo "1. Check direct connection to current Database"  | tee -a $log
$ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF  | tee -a $log
set heading off
select 'Direct connection to current database '||db_unique_name||' - OK!' from v\$database;
select 'Database role:'||database_role from v\$database;
exit;
EOF

echo "2. Check connection to Database D88A via tnsnames.ora"  | tee -a $log
$ORACLE_HOME/bin/sqlplus -s sys/d88sys@D88A as sysdba <<EOF  | tee -a $log
set heading off
select 'TNS connection to D88A - OK! Database role:'||database_role from v\$database;
exit;
EOF

echo "3. Check connection to Database D88B via tnsnames.ora"  | tee -a $log
$ORACLE_HOME/bin/sqlplus -s sys/d88sys@D88B as sysdba <<EOF  | tee -a $log
set heading off
select 'TNS connection to D88B - OK! Database role:'||database_role from v\$database;
exit;
EOF

echo "4. Check connection to Database D88C via tnsnames.ora"  | tee -a $log
$ORACLE_HOME/bin/sqlplus -s sys/d88sys@D88C as sysdba <<EOF  | tee -a $log
set heading off
select 'TNS connection to D88C - OK! Database role:'||database_role from v\$database;
exit;
EOF
