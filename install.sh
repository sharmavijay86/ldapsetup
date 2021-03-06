#!/bin/bash
# AUTHOR: Vijay Sharma
# MAIL: sharmavijay86@gmail.com
# Web: mevijay.in
# About: the script is about how to install openldap server in RHEL 7 or Centos 7. 
clear
printf "******************OpenLdap installer RHEL 7**************** \n"
yum install openldap-clients openldap-servers -y
if [ -f ./ldap.ldif ];
then
        echo "setting up..."
else
        echo "ldap.ldif does not exist copy to current dir"
        echo "Both ldap.ldif and base.ldif files are mandatory for setup.."
        echo "If above two files are not in current directory copy to current directory then run script again"
        echo "installation inturupted try again"
        exit
fi
printf "Enter base dn e.g.  dc=example,dc=com:"
read DOMN
sed  -i "s/dc\=example\,dc\=local/$DOMN/g" ldap.ldif
sed  -i "s/dc\=example\,dc\=local/$DOMN/g" base.ldif
sed -i "s/dc\=example\,dc\=local/$DOMN/g" acl.ldif
CERTVER=$(echo $DOMN |awk -F"=" '{print $2}' | cut -d, -f1)
sed -i "s/example/$CERTVER/g" ldap.ldif
sed -i "s/example/$CERTVER/g" base.ldif
printf "Generating certificates\n"
systemctl enable slapd
systemctl restart slapd
openssl req -subj '/CN=crazytechindia.com/O=Crazy Tech India/C=IN' -new -newkey rsa:2048 -sha256 -x509 -nodes -out /etc/openldap/certs/crt$CERTVER.pem -keyout /etc/openldap/certs/key$CERTVER.pem -days 365
chown -R ldap:ldap /etc/openldap/certs/*.pem
ldapadd -Y EXTERNAL -H ldapi:/// -f ldap.ldif
slaptest -u
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
chown ldap:ldap /var/lib/ldap/*
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
echo "Importing first OU as People and Group. You must be asked to provide admin password.."
ldapadd -x -W -D "cn=admin,$DOMN" -f base.ldif
ldapmodify -QY EXTERNAL -H ldapi:/// -D cn=admin,cn=config -f acl.ldif
firewall-cmd --permanent --add-service=ldap
firewall-cmd --reload
echo "Installation completed !! "
