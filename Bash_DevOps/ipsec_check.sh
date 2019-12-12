#!/bin/bash

#
#   Restart ipsec if remote ip down
#   copyright (c) 2019 Medour Mehdi
#   
#   https://github.com/MedourMehdi
#

my_remote_ip="10.10.4.201"
my_date=`date +"%Y%m%d%H"`
my_email="linux_team@companeo.com"

func_restart_ipsec(){
    my_result_ipsec=$(systemctl restart ipsec);
    [ "$?" != "0" ] && my_message="Error restarting ipsec.\n${result_ipsec}" || my_message="ipsec was restarted at ${my_date}";
    echo -e "${my_message}" | mail -s "Ipsec Restart ${my_date}" ${my_email};
}

main(){
    ping -c 1 ${my_remote_ip};
    [ "$?" != "0" ] && func_restart_ipsec;
    exit 0;
}

main;