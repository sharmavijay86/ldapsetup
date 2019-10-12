# Enterprise grade OpenLdap server setup

This programme is a simple shell script which helps you to install and setup opendlap server on any of redhat 7 family OS.
The programme includes two ldif files base and ldap
ldap.ldif file used in setting up the opendlap server and base.ldif is used to create two basic Orgnizational units
People and Group.

**REPO Name**  <https://github.com/sharmavijay86/ldapsetup>

## requirement

Before running the script you have to install packages 
```
$ sudo yum install openldap-servers git -y
```
pull the github repository
```
$ git clone https://github.com/sharmavijay86/ldapsetup
```
change current directory 
```
$ cd ldapsetup
```
then you should generate ldap admin password and paste to **ldap.ldif** file olcRootPW section
```
$ slappaasswd
```
replace this line exiting password with your generated password
```
olcRootPW: {SSHA}498kL0rtehyoFDxWz5BdGjkhjhWxnb
```
Now you can proceed to run install script

## How to run script and install openldap server?

make script executable
```
$ chmod +x install.sh
```
run the script
```
$ ./install.sh
```
or
```
$ sudo bash install.sh
```
The script will generate TLS certificate hence it will ask few information for ssl,  provide details and hit enter
The script will ask for admin password while creating base OU viz. People and Group. Provide the admin password which you have created with slappasswd command
### enable ssl comunication 
the script will generate already required self signed certificate for you. You need to enable ldaps protocol to enable.
```
 $ vim /etc/sysconfig/slapd

SLAPD_URLS="ldapi:/// ldap:/// ldaps:///"

```
after modification as given above restart slapd service 
```
$ systemctl restart slapd
```
A success message shows you have setup and configured openldap server in your CentOs 7 linux box.
Additionaly in order to explore the cn=config information  use bellow command
```
$ldapsearch -LLLQY EXTERNAL -H ldapi:/// -b cn=config "(|(cn=config)(olcDatabase={2}hdb))"
```
## How to setup CentOs 7 client  to use Authentication with ldap server?

In order to authenticate a ldap user from client  box you must configure ldap on client machine.
```
$ sudo yum install openldap-clients -y

$ sudo authconfig --enableldap --enableldapauth --ldapserver="ldap://ldap.example.local" --ldapbasedn="dc=example,dc=local" --enablemkhomedir --enableshadow --update
```
Replace  above command values of basedn and ldapserver with yours one.
## Usefull commands
- ldapadd -x -D cn=admin,dc=example,dc=com  -W -f adduser.ldif
- ldapsearch -D cn=admin,dc=example,dc=com -b dc=example,dc=com -xLLL -W 
**Assign password to user**
- ldappasswd -s password123 -W -D "cn=admin,dc=example,dc=com" -x "uid=raj,ou=People,dc=example,dc=com"
- ldapdelete -W -D "cn=admin,dc=example,dc=com" "uid=user1,ou=People,dc=example,dc=com"
**Adding schema**
- ldapmodify -Y EXTERNAL  -H ldapi:/// -f monitor.ldif

### setup logging 
```
vi /etc/rsyslog.conf
```
Add below line to /etc/rsyslog.conf file.
```
local4.* /var/log/ldap.log
```
restart rsyslog service
```
systemctl restart rsyslog
```
### Ldap server managment
This git repo contains one ldap.sh file in extra directry which can be used to manage the whole ldap server- It provides bellow facility-

1. You can create single user
2. You can create bulk users from a csv file
3. You can change a users password
4. You can set account expiry date for a user
5. You can change a users account expiry date

### Backup and restore
Ldap server backup setup needs to backup the hdb database ( db2 ) and the full ldif export as file

A Backup script is present in extra directory which can be used to backup the ldif and database.
