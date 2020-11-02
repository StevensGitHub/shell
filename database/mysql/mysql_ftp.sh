#! /bin/bash
#########################Basic parameters####################
DAY=`date +%Y%m%d`
USER="root"
PASSWD="O81LZfS8jSEKOrM="
HostPort="3306"
DATADIR="/opt/backups"
MYSQL=`/usr/bin/which mysql`
MYSQLDUMP=`/usr/bin/which mysqldump`

Dump(){
  cd ${DATADIR}
  rm -rf ${database}-${DAY}.sql.gz
  ${MYSQLDUMP} --master-data=2 --single-transaction --routines --triggers --events -u${USER} -p${PASSWD} -P${HostPort} ${database} > ${DATADIR}/${database}-${DAY}.sql
  gzip ${database}-${DAY}.sql
}

for db in `echo "SELECT schema_name FROM information_schema.schemata where schema_name not in ('information_schema', 'sys', 'performance_schema', 'mysql')" | ${MYSQL} -u ${USER} -p${PASSWD} --skip-column-names 2>/dev/null`
do
        database=${db}
        Dump
done

# clean history compress package
find $DATADIR -mtime +7 -type f -name "*.gz" -exec rm -rf {} \;

# upload backup for mysql
PUTFILE=${database}-${DAY}.sql.gz
ftp -v -n 192.168.192.129<<EOF
user bwtdb bwtdb@123
binary
cd ./
lcd $DATADIR
prompt
put $PUTFILE
bye
#here document
EOF
echo "commit to ftp successfully"
