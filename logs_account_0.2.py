import datetime
import os
import subprocess
import codecs
import sys
import pymysql
# dd=str(input("请输入day or week or month: "))
dd=sys.argv[1]
today=datetime.date.today()
# yesterday = today - datetime.timedelta(days=1)


date1 = []
date2 = []
acc_inc_log = "/tmp/%s" % datetime.datetime.now().strftime('%Y%m%d')+".acc"
pro_inc_log = "/tmp/%s" % datetime.datetime.now().strftime('%Y%m%d')+".pro"
log_path = "/home/dh/log_test"
user = 'root'
pwd  = 'gitgit'
host = '127.0.0.1'
db   = 'dinghaot1'
cnx = pymysql.connect(user=user, password=pwd, host=host, database=db, charset='utf8')
cursor = cnx.cursor()


def logs(list):
    log_list=" ".join(list)
    return log_list

def account_all(date1 ,date2):
    os.chdir("%s" % log_path)
    pv = subprocess.check_output("wc -l %s|tail -n 1|awk '{print $1}'" % logs(date1), shell=True).decode("utf-8").strip("\n")
    uv = subprocess.check_output('''awk -F']' '{print $3}' %s|awk -F'[' '$2!="" {print $2}'|sort|uniq |wc -l ''' % logs(date1), shell=True).decode("utf-8").strip("\n")
    profile = subprocess.check_output('''awk -F']' '{print $4}' %s|awk -F'['  '$2!="" {print $2}'|sort|uniq |wc -l''' % logs(date1), shell=True).decode("utf-8").strip("\n")
    uv_incr = subprocess.check_output('''awk -F']' '$9="[1" {print $3,$9}' %s|awk -F'[' '$2!=" " {print $2,$3}'|sort|uniq|wc -l''' % logs(date1), shell=True).decode("utf-8").strip("\n")
    profile_incr = subprocess.check_output('''awk -F']' '{print $4,$10}' %s|awk -F'[' '$3=="1" {print $2,$3}'|awk -F" " '$1!="" {print $1}'|uniq|wc -l''' % logs(date1), shell=True).decode("utf-8").strip("\n")


    output_acc_inc = codecs.open('%s' % acc_inc_log, 'a+', 'utf-8')
    subprocess.Popen('''awk -F']' '{print $3,$9}' %s|awk -F'[' '$3=="1" {print $2,$3}'|awk '$1!="" {print $1}'|sort|uniq ''' % logs(date2), shell=True,stdout=output_acc_inc,stderr=subprocess.PIPE)
    subprocess.Popen('''awk -F']' '{print $3}' %s|awk -F'[' '$2!="" {print $2}'|sort|uniq''' % logs(date1), shell=True,stdout=output_acc_inc,stderr=subprocess.PIPE)
    account_retention = subprocess.check_output("awk '{++S[$NF]} END {for (a in S)  {print S[a], a}}' %s|awk '$1>1 {print $1,$2}'|wc -l" % acc_inc_log,shell=True).decode("utf-8").strip("\n")

    output_pro_inc = codecs.open('%s' % pro_inc_log, 'a+', 'utf-8')
    subprocess.Popen( '''awk -F']' '{print $4,$10}' %s|awk -F'['  '$2!="  " {print $2 $3}'|awk -F" " '$2==1 {print $1}'|sort|uniq''' % logs(date2), shell=True,stdout=output_pro_inc,stderr=subprocess.PIPE)
    subprocess.Popen('''awk -F']' '{print $4}' %s|awk -F'['  '$2!="" {print $2 }'|sort|uniq''' % logs(date1), shell=True,stdout=output_pro_inc,stderr=subprocess.PIPE)
    profile_retention = subprocess.check_output("awk '{++S[$NF]} END {for (a in S)  {print S[a], a}}' %s|awk '$1>1 {print $1,$2}'|wc -l" % pro_inc_log,shell=True).decode("utf-8").strip("\n")
    frequency_sql = subprocess.check_output('''awk -F']' '{print $2}' %s|awk -F'[' '{++S[$2]} END {for (a in S) {print S[a], "\\""a"\\""}}'|awk 'date0=strftime("%%Y%%m%%d",systime()-'%s'*24*3600) {print "insert %s (date, attribute, count, type) value ("date0" ,"$2", "$1", 1);"}' ''' % (logs(date1), n, frequency_table), shell=True).decode("utf-8").strip("\n")
    acc = print("pv=%s,uv=%s,profile=%s,uv_incr=%s,profile_inc=%s,account_retention=%s,profile_retention=%s" % (pv, uv, profile, uv_incr, profile_incr,account_retention, profile_retention))
    summary_sql = "insert into %s (date, pv, uv, profile, uv_incr,profile_incr,account_retention,profile_retention) values(%s, %s, %s, %s, %s, %s,%s, %s);" % (summary_table, insert_date, pv, uv, profile, uv_incr, profile_incr, account_retention, profile_retention)
    # cursor.execute(frequency_sql)
    # cursor.execute(summary_sql)
    # cursor.commit
    try:
        # 执行sql语句
        cursor.execute(frequency_sql)
        cursor.execute(summary_sql)
        # 提交到数据库执行
        cnx.commit()
    except:
        # 如果发生错误则回滚
        cnx.rollback()
    # print(frequency_sql.split("\n")[0].startswith(r'/'))
    # print(summary_sql)
    # frequency_sql.split(";")
    return print(summary_sql ,"\n\n\n",frequency_sql)


if dd == "day":
    n = 1
    insert_date = subprocess.check_output('date -d "%s days ago" +%%Y%%m%%d' % n,shell=True).decode("utf-8").strip("\n")
    summary_table = "summary"
    frequency_table = "frequency"
    date1.append(subprocess.check_output("echo $(date -d '1 days ago' +%Y%m%d).log", shell=True).decode("utf-8").strip("\n"))
    date2.append(subprocess.check_output("echo $(date -d '2 days ago' +%Y%m%d).log", shell=True).decode("utf-8").strip("\n"))
    account_all(date1,date2)

elif dd == "week":
    n = 7
    insert_date = subprocess.check_output('date -d "%s days ago" +%%Y%%m%%d' % n, shell=True).decode("utf-8").strip("\n")
    summary_table = "summary_week"
    frequency_table = "frequency_week"
    for i in range(1, 8):
        date1.append(subprocess.check_output('echo $(date -d "%d days ago" +%%Y%%m%%d).log' % i, shell=True).decode("utf-8").strip("\n"))
    for i in range(8, 15):
        date2.append(subprocess.check_output('echo $(date -d "%d days ago" +%%Y%%m%%d).log' % i, shell=True).decode("utf-8").strip("\n"))
    account_all(date1, date2)

elif dd == "month":
    n = int(subprocess.check_output('date +%e', shell=True).decode("utf-8").strip("\n"))
    insert_date = subprocess.check_output('date -d "%s days ago" +%%Y%%m%%d' % n, shell=True).decode("utf-8").strip("\n")
    summary_table = "summary_month"
    frequency_table = "frequency_month"
    date1.append(subprocess.check_output('echo $(date +%Y%m --date="-1 month")*.log', shell=True).decode("utf-8").strip("\n"))
    date2.append(subprocess.check_output('echo $(date +%Y%m --date="-2 month")*.log', shell=True).decode("utf-8").strip("\n"))
    account_all(date1, date2)
