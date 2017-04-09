# ldapsetup

This programme is a simple shell script which helps you to install and setup opendlap server on any of redhat 7 family OS.
The programme includes two ldif files base and ldap
ldap.ldif file used in setting up the opendlap server and base.ldif is used to create two basic Orgnizational units
People and Group.

# requirement

Before running the script you have to install packages 

$ sudo yum install openldap-servers git -y

pull the github repository

$ git clone https://github.com/sharmavijay86/ldapsetup

change current directory 

$ cd ldapsetup

then you should generate ldap admin password and paste to ldap.ldif file olcRootPW section

$ slappaasswd

replace this line exiting password with your generated password

olcRootPW: {SSHA}498kL0rtehyoFDxWz5BdGjkhjhWxnb

Now you can proceed to run install script

# How to run script and install openldap server?

make script executable

$ chmod +x install.sh

run the script

$ ./install.sh

or

$ sudo bash install.sh

The script will generate TLS certificate hence it will ask few information for ssl,  provide details and hit enter
The script will ask for admin password while creating base OU viz. People and Group. Provide the admin password which you have created with slappasswd command

A success message shows you have setup and configured openldap server in your CentOs 7 linux box.
Additionaly in order to explore the cn=config information  use bellow command

$ldapsearch -LLLQY EXTERNAL -H ldapi:/// -b cn=config "(|(cn=config)(olcDatabase={2}hdb))"

# How to setup CentOs 7 client  to use Authentication with ldap server?

In order to authenticate a ldap user from client  box you must configure ldap on client machine.

$ sudo yum install openldap-clients -y

$ sudo authconfig --enableldap --enableldapauth --ldapserver="ldap://ldap.example.local" --ldapbasedn="dc=example,dc=local" --enablemkhomedir --enableshadow --update

Replace  above command values of basedn and ldapserver with yours one.
