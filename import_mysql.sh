#!/bin/bash 

for i in `ls /home/dh/sql`;do 
 dbname=`echo $i|awk -F'.' '{print $1}'`
#mysql -uroot -pgitgit -e "create database if not exists `echo ${dbname}`;"
#mysql -uroot -pgitgit -e "create database if not exists `echo $dbname`;use $dbname;"
mysql -uroot -pgitgit -e "create database if not exists  $dbname;use $dbname; source /home/dh/sql/$i;"
echo $dbname
echo "$dbname"
done
