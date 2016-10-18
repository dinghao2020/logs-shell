#!/bin/bash

yw1=$(for i in {1..7};do eval d$i=$(/bin/date -d "$i days ago" +%Y%m%d) && echo $[d$i].log;done)
yw2=$(for i in {8..14};do eval d$i=$(/bin/date -d "$i days ago" +%Y%m%d) && echo $[d$i].log;done)
today=$(date +%Y%m%d)
log_path=/data/appdir/java/logs/kinton-api/statistics/
tmp_log_week_acc=/tmp/week_account_id.log
tmp_log_week_prof=/tmp/week_profile_id.log
weeks_logs=/tmp/$(date +%Y)_$(date --date=$(date -d '1 week ago' +%Y%m%d) +%W).log
MYSQL1="mysql -hmysql.cim.in -uom -pcim120_CIM120 om --default-character-set=utf8 -A -N"
#[yyyyMMddhhmmss] [url] [accountId] [profileId] [phone] [UA] [appVersion] [platform] [isNewAccount] [isNewProfile] 

cd $log_path
#1上周pv
week_pv=$(cat $(for i in {1..7};do eval d$i=$(/bin/date -d "$i days ago" +%Y%m%d) && echo $[d$i].log;done)|wc -l)

#2上周一共多少用户来访
week_sum_account_id=$(awk -F']' '{print $3}' ${yw1}|awk -F'['  '$2!="" {print $2}'|sort|uniq |wc -l)

#3上周profile 统计
week_sum_profile_id=$(awk -F']' '{print $4}' ${yw1}|awk -F'['  '$2!="" {print $2}'|sort|uniq |wc -l)

#4新增用户统计  【判断标记为１】
week_sum_new_add_account_id=$(awk -F']' '$9="[1" {print $3,$9}' ${yw1}|awk -F'[' '$2!=" " {print $2,$3}'|sort|uniq|wc -l)

#5新profile 统计
week_sum_new_profile_id=$(awk -F']' '{print $4,$10}' ${yw1}|awk -F'[' '$3=="1" {print $2,$3}'|awk -F" " '$1!="" {print $1}'|uniq|wc -l)

#6留存account,新增account_id 留存计算（前天的新增与昨天的比较）
awk -F']' '{print $3,$9}' ${yw2}|awk -F'[' '$3=="1" {print $2,$3}'|awk '$1!="" {print $1}'|sort|uniq > ${tmp_log_week_acc}
awk -F']' '{print $3}' ${yw1} |awk -F'['  '$2!="" {print $2}'|sort|uniq >> ${tmp_log_week_acc}
week_sum_keep_account_id=$(awk '{++S[$NF]} END {for (a in S)  {print S[a], a}}' ${tmp_log_week_acc}|awk '$1>1 {print $1,$2}'|wc -l)

#7昨天新增profile_id,前天的新增与昨天的比较
awk -F']' '{print $4}' ${yw1}|awk -F'['  '$2!="" {print $2 }' |sort|uniq > ${tmp_log_week_prof}
awk -F']' '{print $4,$10}' ${yw2}|awk -F'['  '$2!="  " {print $2 $3}'|awk -F" " '$2==1 {print $1}'|sort|uniq >> ${tmp_log_week_prof}
week_sum_keep_profile_id=$(awk '{++S[$NF]} END {for (a in S)  {print S[a], a}}' ${tmp_log_week_prof}|awk '$1>1 {print $1,$2}'|wc -l)

#8 接口调用统计
week_url_account=$(awk -F']' '{print $2}'  ${yw1}|awk -F'[' '{print $2}'|sort |uniq -c|sort -nr)


echo -e "1pv:${week_pv}  3access:${week_sum_account_id}  3profile_account:${week_sum_profile_id}  4add_new_account_id:${week_sum_new_add_account_id}  5add_new_profile_id:${week_sum_new_profile_id}  6keep_account:${week_sum_keep_account_id} 7 keep_profile:${week_sum_keep_profile_id}  8url_account:\n ${week_url_account}" > ${weeks_logs}
sql="insert into summary_week(date, pv, uv, profile, uv_incr,profile_incr,account_retention,profile_retention) values(${today}, ${week_pv}, ${week_sum_account_id}, ${week_sum_profile_id}, ${week_sum_new_add_account_id}, ${week_sum_new_profile_id}, ${week_sum_keep_account_id}, ${week_sum_keep_profile_id});"
which mysql || exit -1
$MYSQL1 -e "$sql"
tail -n +2 ${weeks_logs} |awk 'yd=strftime("%Y%m%d",systime()-7*24*3600) {print "insert frequency_week (date, count,attribute, type) value ("yd" ,"$1" ,\""$2"\", 1);"}'|$MYSQL1

