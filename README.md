# ldapsetup
This programme is a simple shell script which helps you to install and setup opendlap server on any of redhat 7 family OS.
The programme includes two ldif files base and ldap
ldap.ldif file used in setting up the opendlap server and base.ldif is used to create two basic Orgnizational units
1. People 
2. Group
#requirement
Before running the script you have to install packages 
$ sudo yum install openldap-servers opendlap-clients -y
then you should generate ldap admin password and paste to ldap.ldif file olcAccessPW section
$ slappaasswd

replace this line exiting password with your generated password


# How to run?
$ chmod +x install.sh
$ ./install.sh
