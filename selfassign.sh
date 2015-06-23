#!/bin/sh

# This was a quick and dirty beginning of a hack to self
# assign a viable ipv6 address in a a source specific 
# environment.

# hostname device number address
# shortestpath fastestpath

CONF=/etc/ipv6assign.conf
MYCONF=/tmp/ipv6assign.conf
IFACE=eth0
vsec=600
hsec=300
H=`hostname`

getaddrs() {

ip -6 route | grep '^default from' | grep / | while read d f addr via splat
do
	mask=`echo $addr | cut -f2 -d/`
	a=`echo $addr | cut -f1 -d/`
	echo $a/$mask
done
}

parse() {

if [ -s $CONF ]
then
grep ^${H} $CONF | while read h d n a
do
	echo $d
done
fi

}

shortestpath() {
c1=254
for i in $*
do
c=`traceroute6 -n ${i}1 | wc -l`
if [ $c -lt $c1 ]
then
	c1 = $c
	a=$i
fi
done
}

fastestpath() {
p1=256
a=""
for i in $*
do
	ping6 -c 2 ${i}1 > /dev/null # clear the path
	p=`ping6 -c 5 ${i}1 | tail -1 | cut -f5 -d/ | cut -f1 -d.`
		if [ "$p" -lt "$p1" ]
		then
			p1=$p
			a=$i
		fi
done
echo $a
}

mac=`cat /sys/class/net/$IFACE/address`

while :
do
parse
B=""
for i in `getaddrs`
do
	B="$B `echo $i | cut -f1 -d/`"
done
# No! ideally take this route from the top of the range
N=fd04::
ula=`ipv6calc --in prefix+mac $N $mac --out ipv6`
ip -6 addr replace ${ula}/128 dev $IFACE valid_lft $vsec preferred_lft $hsec
# Now we have to wait a bit

# to just add one
#N=`fastestpath $B`
for N in $B
do
addme=`ipv6calc --in prefix+mac $N $mac --out ipv6`
ip -6 addr replace ${addme}/128 dev $IFACE valid_lft $vsec preferred_lft $hsec
done
ip -6 addr del ${ula}/128 dev $IFACE
sleep 60
done

# then register this darn address somewhere else
# nsupdate?
