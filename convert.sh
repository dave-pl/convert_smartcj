#!/bin/bash

TMPFILE=`mktemp tmp.XXXXXXXXX`
MYSQL=`which mysql`

if [ -d /etc/webmin ]; then
  PANEL=vm
  USER=root
  PASS=$(cat /root/.my.cnf|grep password|cut -f 2 -d "=")
elif [ -d /usr/local/directadmin ]; then
  PANEL=da
  USER=da_admin
  PASS=$(cat /root/.my.cnf|grep password|cut -f 2 -d "=")
elif [ -d /usr/local/vesta ]; then
  PANEL=vc
  USER=root
  PASS=$(cat /usr/local/vesta/conf/mysql.conf |awk '{print $3}'|cut -f 2 -d "'")
elif [ -d /usr/local/mgr5 ]; then
  PANEL=isp
  USER=root
  PASS=$(cat /root/.my.cnf|grep password|awk '{print $3}')
fi
echo $PANEL
echo $USER
echo $PASS

> $TMPFILE
echo "list database,table with myisam for rot_* tables to $TMPFILE"

#Выводим наши таблицы в файл
for d in $($MYSQL -u $USER -p$PASS -e "show databases"|grep -v Database);do
    for i in $($MYSQL -u $USER -p$PASS -e "SHOW TABLES FROM $d" | grep rot_gal*); do
        $MYSQL -u $USER -p$PASS -e "SELECT TABLE_SCHEMA, table_name FROM INFORMATION_SCHEMA.TABLES where table_name LIKE '$i' and Engine = 'MyISAM'"| tail -n +2 >> $TMPFILE ; done
done
#коневертируем наши таблицы из файла
echo "converting tables to innodb"
cat $TMPFILE |while read l; do read -d, c1 c2 < <(echo $l) ; echo "$c1 $c2 "; $MYSQL -u$USER -p$PASS -e "use $c1; alter table $c2 ENGINE = INNODB;" ; done
rm -rf $TMPFILE
