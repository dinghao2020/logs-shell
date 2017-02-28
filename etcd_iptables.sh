#!/bin/bash


set -oe pipefail
url_host="etcd01.cimhealth.in"
ping -l 1 -c3 -W1 ${usrl_host} || { echo "can't ping,May be cant't reslove address " && exit 0; }
nc -v -w 2 -z ${url_host} 2379 || {echo "Please check remote server iptables" && exit 0; }
which http||{ echo "Please install httpie" && exit 0; }
url="http://etcd01.cimhealth.in:2379"
f_ip1=/tmp/server_ip1
f_ip2=/tmp/server_ip2
f_port1=/tmp/server_port1
f_port2=/tmp/server_port2

server_ip=$(http "$url"/v2/keys/iptable/ip|egrep value|awk -F'"' '{print $14}')
server_port=$(http "$url"/v2/keys/iptable/port|egrep value|awk -F'"' '{print $14}')

function clean_iptable(){
    /sbin/iptables -P INPUT ACCEPT
    /sbin/iptables -P OUTPUT ACCEPT
    /sbin/iptables -P FORWARD ACCEPT
    /sbin/iptables -F
    /sbin/iptables -X
    /sbin/iptables -Z
    /sbin/iptables-save
}
function do_iptable(){
    for i in $server_ip;do
        /sbin/iptables -I INPUT -p TCP -m multiport --destination-port $server_port -s $i -j ACCEPT
    done   
    /sbin/iptables -A INPUT -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT
    /sbin/iptables -A INPUT -p tcp -m multiport --destination-port $server_port -s 0.0.0.0/0 -j DROP
}
function update_file(){
    echo $server_ip|tee $f_ip1
    echo $server_port|tee $f_port1
    diff $f_ip1 $f_ip2 && diff $f_port1 $f_port2 || { clean_iptable && do_iptable;echo $server_ip|tee $f_ip1 $f_ip2 && echo $server_port|tee $f_port1 $f_port2; }
}
test -f /tmp/server_ip1 || { clean_iptable && do_iptable &&  echo $server_ip|tee $f_ip1 $f_ip2 && echo $server_port|tee $f_port1 $f_port2 &&  exit 0 ; }
update_file
