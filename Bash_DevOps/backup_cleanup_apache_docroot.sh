#!/bin/bash -x

#
# Backup and Cleaning rotation Apache script
# 2019 mmedour_at_gmail_com
#

#
# List_Type option must be one of WWW_LS WWW_CONF WWW_VAR
# Process option must be one of BACKUP CLEANUP
#

if [ $# < 2 ]
then
    echo "Usage: $0 ARG1 ARG2"
    echo
    echo "ARG1 => What we do - One of BACKUP or CLEANUP"
    echo
    echo "ARG2 => What directory(ies) is processed - One of WWW_LS WWW_CONF WWW_VAR"
    echo
    exit 0
else
    Process=$1
    List_Type=$2
fi

ToDay=$(date --date= +"%Y%m")
OldDate=$(date --date='-3 month' +"%Y%m")
WWW_dir="/var/www"
ListDir=""
DebugMode=1

#
# Functions declaration
#

www_var(){
  ListDir="docroot1 docroot2 docroot3"
}

www_ls(){
  for dir2list in $(ls -d ${WWW_dir}/*/ 2> /dev/null);do
    ListDir="${ListDir} $(basename ${dir2list})"
  done
}

www_conf(){
  for dir2list in $(grep -h "DocumentRoot" /etc/apache2/sites-enabled/*conf | grep -v "#" | awk -F" " '{print $2}' | sort -u);do
    ListDir="${ListDir} $(basename ${dir2list})"
  done
}

#
# Backup docroot
#

backup(){
  for dir in ${ListDir};do
    NewDir="${WWW_dir}/${dir}_${ToDay}"
    if [ ! -d ${NewDir} && -d "${dir}" ];then
      Message="New Backup for this month=> ${NewDir}*"
      echo "${Message}"
      echo "Source directory => ${dir}";
      [ DebugMode == 0 ] && sudo cp -a ${dir} ${NewDir};
    fi
  done
}

#
# We don't want to remove docroot served by Apache
#

cleanup(){
  for dir in ${ListDir};do
    OldDir="${WWW_dir}/${dir}_${OldDate}"
    Message="We should remove this template ${OldDir}*"
    echo "${Message}"
    for dir2rm in $(ls -d ${OldDir}* 2> /dev/null | grep -v "${dir}$");do
      if[ -d "${dir2rm}" ];then
      echo "Dir ${dir2rm}";
      [ DebugMode == 0 ] && sudo rm -rf ${dir2rm};
      fi
    done
  done
}


main(){
  #
  # List Apache DocRoot by script or put them manually
  #

  case $List_Type in
    WWW_LS)     www_ls();;
    WWW_CONF)   www_conf();;
    WWW_VAR)    www_var();;
    *)          echo "Option $List_Type not recognized";
                exit 1
    ;;
  esac

  #
  # Backup ListDir or Cleanup old backup
  #

  case $Process in
    BACKUP)   backup();;
    CLEANUP)  cleanup();;
    *)        echo "Option $Process not recognized";
              exit 1
    ;;
  esac
}

main();