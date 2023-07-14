#!/bin/bash

fname="snmpwalk.sh"
version="0.2"

# Menu Switches
arg_target="N"
arg_input="N"
#arg_output="N" # Coming soon
arg_snmp="public"
arg_version="2c"

# Variables
NAME_SUFFIX=$(/bin/date +%d-%m-%Y-%H:%M:%S)
function header () {
# header function  - used to print out the title of the script

echo -e "\e[1m                                        _ _          _     "
echo "                                       | | |        | |     "
echo " ___ _ __  _ __ ___  _ ____      ____ _| | | __  ___| |__   "
echo "/ __| '_ \| '_ ' _ \| '_ \ \ /\ / / _' | | |/ / / __| '_ \  "
echo "\__ \ | | | | | | | | |_) \ V  V / (_| | |   < _\__ \ | | | "
echo "|___/_| |_|_| |_| |_| .__/ \_/\_/ \__,_|_|_|\_(_)___/_| |_| "
echo "                    | | "
echo "                    |_| "
echo ""
echo -e "\e[39m\e[0m\e[96mVersion: $version"
echo ""
}

function helpmenu () {
# show the options to use

header
echo
echo "[*] Usage: $fname [options]"
echo
echo -e "\e[93m[options]:"
echo
echo "  --target [hosts]	Subnet or host for realtime scanning with nmap"
echo "			Ex. 192.168.0.0/24 or 192.168.0.1"
echo "  --input [file]	Set a custom input file with hosts"
echo "  --version		Set snmp vetsion. By default use snmp 2c"
echo "  --snmp [community]	Set a input file with snmp communities list"
echo "			By default checking 'public'"
echo
echo -e "\e[95m[*] Example:"
echo
echo "$fname --target 192.168.0.1"
echo "$fname --input ips.txt --version 1"
echo "$fname --target 192.168.4.0/24 --snmp /home/user/com.txt"
echo
echo "--------------------------------------------------------------------------------------"
}

function active () {
echo "[*] Getting active addresses..."

if [ "$arg_input" == "N" ]
	then nmap -sn "$arg_target" 2> /dev/null | grep -Eo "Nmap scan report.*" | grep -Eo "([0-9]{1,3}\.){3}[0-9]{1,3}" >> temporary-ips-"$NAME_SUFFIX".txt
elif [ "$arg_input" != "N" ]
	then nmap -sn -iL "$arg_input" 2> /dev/null | grep -Eo "Nmap scan report.*" | grep -Eo "([0-9]{1,3}\.){3}[0-9]{1,3}" >> temporary-ips-"$NAME_SUFFIX".txt
else
	echo "[*] Unknown error..."
fi

echo "[*] Checking snmp ports...";

while IFS= read -r line;
do
	#masscan --rate=2000 -pU:161,162 "$line" 2> /dev/null | awk '{print $6}' > temporary-snmp.txt
	nmap -sU -p161,162 --open -T4 "$line" 2> /dev/null | grep -Eo "Nmap scan report.*" | grep -Eo "([0-9]{1,3}\.){3}[0-9]{1,3}" >> temporary-snmp-"$NAME_SUFFIX".txt
done < temporary-ips-"$NAME_SUFFIX".txt

echo "--------------------------------------------------------------------------------------"
echo -e "ip\tcommunity\tnote"
echo "--------------------------------------------------------------------------------------"

while IFS= read -r ip;
do
	if [ "$arg_snmp" == "public" ]
		then snmpwalk -v "$arg_version" -c "$arg_snmp" "$ip" 2> /dev/null | head -n 1 > temporary-comm-"$NAME_SUFFIX".txt;
			sed -ie 's/^.* \"//g' temporary-comm-"$NAME_SUFFIX".txt 2> /dev/null;sed -ie 's/\"$//' temporary-comm-"$NAME_SUFFIX".txt 2> /dev/null;
			echo -e "$ip\tpublic\t$(cat temporary-comm-"$NAME_SUFFIX".txt 2> /dev/null)" | awk 'length($0)>36'
	else
		while IFS= read -r line; do
			snmpwalk -v "$arg_version" -c "$line" "$ip" 2> /dev/null | head -n 1 > temporary-comm-"$NAME_SUFFIX".txt;
			sed -ie 's/^.* \"//g' temporary-comm-"$NAME_SUFFIX".txt 2> /dev/null;sed -ie 's/\"$//' temporary-comm-"$NAME_SUFFIX".txt 2> /dev/null;
			echo -e "$ip\t$line\t$(cat temporary-comm-"$NAME_SUFFIX".txt 2> /dev/null)" | awk 'length($0)>36'
		done < "$arg_snmp"
	fi
done < temporary-snmp-"$NAME_SUFFIX".txt
echo "[*] Done..."
rm temporary-*
}

# Main
helpmenu
echo -e "\e[97m"

# Get args
while [[ "$#" -gt 0 ]];do
        case $1 in
                --target) arg_target="$2"
                shift;;
                --input) arg_input="$2"
                shift;;
#                --output) arg_output="$2" # Coming soon
#                shift;;
		--snmp) arg_snmp="$2"
		shift;;
		--version) arg_version="$2"
		shift;;
                *) echo "[*] Unknown option: $1..."
                exit 1;;
        esac
shift
done

# Check options
if [ "$arg_target" != "N" ] && [ "$arg_input" != "N" ]
        then echo "[*] Incompatible options: --input and --target"
elif [ "$arg_target" != "N" ] || [ "$arg_input" != "N" ]
        then active
else
        echo "[*] Chose options for start..."
fi

# exit
exit 0