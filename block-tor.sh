#!/bin/bash

source .env
# Check if required packages are installed
check_packages() {
	REQUIRED_COMMANDS=("iprange" "curl" "ipset" "iptables")
	for i in ${REQUIRED_COMMANDS[@]}; do
		if ! [ -x "$(command -v $i)" ]; then
		  echo "Error: $i is not installed." >&2
		  EXIT=true
		fi
	done
	if [[ $EXIT ]]; then
		exit 1
	fi
}

fetch_tor_ips() {
	# Get list of tor exit nodes
	echo "Getting new IP addresses"
	curl -s $BLOCK_LIST_URL > /tmp/tor-ips
	
	# Create a variable of rules and pass it to iprange utility to merge related networks into a CIDR
	export IPS=$(cat /tmp/tor-ips | grep -v ':' | iprange)
}

is_list_valid() {
	if [[ $(cat /tmp/tor-ips | wc -l) -le 100 ]]; then
		echo "Less than 100 IPs? It's probably broken, exiting"
		exit 1
	fi
}

# If iptables argument is passed, clear everyhing and add new rules with new IPs
iptables_block() {
	is_list_valid
	iptables -D INPUT -j BLOCK_TOR
	iptables -F $CHAIN
	iptables -X $CHAIN
	iptables -N $CHAIN
	
	for IP in $IPS; do
		echo "Blocking $IP on chain $CHAIN - iptables"
		iptables -A $CHAIN -s $IP -j DROP
	done
	iptables -I INPUT 1 -j BLOCK_TOR
}

ipset_block() {
	is_list_valid
	iptables -D INPUT -m set --match-set $SET src -j DROP
	sleep 0.2
	ipset destroy $SET
	ipset create $SET hash:net
	for IP in $IPS; do
		echo "Blocking $IP on set $SET iptables"
		ipset add $SET $IP
	done
	iptables -I INPUT 1 -m set --match-set $SET src -j DROP
}



check_packages
fetch_tor_ips

if [[ $1 == "iptables" ]]; then
	iptables_block
elif [[ $1 == "ipset" ]]; then
	ipset_block
fi
