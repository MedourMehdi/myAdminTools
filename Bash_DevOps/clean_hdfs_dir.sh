#!/bin/bash

# We want to recursively remove the 60 days older directories from Hadoop Cluster
now=$(date +%s)
# Path in HDFS where we're going to delete old folder
path="/DataLake/raw/to_compute"
# If we need to remove a specific pattern folder
my_pattern="comp_"

#
# Email stuff.
# Note that we send an html email wuth green color for success and red if not.
#
HOST=$(hostame -f)
SUBJECT="HDFS CLEANING RESULT $(date)"
MAIL_FROM="hdfs@${HOST}"
MAIL_TO="datalog@yourdomain.tld"

# Main function
hadoop fs -ls -R ${path} | grep "^d" | grep "${my_pattern}" | (while read f; do

    # Diff between today and the last file modification
    dir_date=`echo $f | awk '{print $6}'`
    difference=$(( ( $now - $(date -d "$dir_date" +%s) ) / (24 * 60 * 60 ) ))
    # If more than 60 days
    if [ $difference -gt 60 ]; then
        dir2del=$(echo "${f}" | awk -F" " '{print $8}');
        echo "${dir2del}"
        # We delete the folder
        hadoop fs -rm -r -skipTrash ${dir2del};
        # If success Green line in HTML email
        if [ "$?" -eq "0" ];then My_Message="${My_Message}\n <p><font color=\"green\">RMDIR ok ${dir2del}</font></p>";
        # Else Red
        else  My_Message="${My_Message}<p><font color=\"green\">ERROR - Check rmdir for ${dir2del}</font></p>\n";
        fi
    fi
done
# And we send it - That's it.
echo -e "Subject: $SUBJECT\nMIME-Version: 1.0\nFrom: $MAIL_FROM\nTo:$MAIL_TO\nContent-Type: text/html\nContent-Disposition: inline\n\n${My_Message}" | /usr/sbin/sendmail -f  $MAIL_FROM $MAIL_TO
)