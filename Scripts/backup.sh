#!/usr/bin/bash

root="/usr/root"
logFile="/home/ahmdjaber/Desktop/Testing/log.txt"
error=""
backup_status="Success"
backup_path="empty"
comp=0

#colors
red='\033[31m'
green='\033[32m'
yellow='\033[33m'
blue='\033[34m'
orange='\033[38;2;255;120;0m'
bold='\033[1m'
reset='\033[0m'

colored_echo(){
        text=$1
        color=$2
        echo -e "${color}${text}${reset}"
}

#Check if there is a permission to read the directory
check_permission () {
        path=$1
        find "${path}" ! -readable -printf "No read permission for : %p\n"
}

#Concatenate all the parents of the directory into one string 
path_to_str() {
        IFS='/'
        path=$1
        str_path=""
        read -ra directories <<< $path
        for dir in ${directories[@]}; do
                if [ -n dir ]; then
                        str_path="$str_path$dir"
                fi
        done
        echo "${str_path}"
}

#Creating a compressed or not compressed backup as the user requirements 
create_backup() {
        DIR=$1
        str_path=$(path_to_str "${DIR}")
        if [ $comp -eq 1 ]; then
                if [ ! -d "${root}/compressed" ]; then 
                        mkdir "${root}/compressed"
                fi 
                
                backup_path="${root}/compressed/${str_path}_Backup.zip"
                if [ ! -f ${backup_path} ]; then 
                        zip -r $backup_path $DIR
                else
                        # echo "Compressed Backup for the directory ${DIR} is already exists in this locatoin"
                        read -p "Compressed backup for this directory found in the specified location, Do you want to replace it [Y/N]? " replace
                        if [[ ${replace,,} == "yes" ]] || [[ ${replace,,} == "y" ]]; then 
                                rm -rf ${backup_path} 
                                zip -r $backup_path $DIR
                        else 
                                error="Compressed Backup for the directory ${DIR} is already exists in the specified locatoin"
                        fi 
                fi 
        else 
                backup_path="${root}/${str_path}_Backup"
                if [ ! -d ${backup_path} ]; then 
                        mkdir $backup_path
                        cp -r ${DIR} $backup_path 
                        
                else 
                        read -p "Backup for this directory found in the specified location, Do you want to replace it [Y/N]? " replace
                        if [[ ${replace,,} == "yes" ]] || [[ ${replace,,} == "y" ]]; then 
                                rm -rf ${backup_path} 
                                mkdir $backup_path
                                cp -r ${DIR} $backup_path 
                        else 
                                error="Backup for the directory ${DIR} is already exists in the specified locatoin"
                        fi 
                fi 
        fi 
        return $?
}

#Check if the user wants to compress the backup or not
check_compression () {
        read -p "Do you want to compress the backup into a zip file [Y/N]? " check_comp
        Check_compL="${check_comp,,}"
        [[ $Check_compL == "yes" || $Check_compL == "y" ]] && comp=1
}

#print the errors
print_error(){
        if [[ $(echo "${error}" | awk '{print $1}') != "Permission" && $error != "" ]]; then
                echo -e "${error}"
        fi
}

#update the log file
update_log(){
        echo "$(basename ${DIR}) Backup creation details: " >> $logFile
        if [[ $error == "" ]]; then
                echo "    status     : Success" >> $logFile
                echo -n "    compressed : " >> $logFile
                [ $comp -eq 1 ] && echo "Yes" >> $logFile || echo "No" >> $logFile
                echo "    size       : $(du -sh $backup_path | awk '{print $1}')" >> $logFile
                echo "    date       : $(date)" >> $logFile
                echo "    location   : ${root}" >> $logFile
                echo -e "\n$(colored_echo "Everything is done" "${green}${bold}"), check ${root} directory\n"
        else
                echo "    status    : Failed" >> $logFile
                echo "    error     : ${error}" >> $logFile
                echo "    date      : $(date)" >> $logFile
                echo -e "\n$(colored_echo "Something went wrong while creating a backup" "${red}${bold}") for the directory '${DIR}'."
                echo "Please check the '${logFile}' file for detailed error information\n"
        fi

        echo "---------------------------------------------------------------------------------" >> $logFile
}

#start the compression process
start(){
        read -p "Directory path to be backed up: " DIR
        while [ ! -d ${DIR} ] && [ ! -f ${DIR} ]; do 
                read -p "Please enter a valid path: " DIR
        done 
        if [ -d "$DIR" ]; then
                permission=$(check_permission "${DIR}")
                if [[ ! -n ${permission} ]]; then

                        read -p "Directory path where you want to save the backup ['d' for defualt]: " directory_path
                        while [[ ${directory_path,,} != "d" ]] && [ ! -d ${directory_path} ]; do 
                                read -p "Please enter a valid directory path ['d' for defualt path]: " directory_path
                        done 

                        if [[ ${directory_path} != "d" ]]; then 
                                root=${directory_path}
                        fi 
                        if [[ ${DIR} != ${root} && ${root} != "${DIR}/"* ]]; then 
                                check_compression
                                create_backup "${DIR}"
                                check=$?
                                if [ $check -ne 0 ]; then
                                        backup_status="Failed"
                                        error="Failed to make a backup for the directory"
                                fi
                        else 
                                error="Cannot create a backup of ${DIR} inside the same directory or its subdirectories"
                        fi 
                else
                        error="Permission denied, can't read the specified directory"
                fi
        else
                error="Specified path is not a directory"
        fi
}

start 
print_error
update_log 