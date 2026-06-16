#! /usr/bin/bash

low_disks=""
orgIFS=$IFS  

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
        sleep 0.001
}

separator(){
        echo -en "${bold}"
        for i in {1..76}; do 
                echo -n "#"
                sleep 0.0005
        done 
        echo -e "${reset}"
}

capitalize() {
    echo -n "$1" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}'
}

formatted_line(){
        line=$1
        color=$2
        IFS=' '
        cnt=0
        echo 
        for word in ${line}; do
                if [ ${cnt} -eq 0 ]; then 
                        printf "${bold}"
                fi 
                if [ ${cnt} -eq 0 ] && [ ${#word} -le 7 ]; then 
                        printf "${color}%s\t\t${reset}" "${word}"
                else 
                        printf "${color}%s\t${reset}" "${word}"
                fi   

                if [[ ${word} ==  *"%" ]]; then 
                        word1=$(echo ${word} | tr -d "%")
                        if [[ ${word1} > 80 ]]; then 
                                cur=$(echo ${line} | awk '{print $1}')
                                low_disks="${low_disks}${cur} "
                        fi 
                fi 
                cnt=1 
                printf "${reset}"  
                
        done
        IFS=${orgIFS}

        sleep 0.01
}

#Recent System Updates
check_recent_updates(){
        updates=()
        while IFS= read -r line; do 
                updates+=("$line")
        done < <(strings ~/.bash_history | grep -E 'apt update|apt install')

        n=${#updates[@]}
        if [ ${n} -ge 1 ]; then 
                echo -e "$(colored_echo "Updates and Installations:" "${bold}")"
                end=0
                if [ ${n} -ge 10 ]; then 
                        end=$((n - 10))
                fi 
                for((i=n-1; i>=end; i--)); do 
                        line=${updates[$i]}
                        echo -en "\t- sudo apt " 
                        if [[ ${line} == *"install"* ]]; then    
                                echo -n "install"
                                install=$(echo "${line}" | awk '{print $4}')
                                colored_echo " ${install}" "${orange}"
                        else 
                                colored_echo "update" "${green}${bold}"
                        fi
                done 
        else 
                echo -e "$(colored_echo "There are no recent Updates or Installations:" "${bold}")"
        fi 

        echo
        echo -e "\t|$(colored_echo "Recommendations and Actions:" "${bold}${green}")"
        echo -e "\t|\t$(colored_echo "- To update the package list, use 'sudo apt update' command")."
        echo -e "\t|\t$(colored_echo "- When updating, condider to reboot, use 'sudo reboot' command")."
        echo -e "\t|\t$(colored_echo "- To list all the available packages, use 'apt list' command")."

        echo -e "\n$(colored_echo "Done Checking Running Services." "${blue}${bold}")\n\n"


        echo -e "====================[ $(colored_echo "Done Checking the System's Health" "${green}${bold}") ]====================\n"


}

#Running Services
check_running_services(){
        services=()
        length=0
        while IFS= read -r service; do 
                services+=("${service}")
                (( length++ ))
        done < <(systemctl --type=service | grep "running" | awk '{print $1}')
        echo -en "${bold}There are " 
        echo -en "${yellow}${length} ${reset}"
        echo -e "${bold}RUNNING services, These services are: ${reset}"
        for service in ${services[@]}; do 
                color=${reset}
                if [[ ${service} == "system"* ]]; then 
                        color=${orange}
                fi 
                echo -e "\t- ${color}${service}${reset}"
                sleep 0.03
        done 
        echo 
        echo -e "\t|$(colored_echo "Recommendations:" "${bold}${green}")"
        echo -e "\t|\t$(colored_echo "- for more details, use 'systemctl --type=service'")."
        echo -e "\t|\t$(colored_echo "- use 'top' command to check the running tasks (processes)")."
        echo -e "\n$(colored_echo "Done Checking Running Services." "${blue}${bold}")\n\n\n"

}

#Memory Usage
check_memory_usage(){
        head="\t\t"
        head="${head}"
        head_mem=$(free | grep "total")
        for word in ${head_mem}; do
                word="$(capitalize "${word}")"
                head="${head}${word}\t"
        done
        colored_echo "${head}" "${bold}"
        echo -n "____________________________________________________________________________"
        IFS=$'\n'
        lines=$(free -m | awk 'NR > 1') 
        for line in ${lines}; do 
                cur_line=$(echo "$line" | awk '{print $1, $2, $3, $4, $5, $6}')
                avail=$(echo ${line} | awk '{print $7}')
                if [[ ${line} == *"Mem:"* ]]; then 
                        formatted_line "${cur_line}" "${orange}"
                        echo -en "${orange}\t${avail}${reset}"
                else 
                        formatted_line "${cur_line}"
                        echo -en "\t${avail}"
                fi 
        done 
        echo
        IFS=${orgIFS}
        total=$(echo "$lines" | awk '/Mem:/ {print $2}')
        used=$(echo "$lines" | awk '/Mem:/ {print $3}')
        percent=$((100 * used / total))
        echo
        if [ ${percent} -ge 80 ]; then 
                echo -e "\t|$(colored_echo "Your system's memory is ${percent} utilized" "${bold}${red}"), which may lead to:"
                echo -e "\t|\t$(colored_echo "- Instability.")"
                echo -e "\t|\t$(colored_echo "- Perfomence Issues.")"
                echo -e "\t|\t$(colored_echo "- Inability to launch new processes.")"
                echo -e "\n"
                echo -e "\t|$(colored_echo "Recommendations:" "${bold}${green}")"
                echo -e "\t|\t$(colored_echo "- Close unnecessary apps.")"
                echo -e "\t|\t$(colored_echo "- Add more memory to your system.")"
        else 
                echo -e "\n\t|$(colored_echo "Everything goes well with the disks" "${bold}${green}")"
        fi 
        echo -e "\n$(colored_echo "Done Checking Memory Usage." "${blue}${bold}")\n\n\n"
}

#Disk Space
check_disk_space(){

        echo -e "$(formatted_line "Filesystem Type Size Used Avail Use% Mounted_on" "${bold}")"
        echo -n "____________________________________________________________________________"
        formatted_line "$(df -hT / | grep "dev")" "${orange}"
        mapfile -t diskCheck <<< "$(df -hT | grep -vE "snapfuse|tempfs|/dev/sd")"
        for line in "${diskCheck[@]}"; do
                if [[ ${line} == *"Size"* ]]; then
                        continue
                fi 
                formatted_line "${line}" "${reset}"
        done
        
        echo -e "\n"
        if [ ${#low_disks} -ge 1 ]; then 
                echo -e "\t|$(colored_echo "Disks with Low Available Space:" "${red}${bold}")"
                for disk in ${low_disks}; do
                        echo -e "\t|\t- $(colored_echo "${disk}")"
                done
                echo -e "\n"
                echo -e "\t|$(colored_echo "Recommendations:" "${bold}${green}")"
                echo -e "\t|\t$(colored_echo "- Remove unnecessary files using the 'rm <file_name>' command.")"
                echo -e "\t|\t$(colored_echo "- Uninstall pakages or apps that you don't use frequently.")"
                echo -e "\t|\t$(colored_echo "- You can use the command 'sudo apt-get remove <pakage_name>' to Unistall apps.")"
        else 
                echo -e "\n\t$(colored_echo "|Everything goes well with the disks" "${bold}${green}")"
        fi 
        echo -e "\n$(colored_echo "Done Checking Disk Space." "${blue}${bold}")\n\n\n"
}

#Header
print_header(){
        echo -e "\n==========================[ $(colored_echo "System Health Check" "${green}${bold}") ]==========================\n"
        colored_echo "This report will include checks for:" "${bold}"
        echo "1. $(colored_echo "Disk Space" "${yellow}")" 
        echo "2. $(colored_echo "Memory Usage" "${yellow}")"
        echo "3. $(colored_echo "Running Services" "${yellow}")"
        echo "4. $(colored_echo "Recent System Updates\n" "${yellow}")"
        echo -e "===========================[ $(colored_echo "Starting Checks..." "${green}${bold}") ]===========================\n\n"
}

print_header 

separator
echo -e "$(colored_echo "Checking Disk Space..." "${blue}${bold}")\n"
sleep 0.6
check_disk_space

separator
echo -e "$(colored_echo "Checking Memory Usage..." "${blue}${bold}")\n"
sleep 0.6
check_memory_usage

separator
echo -e "$(colored_echo "Checking Running Services..." "${blue}${bold}")\n"
sleep 0.6
check_running_services

separator
echo -e "$(colored_echo "Checking Recent System Updates..." "${blue}${bold}")\n"
sleep 0.6
check_recent_updates