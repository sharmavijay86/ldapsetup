#!/bin/bash
#AUTHOR: Vijay Vishwakarma
#MAIL: vijay@mevijay.com
#DATE: 11/3/2020

/usr/bin/kinit admin@CLOUD.VSSI.COM -k -t /usr/local/src/admin.keytab


cd /tmp
THENUMBEROFDAYS=2

USERLIST=$(ldapsearch -x -b cn=users,cn=accounts,dc=cloud,dc=vssi,dc=com | grep '^uid:' | awk '{print $2}')

echo "--------------------------" >> /root/pw.list
for USER in $USERLIST;
do
TODAYSDATE=$(date +"%Y%m%d")

echo "Checking Expiry For $USER" >> /root/pw.list

EXPIRYDATE=$(ipa user-show $USER --all --raw | grep krbPasswordExpiration |awk '{print $2}' | cut -c 1-8)
MAILID=$(ipa user-show $USER --raw | grep mail | awk '{print $2}')

CALCEXPIRY=$(date -d "$EXPIRYDATE" +%j)
CALCTODAY=$(date -d "$TODAYSDATE" +%j)
DAYSLEFT=$(expr $CALCEXPIRY - $CALCTODAY)
echo "$USER has $DAYSLEFT left" >> /root/pw.list

if [ $DAYSLEFT = $THENUMBEROFDAYS ];
then

echo "Dear $USER," >> $USER.temp
echo "Your password is going to expiring or expired. Please change immediatly" >> $USER.temp
echo " " >> $USER.temp
echo "-- Cloud Team" >> $USER.temp

mailx -s "$USER Password expired...." $MAILID < $USER.temp
rm -rf $USER.temp
fi
done
