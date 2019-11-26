#!/bin/bash -x

#
#   Merging and backup apache log from multiple web server
#   copyright (c) 2019 Medour Mehdi
#   
#   https://github.com/MedourMehdi
#

#
#   Variables init
#
SITENAME=$1
CONFNAME=`echo "${SITENAME}" |  sed 's/www.//'`
WORKDIR="/var/log/apache2"
SRC_SRV_LIST="web1 web2 web3"
SRC_APACHE_LOG="/var/log/apache2"
MAIL_ADMIN=seo@yourdomain.com
REMOTE_WEB_USER=apacheuser
SSH_KEY_PATH="/var/backups/.ssh/id_rsa_X"
MERGE_SCRIPT="/usr/share/awstats/tools/logresolvemerge.pl"
TMP_WORK_DIR="~/merge"
DEST_DIR="~/merge/all_days"
NFS_BACKUP_DIR="~/logs_web_production/web_logs"

#
#   Active or not SEO suppliers upload
#
FTP_Upload_Active="0"

#
# Domain Name parsing
# Not used in this sample script...
#
FirstLevelNDD="${SITENAME%%.*}"
SecondLevelNDD="${SITENAME%.*}"
ThirdLevelNDD="${SITENAME##*.}"

#
#   Rsync log and log.1 for each web server
#
echo "DIFF log pour ${SITENAME}"
for s in ${SRC_SRV_LIST} ; do
rsync -avz  -e "ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" ${REMOTE_WEB_USER}@$s:${SRC_APACHE_LOG}/access-${SITENAME}.log ${WORKDIR}/$s/
rsync -avz -e "ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" ${REMOTE_WEB_USER}@$s:${SRC_APACHE_LOG}/access-${SITENAME}.log.1 ${WORKDIR}/$s/
done

#
#   Merging three apache logs into one.
#   Dest file is ${TMP_WORK_DIR}/access-${SITENAME}.log.temp
#
for f in access-${SITENAME}.log.1 access-${SITENAME}.log;do
    ${MERGE_SCRIPT} ${WORKDIR}/web1/$f ${WORKDIR}/web2/$f ${WORKDIR}/web3/$f;
done > ${TMP_WORK_DIR}/access-${SITENAME}.log.temp

#
#   This file is created below and contain the last date and hour processed
#   If file is not present we choose an arbitrary date (Yesterday)
#
if [ -f  ${DEST_DIR}/access-${SITENAME}.last.log ];then
                LASTDATE=`cat ${DEST_DIR}/access-${SITENAME}.last.log`;
[ ".${LASTDATE}" == "." ] && LASTDATE=`LC_ALL=en_GB.UTF-8 date --d="-1 day" +"%d/%b/%Y"`
fi;

echo "LASTDATE equal ${LASTDATE}"

#
#   Date format cleaning
#
LASTDATE_2=`echo "${LASTDATE}" | sed 's:/:\\\\/:g'`

echo "${LASTDATE_2}"

#
#   Truncate Apache Log begining from LASTDATE_2
#
`sed -n '/'"${LASTDATE_2}"'/,$'p ${TMP_WORK_DIR}/access-${SITENAME}.log.temp > ${DEST_DIR}/access-${SITENAME}.log`

#
#   Getting date interval information about logs merging
#   Used to store log archive with comprhensive date in filename
#   Also used to create the LASTDATE file.
#
`tail -n 1 ${DEST_DIR}/access-${SITENAME}.log > endfile.temp`;
date=`awk -F " " '{print $4}' endfile.temp | tr "[" " "`;
echo $date > datefile.temp;
day=`awk -F "/" '{print $1}' datefile.temp`;
month=`awk -F "/" '{print $2}' datefile.temp`;
`awk -F "/" '{print $3}' datefile.temp > year.temp`;
year=`awk -F ":" '{print $1}' year.temp`;
DATE2=`date -d "${day} ${month} ${year}" +"%Y%m%d"`;

#
#   Keep it for next merge
#
cp datefile.temp  ${DEST_DIR}/access-${SITENAME}.last.log

`head -1 ${DEST_DIR}/access-${SITENAME}.log > startfile.temp`;
date=`awk -F " " '{print $4}' startfile.temp | tr "[" " "`;echo $date > datefile.temp;
day=`awk -F "/" '{print $1}' datefile.temp`;
month=`awk -F "/" '{print $2}' datefile.temp`;
`awk -F "/" '{print $3}' datefile.temp > year.temp`;
year=`awk -F ":" '{print $1}' year.temp`;
DATE1=`date -d "${day} ${month} ${year}" +"%Y%m%d"`

#
#   Cleaning tmp files
#
rm year.temp;rm datefile.temp;rm startfile.temp;rm endfile.temp;

mv ${DEST_DIR}/access-${SITENAME}.log ${DEST_DIR}/access-${SITENAME}.${DATE1}-${DATE2}.log

#
#   Archiving
#
gzip --force ${DEST_DIR}/access-${SITENAME}.${DATE1}-${DATE2}.log

#
#   Store in safe place
#
cp -a ${DEST_DIR}/access-${SITENAME}.${DATE1}-${DATE2}.log.gz ${NFS_BACKUP_DIR}/access-${SITENAME}.${DATE1}-${DATE2}.log.gz

#
# FTP Upload example
#
USER="ftp_user"
PASSWD="my_pass"
HOST="ftp.wedoseo4you.com"

if [ ${FTP_Upload_Active} -gt 0 ];then
        FTPSTATUS=`curl  -s -w '%{http_code}' -u ${USER}:${PASSWD} -T ${DEST_DIR}/access-${SITENAME}.${DATE1}-${DATE2}.log.gz ftp://${HOST}/`
        if [ "${FTPSTATUS}" = "226"  ]; then
                DATE_SEND=`date +"%Y%m%d%H"`
                echo "${DATE_SEND} access-${SITENAME}.${DATE1}-${DATE2}.log.gz done. FTP Status ${FTPSTATUS}" >> /tmp/log_FTP_Upload_OK_ftp.log
        else
                echo "${DATE_SEND} access-${SITENAME}.${DATE1}-${DATE2}.log.gz error. FTP Status ${FTPSTATUS}" >> /tmp/log_FTP_Upload_ftp.log
                echo "${DATE_SEND} access-${SITENAME}.${DATE1}-${DATE2}.log.gz error. FTP Status ${FTPSTATUS}" | tee /dev/tty | mail -s 'FTP_Upload Error' ${MAIL_ADMIN}
        fi
fi