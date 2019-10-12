#!/bin/bash
#AUTHOR : Vijay Sharma
#Mail: sharmavijay86@gmail.com

#About :-  This is a admin script for 389 Directory server or openldap server
#          This script will help administrators to do some administrative tasks 
#          very easily e.g. to create a user, delete a user, bulk user creation by csv file
#          changing a users password etc..
function fcheck() {
	if [ $? == 0 ];then
	echo "command completed successfully!!..."
	else
	echo "Something went wrong.."
	fi
}


clear
echo "________________________________________________________"
echo " ***************  Ldap Administration  *****************"
echo "========================================================"
if [ ! -f conn.txt ];then
touch conn.txt
echo "_______________________________________________"
echo -e "This is one time setup.The credential will get \n store in a file named conn.txt and will have \n read permission only to the user who is running this script"
echo "_______________________________________________"
echo -e "\n"
echo -n "Type ldap server address :"
read srv
echo -n "Type base dn  :"
read bsdn
echo -n "Type admin bind dn :"
read admndn
echo -n "Type mail domain name :"
read maild
echo -n "Type admin passowrd: "
read -s passd
printf "\n"

echo "server:$srv" >conn.txt
echo "basedn:$bsdn" >>conn.txt
echo "binddn:$admndn" >>conn.txt
echo "passwd:$passd" >>conn.txt
echo "domain:@$maild" >>conn.txt
chmod 400 conn.txt
echo " testing connectivity with ldap server...."
ldapsearch -xLLL -D "cn=$admndn" -h $srv -w $passd ou=People -b $bsdn >>/dev/null
	if [ $? == 0 ];then
	echo " connected with ldap server"
	else
	echo -e  "connection to ldap server failed \n if you are using debian based os please run command sudo apt-get install ldap-utils \n and if you are using redhat based os then run command yum install openldap-clients"
	fi
	  

else
echo "connection file to ldap server exist! "
fi


admndn=`cat conn.txt | grep binddn | awk -F":" '{print $2}'`
srv=`cat conn.txt | grep server | awk -F":" '{print $2}'`
passd=`cat conn.txt | grep passwd | awk -F":" '{print $2}'`
bsdn=`cat conn.txt | grep basedn | awk -F":" '{print $2}'`
maild=`cat conn.txt | grep domain | awk -F":" '{print $2}'`

while true
do
echo "============================================="
echo "********* ||  Ldap Task Menu  || **********"
echo "============================================="
echo -e "\n"
echo "Type s to search a user!"
echo "Type l to find last uid!"
echo "Type c to create a new user!"
echo "Type p to change password!"
echo "Type d to delete a user!"
echo "Type t to take backup in ldif format and save to home"
echo "Type b to create bulk users with csv file!"
echo "Type e to set a user account expiry"
echo "Type x to exit :"
echo -n "Type you option here :"
read option
echo -e "\n\n"


case $option in
s|S)
	echo -n "Type login id of user to search :"
	read user
	user1=`ldapsearch -xLLL -D "cn=$admndn" -h $srv -w $passd uid=$user -b $bsdn`
	user2=`ldapsearch -xLLL -D "cn=$admndn" -h $srv -w $passd uid=$user -b $bsdn |grep uid: | awk  '{print $2}'`
	
	if [ "$user" == "$user2" ];then
	echo "____________________________________________"
	echo "$user1"
	else 
	echo "================================="
	echo "User does not exist in system .."
	echo "================================="
	fi	
	fcheck
	;;
l|L)
	echo -n "Last uidNumber used by server is :"; ldapsearch -x -D "cn=$admndn" -h $srv -w $passd -b $bsdn | grep uidNumber | awk  '{print $2}'| sort -n | tail -1
 fcheck;;
