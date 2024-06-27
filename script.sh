#!/bin/bash


print_banner() {

    echo "======================================================"
    echo "                  Network Script                      "
    echo "======================================================"
    echo " This script will perform the following tasks:        "
    echo " 1. Ping scan to find live machines on the network    "
    echo " 2. ARP scan to find live machines on the network     "
    echo " 3. Combine results and sort to remove duplicates     "
    echo " 4. Find well-known open ports on live machines       "
    echo " 5. Perform DNS reconnaissance on live machines       "
    echo " 6. Perform automatic all Network	tasks		        "
    echo "======================================================"
    echo ""
}

print_banner

#find machines funtion
find_machine()
{
	local -n input_array=$1
	echo "Ping scan starts"
	for ((i=$start;i<=$end;i++))
	do
		ip="$net_ip.$i"
		ping_output=$(ping -c 2 -W 1 $ip | pv -c -N Ping -L $band_with)
		if [ $? -eq 0 ]
		then
			echo "$ip is alive scanned with ping"
			input_array+=("$ip")

			traffic=$(echo "$ping_output" | pv -c -N Ping -L $band_with | wc -c)
         	total_traffic=$((total_traffic + traffic))
		fi
	done
}


#arping
find_machine_ar()
{
	echo "ARP Ping scan starts"
	local -n input_array=$1
	for ((i=$start;i<=$end;i++))
	do
		ip="$net_ip.$i"

			arping_output=$(arping -c 2 -W 1 $ip | pv -c -N Arping -L $band_with)
			if [ $? -eq 0 ]
			then
				echo "$ip is alive scanned with arp ping"
				input_array+=("$ip")

				traffic=$(echo "$arping_output" | pv -c -N Arping -L $band_with | wc -c)
            	total_traffic=$((total_traffic + traffic))
			fi

	done 
}

#print function
print()
{
	local -n array=$1
	for input in "${array[@]}"
do
	echo "$input "
done 
}

sort_remove()
{
	local -n array=$1
	sorted_array=($(echo "${array[@]}" |tr ' ' '\n' | sort | uniq))
	
}

#combine result
combine()
{
#combine ip of both arrays in one
	combine_array=()
	combine_array=("${array_ping[@]}")
	combine_array+=("${array_arp[@]}")
#working pending
	sort_remove combine_array
	
}

#Find well_known ports
find_ports()
{
	local -n arra=$1
	ports=(7 20 21 22 23 25 53 69 80 88 102 110 135 137 139 143 381 443 3389 3306)
	
#check file exitence
if [ -f "ports_result" ]
then 
    rm "ports_result"
fi
    touch "ports_result"
 



	for ips in "${arra[@]}"
	do
		echo "Ports open for this $ips are below" >> ports_result
		for port in "${ports[@]}"
		do
			nc -zv -w 2 $ips $port &> /dev/null 
			if [ $? == 0 ]
			then

				result=$(nc -zv -w 2 $ips $port 2>&1 | pv -c -N NC -L $band_with) #it limits the traffic and save output to result
				echo $result >> ports_result
				echo "" >> ports_result
				traffic=$(echo "$result" | pv -c -N NC -L $band_with | wc -c)
                total_traffic=$((total_traffic + traffic))
			fi
		done 
		echo "--------------------------------" >> ports_result
		echo "" >> ports_result
	done 
	echo "Port scanning results saved to ports_result"
}

#DNS_Reconnaissances

dns_reconnaissance()
{
    local -n array=$1
    if [ -f "dns_result" ]; then 
        rm "dns_result"
    fi
    touch "dns_result"

    for ip in "${array[@]}"
    do
        echo "DNS reconnaissance for $ip" >> dns_result
        echo "" >> dns_result
        echo "Output of NSLookup command" >> dns_result
        echo "" >> dns_result
        nslookup_output=$(nslookup $ip | pv -c -N NSLookup -L $band_with)
        echo "$nslookup_output" >> dns_result
        traffic=$(echo "$nslookup_output" | pv -c -N NSLookup -L $band_with | wc -c)
        total_traffic=$((total_traffic + traffic))
        
        echo "" >> dns_result
        echo "Output of host command" >> dns_result
        echo "" >> dns_result
        host_output=$(host $ip | pv -c -N Host -L $band_with)
        echo "$host_output" >> dns_result
        traffic=$(echo "$host_output" | pv -c -N Host -L $band_with | wc -c)
        total_traffic=$((total_traffic + traffic))
        
        echo "" >> dns_result
        echo "Output of dig command" >> dns_result
        echo "" >> dns_result
        dig_output=$(dig -x $ip | pv -c -N Dig -L $band_with)
        echo "$dig_output" >> dns_result
        traffic=$(echo "$dig_output" | pv -c -N Dig -L $band_with | wc -c)
        total_traffic=$((total_traffic + traffic))
        
        echo "--------------------------------" >> dns_result
        echo "" >> dns_result
    done
    echo "DNS reconnaissance results saved to dns_result"
}


#main

main()
{
	while :
	do
		echo "Enter done to finish or select any option"
		read user_input
		if [ $user_input = "done" ]
		then
			break

		elif [ $user_input = 1 ]
			then
				if [ $count = 0 ] || [ $count = 2 ] || [ $count != 3 ]
				then
					find_machine array_ping
					count=$((count+1))
				else
					echo "You already perform this scan"
				fi

		elif [ $user_input = 2 ]
			then
				if [ $count = 0 ] || [ $count = 1 ] || [ $count != 3 ]
				then
					find_machine_ar array_arp
					count=$((count+2))
				else
					echo "You already perform this scan"
				fi

		elif [ $user_input = 3 ]
			then
				if [ $count = 1 ]
				then
					find_machine_ar array_arp
				elif [ $count =2 ]
					then
						find_machine array_ping
				elif [ $count = 0 ]
					then
						find_machine array_ping
						find_machine_ar array_arp
				fi
				combine

		elif [ $user_input = 4 ]
			then
				if [ $count = 1 ]
				then
					find_ports array_ping
				elif [ $count =2 ]
					then
						find_ports array_arp
				elif [ $count = 3 ]
					then
						find_ports combine_array
				else
					echo "First perform scanning to check live hosts on network"
				fi
		elif [ $user_input = 5 ]
		then
				if [ $count = 1 ]
				then
					dns_reconnaissance array_ping
				elif [ $count =2 ]
				then
						dns_reconnaissance array_arp
				elif [ $count = 3 ]
				then
						dns_reconnaissance combine_array
				else
					echo "First perform scanning to check live hosts on network"
				fi
		elif [ $user_input = 6 ]
		then
			find_machine array_ping
			find_machine_ar array_arp
			combine
			find_ports combine_array
			dns_reconnaissance combine_array 
		fi
	done

}



echo  "Enter your IP"
read ip
echo "Enter the starting point of scope"
read start
echo "Enter the ending point of scope"
read end
band_with=1024
array_ping=()
array_arp=()
net_ip=${ip%.*}
total_traffic=0
count=0
main