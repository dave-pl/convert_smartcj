#!/bin/bash

TMPFILE=`mktemp tmp.XXXXXXXXX`
MYSQL=`which mysql`

if [ -d /etc/webmin ]; then
  PANEL=vm
  USER=root
  PASS=$(cat /etc/webmin/mysql/config |grep pass=|cut -f 2 -d "=")
elif [ -d /usr/local/vesta ]; then
  PANEL=vc
  USER=root
  PASS=$(cat /usr/local/vesta/conf/mysql.conf |awk '{print $3}'|cut -f 2 -d "'")
elif [ -d /usr/local/directadmin ]; then
  PANEL=da
  USER=da_admin
  PASS=$(cat /usr/local/directadmin/conf/mysql.conf|grep passwd|cut -f 2 -d "=")
elif [ -d /usr/local/mgr5 ]; then
  PANEL=isp
  USER=root
  PASS=$(cat /root/.my.cnf|grep password|awk '{print $3}')
fi
echo $PANEL
echo $USER
echo $PASS
#PASS=
> $TMPFILE
echo "list database,table with myisam for rot_* tables to $TMPFILE"

#Выводим наши таблицы в файл
for d in $($MYSQL -u $USER -p$PASS -e "show databases"|grep -v Database);do
    for i in $($MYSQL -u $USER -p$PASS -e "SHOW TABLES FROM $d" | egrep 'rot_gallery_stats|rot_gallery_info|rot_galleries'); do
        $MYSQL -u $USER -p$PASS -e "SELECT TABLE_SCHEMA, table_name FROM INFORMATION_SCHEMA.TABLES where table_name LIKE '$i' and Engine = 'MyISAM'"| tail -n +2 >> $TMPFILE ; done
done

#альтернативный вариант
#for d in $($MYSQL -u $USER -p$PASS -e "show databases"|grep -v Database);do 
#  for i in $($MYSQL -u $USER -p$PASS -e "SHOW TABLES FROM $d" | egrep 'rot_gallery_stats|rot_gallery_info|rot_galleries'); do 
#    echo "$d $i" >> $TMPFILE ; done
#done

#коневертируем наши таблицы из файла
echo "converting tables to innodb"
cat $TMPFILE |while read l; do read -d, c1 c2 < <(echo $l) ; echo "$c1 $c2 "; $MYSQL -u$USER -p$PASS -e "use $c1; alter table $c2 ENGINE = INNODB;" ; done
rm -rf $TMPFILE
#
#версия 2 
#Mysql Table Engine: looks like mysql DB tables (rot_gallery_info, rot_gallery_stats1) are not of InnoDB format. it's good idea to tune mysql and use innodb table format for rot_* tables. Please, read wiki for mysql tuning hints.
#Script Installation is done. Please, open http://dave.test/scj2/admin/ in your browser. Your login is 'admin' and password is 'cxyfsgaevi'.
#версия 1.5
#Script Installation is done. Please, open http://dave2.test/scj/admin/ in your browser. Your login is 'admin' and password is 'adminpass'. 
#Mysql Table Engine: looks like mysql DB tables (rot_galleries, rot_gallery_stats) are not of InnoDB format. it's good idea to tune mysql and use innodb table format for rot_* tables. Please, read wiki for mysql tuning hints.