c|C)
	touch singleuser.ldif
	while true
	do
	echo -n "Type Login ID :"
	read clida
	lidcheck=`ldapsearch -xLLL -D "cn=$admndn" -h $srv -w $passd uid=$clida -b $bsdn |grep uid: |awk '{print $2}'`
	
	 if [ "$clida" != "$lidcheck" ];then
	   echo "dn: uid=$clida,ou=People,$bsdn" >singleuser.ldif
	   echo "uid: $clida" >>singleuser.ldif
	   break
	 else
	  echo "User ID you typed already exist"
	fi
	 done
	echo -n "Type First name of user :"
	read fname
	echo "givenName: $fname" >>singleuser.ldif
	echo -n "Type Last name of user :"
	read lname
	echo "sn: $lname" >>singleuser.ldif
	while true
	do
	echo -n "Enable shell access for user? y/n:"
	read ush
	if [ "$ush" == "y" ];then
	echo "loginShell: /bin/bash" >>singleuser.ldif
	break
	elif [ "$ush" == "n" ];then
	echo "loginShell: /sbin/nologin" >>singleuser.ldif
	break
	elif [ "$ush" == "*" ];then
	echo "Wrong choice Please enter y or n only "
	fi
	done
	cluidnumber=`ldapsearch -x -D "cn=$admndn" -h $srv -w $passd -b $bsdn | grep uidNumber | awk '{print $2}'| sort -n | tail -1`
	cluidnum=`expr $cluidnumber + 1`
	echo "uidNumber: $cluidnum" >>singleuser.ldif
	echo "gidNumber: 2110" >>singleuser.ldif
	echo "shadowMax: 99999" >>singleuser.ldif
	echo "mail: $clida`cat conn.txt | grep domain | awk -F":" '{print $2}'`" >>singleuser.ldif
	echo "objectClass: person" >>singleuser.ldif
	echo "objectClass: top" >>singleuser.ldif
	echo "objectClass: inetOrgPerson" >>singleuser.ldif
	echo "objectClass: posixAccount" >>singleuser.ldif
	echo "objectClass: shadowAccount" >>singleuser.ldif
	echo "cn: $fname $lname">>singleuser.ldif
	echo -n "Type users homedirectory :"
	read hm
	echo "homeDirectory: $hm">>singleuser.ldif
	echo -n "Type user password :"
	read -s upassd
	echo -n "userPassword: $upassd">>singleuser.ldif
	echo -n "Account expiry date (yyyymmdd):"
        read accexp
        echo -n "shadowExpire: ">>singleuser.ldif
        echo  `date -u -d $accexp +%s` /24/60/60 |bc >>singleuser.ldif
	
	ldapadd -D "cn=$admndn" -h $srv -f singleuser.ldif -w $passd
	echo "_____________________________________________________________"
	fcheck
        rm -f singleuser.ldif ;; 
p|P)	
	while true
	do
	echo -n "Type user's Login ID :"
	read pulid
        user2=`ldapsearch -xLLL -D "cn=$admndn" -h $srv -w $passd uid=$pulid -b $bsdn |grep uid: | awk  '{print $2}'`
        if [ "$pulid" != "$user2" ];then
        echo "================================="
        echo "User does not exist in system .."
        echo "================================="
        else
	touch changepasswd.ldif
	echo "dn: uid=$pulid,ou=People,$bsdn" > changepasswd.ldif
	break
	fi
	done
	echo "changetype: modify" >>changepasswd.ldif
	echo "replace: userPassword" >>changepasswd.ldif
	echo -n "Type a new password :"
	read -s npass
	echo "userPassword: $npass" >>changepasswd.ldif
	ldapadd -D "cn=$admndn" -h $srv -f changepasswd.ldif -w $passd
	rm -f changepasswd.ldif
	echo "______________________________________________________________"
	fcheck;;
e|E)
	 while true
        do
        echo -n "Type user's Login ID :"
        read pulid
        user2=`ldapsearch -xLLL -D "cn=$admndn" -h $srv -w $passd uid=$pulid -b $bsdn |grep uid: | awk  '{print $2}'`
        if [ "$pulid" != "$user2" ];then
        echo "================================="
        echo "User does not exist in system .."
        echo "================================="
        else
        echo "dn: uid=$pulid,ou=People,$bsdn" > ldapexpire.ldif
        break
        fi
        done
	echo "changetype: modify" >>ldapexpire.ldif
        echo "replace: shadowExpire" >>ldapexpire.ldif
	echo "Account expiry date (yyyymmdd):"
        read accexp
        echo -n "shadowExpire: ">>ldapexpire.ldif
	echo  `date -u -d $accexp +%s` /24/60/60 |bc >>ldapexpire.ldif

        ldapmodify -D "cn=$admndn" -h $srv -f ldapexpire.ldif -w $passd
	rm -f ldapexpire.ldif
	fcheck;;


