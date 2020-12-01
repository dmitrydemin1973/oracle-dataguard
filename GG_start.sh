#!/bin/sh

# Restore Golden Gate configuration and starting Golden gate
# Brovor D.V.
# 10.02.2015 create
# 13.02.2015 tee
# 17.02.2014 only starting GG (without restore from backup)
#

PATH=$PATH:/bin:/usr/bin
export PATH

log=/home/oracle/scripts/log/GG_start_`date +%d%m%Y`.log

echo ------------------------ >> $log
date >> $log

#Check database role
db_role=`$ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF |  awk '{print $1;}'
set heading off
select replace(database_role,' ','_') from v\\$database;
exit;
EOF`

echo Database role is $db_role >> $log 2>&1

if [$db_role = "PRIMARY" ];
  then echo Check Database role - OK >> $log 2>&1
    else echo Warning!!! Database is not PRIMARY | tee -a $log
         echo Golden gate must be started only on PRIMARY database | tee -a $log
         echo Script cancelled!!! | tee -a $log
         date >> $log
         exit
fi;

gg_dir=/oracle/gg11

echo Starting Golden Gate. Please wait 30 sec... | tee -a $log
$gg_dir/ggsci <<EOF >> $log 2>&1
info all
info EOD88P92
start MGR
quit
EOF

echo Sleep 10 sec and rescan info >> $log
sleep 10
$gg_dir/ggsci <<EOF >> $log 2>&1
start EOD88P92
info all
info EOD88P92
quit
EOF

date >> $log
echo Golden Gate started | tee -a $log
