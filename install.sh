#!/bin/bash

OKB='\033[94m'
OKR='\033[91m'
OKG='\033[92m'
OKO='\033[93m'
RESET='\e[0m'

echo -e "$RESET"
echo -e "$OKO   ██████╗ ███████╗ ██████╗ ██████╗    $RESET"  
echo -e "$OKO   ██╔══██╗██╔════╝██╔════╝██╔═══██╗   $RESET"   
echo -e "$OKW   ██████╔╝█████╗  ██║     ██║   ██║   $RESET"   
echo -e "$OKW   ██╔══██╗██╔══╝  ██║     ██║   ██║   $RESET"   
echo -e "$OKG   ██║  ██║███████╗╚██████╗╚██████╔╝██╗██╗██╗  $RESET"
echo -e "$OKG   ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝╚═╝╚═╝  $RESET"
echo -e "$RESET"
echo -e "$OKORANGE                      + -- --=[ https://kunshdeep.com $RESET"
echo -e "$OKORANGE                      + -- --=[ Reco by @kunshdeep(Deepak Kandpal) $RESET"
echo ""

echo -e "$OKG + -- --=[ This script will install some dependencies. Are you sure you want to continue? (Hit Ctrl+C to exit)$RESET"
if [[ "$1" != "force" ]]; then
	read answer
fi

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

apt-get -y update
apt-get install -y ruby
apt-get install -y ruby-full
apt-get install -y libssl-dev
echo -e "$OKO + -- --=[ Installing gem dependencies...$RESET"
gem install ipaddr
gem install ipaddress
gem install httparty
gem install colorize
gem install csv
gem install timeout
gem install ruby-progressbar
gem install faye-websocket
gem install eventmachine
gem install json
gem install terminal-table
gem install selenium-webdriver
gem install fileutils
echo -e "$OKO + -- --=[ Done! $RESET"
echo -e "$OKO + -- --=[ To run, type 'ruby reco.rb -h'! $RESET"
