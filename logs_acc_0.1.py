import datetime
import re
import os
import sys
import pymysql

# dd = sys.argv[1]
dd="week"
#[yyyyMMddhhmmss0] [url1] [accountId2] [profileId3] [phone4] [UA5] [appVersion6] [platform7] [isNewAccount8] [isNewProfile9]
pv = 0
d1_acc_id_set=set()
d2_acc_id_set=set()
d1_pro_id_set=set()
d2_pro_id_set=set()
account_id_add_set=set()
profile_id_add_set=set()
dic_uv = {}
dic_url = {}
dic_account_id = {}
dic_profile_id = {}
dic_account_id_add = {}
dic_profile_id_add = {}
dic_profile_id_keep = {}
dic_account_id_keep = {}



#传入要打开的文件file=open("/home/dh/log_test/20161031.log", 'rU')，返回的是文件行数
def account_line(file):
    global pv
    global dic_url
    pv0 = 0
    for pv0, line0 in enumerate(file):
        # pass
        id = re.split(r'[\[\]]', line0)
        if id[3] !=' ':
            if id[3] in dic_url:
                dic_url[id[3]] = dic_url[id[3]] + 1
            else:
                dic_url[id[3]] = 1
    pv = pv0 + pv +1
    return pv

#统计日志某个位置id(user_id or profile_id)，把不同位置的id 放入对应的字典里，如果存在，字典的value +1
def account_id(file,n,tmp_set):
    # tmp_set = set()
    while True:
        line = file.readline()
        if len(line) == 0:
            break
        id = re.split(r'[\[\]]', line)
        # print(id)
        # lambda id[n] !='':tmp_set(id[n])
        if id[n] !='':
            if id[n] not in tmp_set:
                tmp_set.add(id[n])
        # a_set = a_set | tmp_set
    return tmp_set

#统计日志新增的(user_id or profile_id)，判断新增id的标示是否是１(n2位置)， 放入对应的字典里，如果存在把n1(user_id or profile_id)key放入字典，字典的value +1(理论上不应该重复出现)，统计len(dic)
def account_id_add(file,n1,n2,tmp_set):
    while True:
        line = file.readline()
        if len(line) == 0:
            break
        id = re.split(r'[\[\]]', line)
        # print(id[n2])
        if id[n2] == '1':
            if id[n1] not in tmp_set:
                tmp_set.add(id[n1])
    return tmp_set,dic_url

#统计留存(user_id or profile_id)在两个时间的段的对比,把两个时间段的文件分别统计对应的id,放入字典求交集，计算交集个数
def keep_id(file1,file2,n):
    dc1 = account_id(file1,n)
    dc2 = account_id(file2,n)
    return (dc1.keys() & dc2.keys())

def day(n):
    d12 = []
    if dd == 'month':
        n1 = datetime.date.today().day
        n2 = (datetime.date.today() - datetime.timedelta(days=n1)).day
        n3 = (datetime.date.today() - datetime.timedelta(days=(n1+n2))).day
        for i in range(n1, n1+n2+n3):
            d12.append((datetime.date.today() - datetime.timedelta(days=int(i))).strftime('%Y%m%d') + '.log')
        return d12[0:n2], d12[n2:]
    else:
        d = int(n / 2)
        for i in range(1, n + 1):
            d12.append((datetime.date.today() - datetime.timedelta(days=int(i))).strftime('%Y%m%d') + '.log')
        return d12[0:d], d12[d:n]

def fun_call(date1, date2):
    os.chdir(log_path)
    global pv
    for i in date2:
        file2 = open(i,'rU')
        account_id(file2, 5, d2_acc_id_set)
        file2.seek(0, 0)
        account_id(file2, 7, d2_pro_id_set)
    # global acc_id_set
    for i in date1:
        file1 = open(i, "rU")
        account_line(file1)
        file1.seek(0, 0)
        account_id(file1, 5, d1_acc_id_set)
        file1.seek(0, 0)
        account_id(file1, 7, d1_pro_id_set)
        file1.seek(0, 0)
        account_id_add(file1, 5, 17, account_id_add_set)
        file1.seek(0, 0)
        account_id_add(file1, 7, 19, profile_id_add_set)
        # print(acc_id_set)
    print("pv=%s" % pv)
    # print(acc_id_set)
    print(len(d2_acc_id_set))
    print(len(d2_pro_id_set))
    print(account_id_add_set)
    print(profile_id_add_set)
    print(len(d1_acc_id_set & d2_acc_id_set))
    print(len(d1_pro_id_set & d2_pro_id_set))
    print(dic_url)
#把以时间为命名的文件名放入素组
log_path = "/home/dh/log_test"
os.chdir(log_path)
# file2=open("/home/dh/log_test/20161031.log", 'r')
if dd == "day":
    date1,date2 = day(2)
    # account_id(file2,1,acc_id_set)
    fun_call(date1,date2)
elif dd == "week":
    date1, date2 = day(14)
    print(date1)
    fun_call(date1, date2)
elif dd == "month":
    date1, date2 = day(60)
    print(date1)
    fun_call(date1, date2)
    # print(date2)






