#!/bin/bash -x

#
#   My own utility to backup and clean DocRoot (Apache only)
#   copyright (c) 2019 Medour Mehdi
#   
#   Backup (Once a month) and Cleaning (2 months retention) rotation Apache script
#   
#   https://github.com/MedourMehdi
#

#
# List_Type option must be one of WWW_LS WWW_CONF WWW_VAR
# Process option must be one of BACKUP CLEANUP
#

if [ $# -lt 2 ]
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

gzip_check(){
  type -a gzip > /dev/null 2>&1;
  if[ ?$ > 0 ];then
    echo "gzip must be installed"
    exit 1;
  fi
}

www_var(){
  ListDir="docroot1 docroot2 docroot3"
}

www_ls(){
  for dir2list in $(ls -d ${WWW_dir}/*/ 2> /dev/null);do
    #
    # Quick check if we're not in presence of backup dir
    # I think we can do better - It should do the trick...
    #
  is_backup=$(echo $dir2list | grep -c "$(basename ${dir2list})_[0-2][0-9][0-9][0-9][0-1][0-2]");
    if [ ${is_backup} -lt 1 ];then
      ListDir="${ListDir} $(basename ${dir2list})"
    fi
  done
}

www_conf(){
  for dir2list in $(grep -h "DocumentRoot" /etc/apache2/sites-enabled/*conf | grep -v "#" | awk -F" " '{print $2}' | sed -e "s#${WWW_dir}/##g" | awk -F"/" '{print $1}' | sort -u | grep -v "^$");do
    ListDir="${ListDir} $(basename ${dir2list})"
  done
}

#
# Backup docroot
#

backup(){
  gzip_check;
  for dir in ${ListDir};do
    NewDir="${WWW_dir}/${dir}_${ToDay}"
    if [ ! -d "${NewDir}" ] && [ -d "${dir}" ]; then
      Message="New Backup for this month=> ${NewDir}*"
      echo "${Message}"
      echo "Source directory => ${dir}";
      [[ DebugMode == 0 ]] && sudo cp -a ${WWW_dir}/${dir} ${WWW_dir}/${NewDir};
      if [ -d "${WWW_dir}/${NewDir}" ];then
        tar czvf ${WWW_dir}/${NewDir}.tar.gz ${WWW_dir}/${NewDir} && rm ${WWW_dir}/${NewDir}
      fi
    fi
  done
}

#
# We don't want to remove docroots served by Apache
#

cleanup(){
  for dir in ${ListDir};do
    OldDir="${WWW_dir}/${dir}_${OldDate}"
    Message="We should remove this template ${OldDir}*"
    echo "${Message}"
    for dir2rm in $(ls -d ${WWW_dir}/*/ 2> /dev/null | grep "${dir}" | grep -v "${dir}/$");do
      if [ -d "${dir2rm}" ];then
      echo "Dir2rm ${dir2rm} / Dir ${dir}";
      [[ DebugMode == 0 ]] && sudo rm -rf ${dir2rm};
      fi
      if [ -f "${dir2rm}.tar.gz" ];then
      echo "Removing ${dir2rm}.tar.gz";
      [[ DebugMode == 0 ]] && sudo rm -rf ${dir2rm}.tar.gz;
      fi      
    done
  done
}


main(){
  #
  # List Apache DocRoot by script or put them manually
  #

  case $List_Type in
    WWW_LS)     www_ls;;
    WWW_CONF)   www_conf;;
    WWW_VAR)    www_var;;
    *)          echo "Option $List_Type not recognized";
                exit 1
    ;;
  esac

  #
  # Backup ListDir or Cleanup old backup
  #

  case $Process in
    BACKUP)   backup;;
    CLEANUP)  cleanup;;
    *)        echo "Option $Process not recognized";
              exit 1
    ;;
  esac
}

main;