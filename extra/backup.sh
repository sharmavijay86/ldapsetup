#!/bin/bash
backupdir=/data
if [ ! -d "$backupdir" ];then
mkdir /data
fi
/usr/sbin/slapcat -n 0 -l $backupdir/config`date '+%Y-%m-%d'`.ldif
/usr/sbin/slapcat -n 2 -l $backupdir/data`date '+%Y-%m-%d'`.ldif
