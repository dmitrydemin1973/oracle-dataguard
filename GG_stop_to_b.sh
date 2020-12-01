#!/bin/sh

# Stop Golden Gate and archiving it to reserv server
# Brovor D.V.
# 10.02.2015 create
# 13.02.2015 tee
# 17.02.2015 don't send full gg folder, only dirchk folder copy to reserv server
# 16.09.2015 additional note "Password needed for $server_name2"
# 21.01.2016 change hostname of ASUST servers (alpha, betta is expired)
# 21.01.2016 change log name from GG_start to GG_stop
#

PATH=$PATH:/bin:/usr/bin
export PATH

log=/home/oracle/scripts/log/GG_stop_`date +%d%m%Y`.log

echo ------------------------ >> $log
date >> $log

server_name=`uname -n`
echo Server name: $server_name >> $log

#if [ $server_name = 'krw-asust-db-01.krw.oao.rzd' ]
#  then server_name2="krw-asust-db-02.krw.oao.rzd"
#fi
#
#if [ $server_name = 'krw-asust-db-02.krw.oao.rzd' ];
#  then server_name2="krw-asust-db-01.krw.oao.rzd"
#fi

server_name2="krw-asust-db-02.krw.oao.rzd"

echo Backup Golden Gate configuration from $server_name to $server_name2: >> $log

#Check database role
db_role=`$ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF |  awk '{print $1;}'
set heading off
select replace(database_role,' ','_') from v\\$database;
exit;
EOF`

echo Database role is $db_role >> $log

if [$db_role = "PRIMARY" ];
  then echo Check Database role - OK >> $log
  else echo Warning!!! Database is not PRIMARY | tee -a $log
       echo Actual Golden gate configuration only on PRIMARY database | tee -a $log
       echo Script cancelled!!! | tee -a $log
       date >> $log
       exit
fi;

gg_dir=/oracle/gg11
gg_conf_dir=$gg_dir/dirchk
#tar_dir=/oracle

echo Stopping Golden Gate... | tee -a $log
$gg_dir/ggsci << EOF >> $log 2>&1
info all
info EOD88P92
stop EOD88P92
stop MGR !
info all
info EOD88P92
quit
EOF

echo Golden gate stopped | tee -a $log

echo Copy $gg_conf_dir to $server_name2 | tee -a $log
echo Password needed for $server_name2 | tee -a $log
/usr/bin/scp $gg_conf_dir/* oracle@$server_name2:$gg_conf_dir >> $log 2>&1

date >> $log
echo Backup Golden gate completed | tee -a $log