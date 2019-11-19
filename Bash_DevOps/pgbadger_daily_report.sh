#!/bin/bash

#
#   Build and Send a daily pgbadger report by email in attachment using mutt
#   copyright (c) 2019 Medour Mehdi
#   
#   https://github.com/MedourMehdi
#

#
#   Assuming that locale lang is english and
#   thet postgresql is configured with:
#   log_directory = '/var/log/postgresql'
#   log_filename = 'postgresql-%a.log'
#

PGLOG_DIR="/var/log/postgresql"
PG_LOGFILE="postgresql-$(LANG=en_GB date --date yesterday +%a).log"
PGBADGER_FILENAME="pgbadger_$(LANG=en_GB date --date yesterday +%a).html"
ENV="CLOUD PROD"
HOST=$(hostame -f)

dependencie_check(){
    type -a mutt > /dev/null 2>&1;
    if[ ?$ > 0 ];then
        echo "mutt must be installed"
        exit 1;
    fi
    type -a pgbadger > /dev/null 2>&1;
    if[ ?$ > 0 ];then
        echo "pgbadger must be installed"
        exit 1;
    fi    
}

report_build(){
    pgbadger ${PGLOG_DIR}/${PG_LOGFILE} -o ${PGBADGER_FILENAME};
}

compress_report(){
    [ -f "${PGBADGER_FILENAME}" ] && gzip ${PGBADGER_FILENAME};
}

email_notify(){
    MAIL_FROM="dba_reporting@${HOST}"
    MAIL_TO="devops@yourdomain.tld"
    SUBJECT="${ENV} - POSTGRESQL LOG - $(date --date yesterday +%a)"
    MESSAGE="PGBadger from ${HOST} - Log parsed = ${PGLOG_DIR}/${PG_LOGFILE}"
    [ -f "${PGBADGER_FILENAME}.gz" ] && echo "${MESSAGE}" | mutt -e "set from=${MAIL_FROM}" -s "${SUBJECT}" -a ${PGBADGER_FILENAME}.gz -- ${MAIL_TO}
}

clean_var_log_postgresql(){
    #
    #   For dev purpose: we do not need log files from dev - PgBadger is sufficient.
    #   So keep your logs in prod and let logrotate do his job :)
    #
    find ${PGLOG_DIR} -mtime 1 -name 'postgresql*log*' -exec rm -v \{} \;
}

main(){
    dependencie_check;
    report_build;
    compress_report;
    email_notify;
    #clean_var_log_postgresql;
}

main;