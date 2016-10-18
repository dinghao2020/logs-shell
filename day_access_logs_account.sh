#!/bin/bash

yd=$(date -d '1 days ago' +%Y%m%d)
yd2=$(date -d '2 days ago' +%Y%m%d)
log_path=/data/appdir/java/logs/kinton-api/statistics/
tmp_log_day_acc=/tmp/day_account_id.log
tmp_log_day_prof=/tmp/day_profile_id.log
MYSQL1="mysql -hmysql.cim.in -uom -pcim120_CIM120 om --default-character-set=utf8 -A -N"
#[yyyyMMddhhmmss] [url] [accountId] [profileId] [phone] [UA] [appVersion] [platform] [isNewAccount] [isNewProfile] 

#1昨日pv
day_pv=$(egrep ${yd} -c ${log_path}${yd}.log)

#2昨日一共多少用户来访
day_sum_account_id=$(awk -F']' '{print $3}' ${log_path}${yd}.log |awk -F'['  '$2!="" {print $2}'|sort|uniq |wc -l)

#3昨日profile 统计
day_sum_profile_id=$(awk -F']' '{print $4}' ${log_path}${yd}.log |awk -F'['  '$2!="" {print $2}'|sort|uniq |wc -l)

#4新增用户统计  【判断标记为１】
day_sum_new_add_account_id=$(awk -F']' '$9="[1" {print $3,$9}' ${log_path}${yd}.log|awk -F'[' '$2!=" " {print $2,$3}'|sort|uniq|wc -l)

#5新profile 统计
day_sum_new_profile_id=$(awk -F']' '{print $4,$10}' ${log_path}${yd}.log|awk -F'[' '$3=="1" {print $2,$3}'|awk -F" " '$1!="" {print $1}'|uniq|wc -l)

#6留存account,新增account_id 留存计算（前天的新增与昨天的比较）
awk -F']' '{print $3,$9}' ${log_path}${yd2}.log|awk -F'[' '$3=="1" {print $2,$3}'|awk '$1!="" {print $1}'|sort|uniq > ${tmp_log_day_acc}
awk -F']' '{print $3}' ${log_path}${yd}.log |awk -F'['  '$2!="" {print $2}'|sort|uniq >> ${tmp_log_day_acc}
day_sum_keep_account_id=$(awk '{++S[$NF]} END {for (a in S)  {print S[a], a}}' ${tmp_log_day_acc}|awk '$1>1 {print $1,$2}'|wc -l)

#7昨天新增profile_id,前天的新增与昨天的比较
awk -F']' '{print $4}' ${log_path}${yd}.log |awk -F'['  '$2!="" {print $2 }' |sort|uniq > ${tmp_log_day_prof}
awk -F']' '{print $4,$10}' ${log_path}${yd2}.log|awk -F'['  '$2!="  " {print $2 $3}'|awk -F" " '$2==1 {print $1}'|sort|uniq >> ${tmp_log_day_prof}
day_sum_keep_profile_id=$(awk '{++S[$NF]} END {for (a in S)  {print S[a], a}}' ${tmp_log_day_prof}| awk '$1>1 {print $1,$2}'|wc -l)

#8 接口调用统计
day_url_account=$(awk -F']' '{print $2}'  ${log_path}${yd}.log|awk -F'[' '{print $2}'|sort |uniq -c|sort -nr)
echo -e "1pv:${day_pv}  3access:${day_sum_account_id}  3profile_account:${day_sum_profile_id}  4add_new_account_id:${day_sum_new_add_account_id}  5add_new_profile_id:${day_sum_new_profile_id}  6keep_account:${day_sum_keep_account_id} 7 keep_profile:${day_sum_keep_profile_id}  8url_account:\n ${day_url_account}" > /tmp/${yd}.log

sql="use om;insert into summary(date, pv, uv, profile, uv_incr,profile_incr,account_retention,profile_retention) values(${yd}, ${day_pv}, ${day_sum_account_id}, ${day_sum_profile_id}, ${day_sum_new_add_account_id}, ${day_sum_new_profile_id}, ${day_sum_keep_account_id}, ${day_sum_keep_profile_id});"
$MYSQL1 -e "$sql"
sleep 1
tail -n +2 /tmp/${yd}.log|awk 'yd=strftime("%Y%m%d",systime()-1*24*3600) {print "insert frequency (date, count, attribute, type) value ("yd", "$1", \""$2"\", 1);"}'|$MYSQL1

