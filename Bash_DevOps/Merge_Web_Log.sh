#!/bin/bash -x

#
#   Variables init
#
SITENAME=$1
CONFNAME=`echo "${SITENAME}" |  sed 's/www.//'`
WORKDIR="/var/log/apache2"
MAIL_ADMIN=seo@yourdomain.com
REMOTE_WEB_USER=apacheuser

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
for s in web1 web2 web3 ; do
rsync -avz  -e "ssh -i /var/backups/.ssh/id_rsa_amdump_new -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" ${REMOTE_WEB_USER}@$s:/var/log/apache2/access-${SITENAME}.log /var/log/apache2/$s/
rsync -avz -e "ssh -i /var/backups/.ssh/id_rsa_amdump_new -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" ${REMOTE_WEB_USER}@$s:/var/log/apache2/access-${SITENAME}.log.1 /var/log/apache2/$s/
done

#
#   Merging three apache logs into one.
#   Dest file is ~/merge/access-${SITENAME}.log.temp
#
for f in access-${SITENAME}.log.1 access-${SITENAME}.log;do
    /usr/share/awstats/tools/logresolvemerge.pl ${WORKDIR}/web1/$f ${WORKDIR}/web2/$f ${WORKDIR}/web3/$f;
done > ~/merge/access-${SITENAME}.log.temp

#
#   This file is created below and contain the last date and hour processed
#   If file is not present we choose an arbitrary date (Yesterday)
#
if [ -f  ~/merge/all_days/access-${SITENAME}.last.log ];then
                LASTDATE=`cat ~/merge/all_days/access-${SITENAME}.last.log`;
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
`sed -n '/'"${LASTDATE_2}"'/,$'p ~/merge/access-${SITENAME}.log.temp > ~/merge/all_days/access-${SITENAME}.log`

#
#   Getting date interval information about logs merging
#   Used to store log archive with comprhensive date in filename
#   Also used to create the LASTDATE file.
#
`tail -n 1 ~/merge/all_days/access-${SITENAME}.log > endfile.temp`;
date=`awk -F " " '{print $4}' endfile.temp | tr "[" " "`;

echo $date > datefile.temp;

day=`awk -F "/" '{print $1}' datefile.temp`;
month=`awk -F "/" '{print $2}' datefile.temp`;
`awk -F "/" '{print $3}' datefile.temp > year.temp`;
year=`awk -F ":" '{print $1}' year.temp`;

DATEDEBUT=`date -d "${day} ${month} ${year}" +"%Y%m%d"`;

echo "DATEDEBUT equal ${DATEDEBUT}"

cp datefile.temp  ~/merge/all_days/access-${SITENAME}.last.log

`head -1 ~/merge/all_days/access-${SITENAME}.log > startfile.temp`;
date=`awk -F " " '{print $4}' startfile.temp | tr "[" " "`;echo $date > datefile.temp;
day=`awk -F "/" '{print $1}' datefile.temp`;
month=`awk -F "/" '{print $2}' datefile.temp`;
`awk -F "/" '{print $3}' datefile.temp > year.temp`;
year=`awk -F ":" '{print $1}' year.temp`;
DATEFIN=`date -d "${day} ${month} ${year}" +"%Y%m%d"`

echo "DATEFIN equal ${DATEFIN}"

rm year.temp;rm datefile.temp;rm startfile.temp;rm endfile.temp;

`mv ~/merge/all_days/access-${SITENAME}.log ~/merge/all_days/access-${SITENAME}.${DATEFIN}-${DATEDEBUT}.log`

#if [ ${LogStash_Active} -gt 0 ];then
#       $(cp ~/merge/all_days/access-${SITENAME}.${DATEFIN}-${DATEDEBUT}.log /var/backups/merge/logstash/)
#fi

#
#   Archiving
#
`gzip --force ~/merge/all_days/access-${SITENAME}.${DATEFIN}-${DATEDEBUT}.log`

#
#   Store in safe place
#
`cp -a ~/merge/all_days/access-${SITENAME}.${DATEFIN}-${DATEDEBUT}.log.gz ~/logs_web_production/web_logs/access-${SITENAME}.${DATEFIN}-${DATEDEBUT}.log.gz`

echo "Fin ${SITENAME}"

#
# FTP Upload example
#
USER="ftp_user"
PASSWD="my_pass"
HOST="ftp.wedoseo4you.com"

if [ ${FTP_Upload_Active} -gt 0 ];then
        FTPSTATUS=`curl  -s -w '%{http_code}' -u ${USER}:${PASSWD} -T ~/merge/all_days/access-${SITENAME}.${DATEFIN}-${DATEDEBUT}.log.gz ftp://${HOST}/`
        if [ "${FTPSTATUS}" = "226"  ]; then
                DATE_SEND=`date +"%Y%m%d%H"`
                echo "${DATE_SEND} access-${SITENAME}.${DATEFIN}-${DATEDEBUT}.log.gz done. FTP Status ${FTPSTATUS}" >> /tmp/log_FTP_Upload_OK_ftp.log
        else
                echo "${DATE_SEND} access-${SITENAME}.${DATEFIN}-${DATEDEBUT}.log.gz error. FTP Status ${FTPSTATUS}" >> /tmp/log_FTP_Upload_ftp.log
                echo "${DATE_SEND} access-${SITENAME}.${DATEFIN}-${DATEDEBUT}.log.gz error. FTP Status ${FTPSTATUS}" | tee /dev/tty | mail -s 'FTP_Upload Error' ${MAIL_ADMIN}
        fi
fi