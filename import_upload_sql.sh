#!/bin/bash

sql_dir=/home/dh/sql
nc -v -w 1 -z 127.0.0.1 2121 || ssh -N -f -L 2121:10.170.180.132:8015 dinghao@182.92.191.34 -p8015
rsync -avczP --delete ${sql_dir}/* -e'ssh -p 2121' dinghao@127.0.0.1:~/sql/
ssh -p2121 dinghao@127.0.0.1 '/bin/sudo /bin/bash -x /root/shell/mysql57_back.sh'
echo "备份完成，准备导入上传的数据！"
sleep 5
echo "开始导入数据"
ssh -p2121 dinghao@127.0.0.1 '/bin/bash -x /home/dinghao/shell/mysql57_in.sh'
echo "开始导入完成!"

#for i in `ls /home/dinghao/sql`;do 
#dbname=`echo $i|awk -F'.' '{print $1}'`
#/usr/local/mysql57/bin/mysql -uroot -pcimpublic123A -S /tmp/mysql57.sock -e"use ${dbname};source /home/dinghao/${i};"
#done
