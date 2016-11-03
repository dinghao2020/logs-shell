#!/bin/bash 

[ -z $1 ] && echo "Please input parameter,eg 'day or week or month'" && exit 
[ -z $(command -v mysql) ] && echo "mysql_client no exit in Path,Please Check it" && exit
#MYSQL1="mysql -hmysql.cim.in -uom -pcim120_CIM120 om --default-character-set=utf8 -A -N"
MYSQL1="mysql -h192.168.3.102 -udh -pgitgit dinghaot1 --default-character-set=utf8 -A -N"
acc_inc_log=/tmp/acc_inc.log
pro_inc_log=/tmp/pro_inc.log
log_path=/home/dh/log_test/
[ ! -d $log_path ] && echo "no exit logs path $log_path,Please Check it!" && exit -1
cd $log_path

#统计计算
account_all()
{
pv=$(wc -l ${date1}|tail -n 1|awk '{print $1}')
uv=$(awk -F']' '{print $3}' ${date1}|awk -F'['  '$2!="" {print $2}'|sort|uniq |wc -l)
profile=$(awk -F']' '{print $4}' ${date1}|awk -F'['  '$2!="" {print $2}'|sort|uniq |wc -l)
uv_incr=$(awk -F']' '$9="[1" {print $3,$9}' ${date1}|awk -F'[' '$2!=" " {print $2,$3}'|sort|uniq|wc -l)
profile_incr=$(awk -F']' '{print $4,$10}' ${date1}|awk -F'[' '$3=="1" {print $2,$3}'|awk -F" " '$1!="" {print $1}'|uniq|wc -l)

awk -F']' '{print $3,$9}' ${date2}|awk -F'[' '$3=="1" {print $2,$3}'|awk '$1!="" {print $1}'|sort|uniq > ${acc_inc_log}
awk -F']' '{print $3}' ${date1}|awk -F'['  '$2!="" {print $2}'|sort|uniq >> ${acc_inc_log}
account_retention=$(awk '{++S[$NF]} END {for (a in S)  {print S[a], a}}' ${acc_inc_log}|awk '$1>1 {print $1,$2}'|wc -l)

awk -F']' '{print $4,$10}' ${date2}|awk -F'['  '$2!="  " {print $2 $3}'|awk -F" " '$2==1 {print $1}'|sort|uniq > ${pro_inc_log}
awk -F']' '{print $4}' ${date1}|awk -F'['  '$2!="" {print $2 }'|sort|uniq >> ${pro_inc_log}
profile_retention=$(awk '{++S[$NF]} END {for (a in S)  {print S[a], a}}' ${pro_inc_log}|awk '$1>1 {print $1,$2}'|wc -l)


echo $n 
sleep 2
frequency_sql=$(awk -F']' '{print $2}'  ${date1}|awk -F'[' '{print $2}'|sort |uniq -c|sort -nr|awk 'date0=strftime("%Y%m%d",systime()-$n*24*3600) {print "insert '${frequency_table}' (date, count,attribute, type) value ("date0" ,"$1" ,\""$2"\", 1);"}')

summary_sql="insert into ${summary_table} (date, pv, uv, profile, uv_incr,profile_incr,account_retention,profile_retention) values(${insert_date}, ${pv}, ${uv}, ${profile}, ${uv_incr}, ${profile_incr},${account_retention}, ${profile_retention});"
}


insert_mysql()
{
account_all
$MYSQL1 -e "$frequency_sql"
$MYSQL1 -e "$summary_sql"
}


logs_dir=(A1 B1)


case $1 in
day)
        dt1=$(date -d '1 days ago' +%Y%m%d).log
        date1=$(for i in ${logs_dir[@]};do  for j in ${dt1}; do echo $i/$j;done;done)
        dt2=$(date -d '2 days ago' +%Y%m%d).log
        date2=$(for i in ${logs_dir[@]};do  for j in ${dt2}; do echo $i/$j;done;done)
        n=1
        insert_date=$(date -d '1 days ago' +%Y%m%d)
        summary_table=summary
        frequency_table=frequency
        insert_mysql
        ;;
week)
        dt1=$(for i in {1..7};do eval d$i=$(/bin/date -d "$i days ago" +%Y%m%d) && echo $[d$i].log;done)
        date1=$(for i in ${logs_dir[@]};do  for j in ${dt1}; do echo $i/$j;done;done)
        dt2=$(for i in {8..14};do eval d$i=$(/bin/date -d "$i days ago" +%Y%m%d) && echo $[d$i].log;done)
        date2=$(for i in ${logs_dir[@]};do  for j in ${dt2}; do echo $i/$j;done;done)
        n=7
        insert_date=$(date -d '7 days ago' +%Y%m%d)
        summary_table=summary_week
        frequency_table=frequency_week
        insert_mysql
        ;;
month)
        dt1=$(date +%Y%m --date="-1 month")*.log
        date1=$(for i in ${logs_dir[@]};do  for j in ${dt1}; do echo $i/$j;done;done)
        dt2=$(date +%Y%m --date="-2 month")*.log
        date2=$(for i in ${logs_dir[@]};do  for j in ${dt2}; do echo $i/$j;done;done)
        n=$(date +%e)
	    insert_date=$(date --date="$(date +%e) days ago" '+%Y%m%d') 
        summary_table=summary_month
        frequency_table=frequency_month
        insert_mysql
        ;;
*)
       echo "You input parameter error, Please input 'day' ,or 'week' , or 'month' "
esac