d|D)
	while true
	do
	echo -n "Type User id to delete :"
        read udd
	user2=`ldapsearch -xLLL -D "cn=$admndn" -h $srv -w $passd uid=$udd -b $bsdn |grep uid: | awk  '{print $2}'`
        if [ "$udd" != "$user2" ];then
        echo "================================="
        echo "User does not exist in system .."
        echo "================================="
        else
        ldapdelete -v uid=$udd,ou=People,$bsdn -D "cn=$admndn" -h $srv -w $passd
        echo "_______________________________________________________________"
       echo "Deleted successfully........" 
	break
	fi
	done;;

b|B)

	echo -n "Type File name e.g. /home/bulkuser.csv :"
	read bulkfile
	echo -n "Give users homedirectory base trailing / e.g. /home/ :"
	read homedir
	cluidnumber=`ldapsearch -x -D "cn=$admndn" -h $srv -w $passd -b $bsdn | grep uidNumber | awk '{print $2}'| sort -n | tail -1`
        cluidnum=`expr $cluidnumber + 1`
 	echo "BEGIN {" >bulkuser.awk
	echo "start_uid = $cluidnum;" >>bulkuser.awk
	echo "start_gid = 2110;" >>bulkuser.awk
	echo "i=0">>bulkuser.awk
	echo "}" >>bulkuser.awk
	echo "{" >>bulkuser.awk
	echo "print \"dn: uid=\"\$1\",ou=People,$bsdn"\" >>bulkuser.awk
	echo "print \"givenName: \",\$2" >>bulkuser.awk
	echo "print \"sn: \",\$3" >>bulkuser.awk
	echo -n "Enable shell access for user? y/n :"
        read shl
        if [ "$shl" == "y" ];then
	echo "print \"loginShell: /bin/bash\"" >>bulkuser.awk
	else
	echo "print \"loginShell: /sbin/nologin\"" >>bulkuser.awk
	fi
	echo "print \"uidNumber: \"(start_uid+i);" >>bulkuser.awk
	echo "print \"gidNumber: 2110\"" >>bulkuser.awk
	echo "print \"shadowMax: 99999\"" >>bulkuser.awk
	echo "print \"mail: \"\$1\"$maild\"" >>bulkuser.awk
	echo "print \"objectClass: top\"" >>bulkuser.awk
	echo "print \"objectClass: person\"" >>bulkuser.awk
	echo "print \"objectClass: inetOrgPerson\"" >>bulkuser.awk
	echo "print \"objectClass: posixAccount\"" >>bulkuser.awk
	echo "print \"objectClass: shadowAccount\"" >>bulkuser.awk
	echo "print \"uid: \"\$1" >>bulkuser.awk
	echo "print \"cn: \"\$2\$3" >>bulkuser.awk
	echo "print \"homeDirectory: $homedir\"\$1" >>bulkuser.awk
	echo "print \"userPassword: \"\$2 \$1" >>bulkuser.awk
	echo "print \"\\n\";" >>bulkuser.awk
	echo "i++;" >>bulkuser.awk
	echo "}" >>bulkuser.awk
	awk  -F";" -f bulkuser.awk $bulkfile > /tmp/ldapuser.ldif
	while true
	do
	echo  "Press 1 to create users into your ldap server"
	echo  "Press 2 to display ldif file"
	echo  "Press 3 to exit application"
	echo -n "Option :"
	read answer
	if [ "$answer" -eq 1 ];then
	ldapadd -D "cn=$admndn" -h $srv -f /tmp/ldapuser.ldif -w $passd
	elif [ "$answer" -eq 2 ];then
	cat /tmp/ldapuser.ldif
	elif [ "$answer" -eq 3 ];then
	break
	fi
	done
	rm -f bulkuser.awk;;	
t|T)

	
	bakdir=$HOME
	ldapsearch -xLLL -D "cn=$admndn" -h $srv -w $passd -b $bsdn objectClass=* >$bakdir/fullldapbkp.ldif
	fcheck;;
x|X)exit;;
*) echo "Wrong Choice! Please select correct option menu!";;
esac
done


