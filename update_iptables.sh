#!/bin/bash

#curl -L http://etcd.dev.cim.in:4001/v2/keys/iptable/ip -XPUT -d value="192.168.1.11 192.168.1.12 192.168.1.13"
#curl -L http://etcd.dev.cim.in:4001/v2/keys/iptable/port -XPUT -d value="22,8015,2379,4000,3308,3306"


url=etcd.dev.cim.in:2379
f_ip1=/tmp/server_ip1
f_ip2=/tmp/server_ip2
f_port1=/tmp/server_port1
f_port2=/tmp/server_port2

server_ip=$(http http://"$url"/v2/keys/iptable/ip|egrep value|awk -F'"' '{print $14}')
server_port=$(http http://"$url"/v2/keys/iptable/port|egrep value|awk -F'"' '{print $14}')

function do_iptable(){
    for i in $server_ip;do
        iptables -I INPUT -p TCP -m multiport --destination-port $server_port -s $i -j ACCEPT
    done   
}
test -f /tmp/server_ip1 || { do_iptable; echo $server_ip|tee $f_ip1 $f_ip2; echo $server_port|tee $f_port1 f_port1 ; exit 0 }
{diff $f_ip1 $f_ip2 && diff $f_port1 $f_port2  && exit 0 ; } || do_iptable
