#!/bin/bash

DEFAULTMAMBOCOINUSER="mambocoin"
DEFAULTMAMBOCOINPORT=21410
DEFAULTCONFFILE="MamboCoin.conf"
DEFAULTMAMBOBINARY="mambocoind"

function compile_error() {
if [ "$?" -gt "0" ];
 then
  echo -e "${RED}Failed to compile $@. Please investigate.${NC}"
  exit 1
fi
}


function checks() {
if [[ $(lsb_release -d) != *16.04* ]]; then
  echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

if [ -n "$(pidof $DEFAULTMAMBOBINARY)" ]; then
  echo -e "${GREEN}Mambocoind already running.${NC}"
  exit 1
fi
}

function prepare_system() {

echo -e "Prepare the system to install MamboCoin MasterNode."
apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade >/dev/null 2>&1
apt install -y software-properties-common >/dev/null 2>&1
echo -e "${GREEN}Adding bitcoin PPA repository"
apt-add-repository -y ppa:bitcoin/bitcoin >/dev/null 2>&1
echo -e "Installing required packages, it may take some time to finish.${NC}"
apt-get update >/dev/null 2>&1
apt-get install -y make software-properties-common build-essential libtool autoconf libssl-dev libboost-dev libboost-chrono-dev \
libboost-filesystem-dev libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git \
wget curl libdb4.8-dev bsdmainutils libdb4.8++-dev libminiupnpc-dev pwgen
clear
if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
        echo "apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade"
    echo "apt -y install software-properties-common"
    echo "apt-add-repository -y ppa:bitcoin/bitcoin"
    echo "apt-get update"
    echo "apt install -y make build-essential libtool software-properties-common autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev \
libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git curl libdb4.8-dev \
bsdmainutils libdb4.8++-dev libminiupnpc-dev pwgen"
 exit 1
fi

clear
echo -e "Checking if swap space is needed."
PHYMEM=$(free -g|awk '/^Mem:/{print $2}')
if [ "$PHYMEM" -lt "2" ];
  then
    echo -e "${GREEN}Server is running with less than 2G of RAM, creating 2G swap file.${NC}"
    dd if=/dev/zero of=/swapfile bs=1024 count=2M
    chmod 600 /swapfile
    mkswap /swapfile
    swapon -a /swapfile
else
  echo -e "${GREEN}Server running with at least 2G of RAM, no swap needed.${NC}"
fi
clear
}


function compile_mambocoin() {

echo -e "Clone git repo and compile it. This may take some time. Press a key to continue."
read -n 1 -s -r -p ""
git clone https://github.com/MamboCoin/MamboCoin
cd MamboCoin/src
make -f makefile.unix
compile_error MamboCoin

strip $DEFAULTMAMBOBINARY
chmod 755 $DEFAULTMAMBOBINARY
mv $DEFAULTMAMBOBINARY /usr/bin/$DEFAULTMAMBOBINARY
clear
}

function enable_firewall() {
FWSTATUS=$(ufw status 2>/dev/null|awk '/^Status:/{print $NF}')
if [ "$FWSTATUS" = "active" ]; then
  echo -e "Setting up firewall to allow ingress on port ${GREEN}$MAMBOCOINPORT${NC}"
  ufw allow $MAMBOCOINPORT/tcp comment "MamboCoin MN port" >/dev/null
fi
}

function systemd_mambocoin() {

cat << EOF > /etc/systemd/system/$DEFAULTMAMBOBINARY.service
[Unit]
Description=Mambocoin service
After=network.target
[Service]
ExecStart=/usr/bin/$DEFAULTMAMBOBINARY -conf=$MAMBOCOINFOLDER/$DEFAULTCONFFILE -datadir=$MAMBOCOINFOLDER
ExecStop=/usr/bin/$DEFAULTMAMBOBINARY -conf=$MAMBOCOINFOLDER/$DEFAULTCONFFILE -datadir=$MAMBOCOINFOLDER stop
Restart=on-abort
User=$MAMBOCOINUSER
Group=$MAMBOCOINUSER
[Install]
WantedBy=multi-user.target
EOF
}

##### Main #####
clear

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

checks
prepare_system
compile_mambocoin

echo -e "Set a password for ${RED}$MAMBOCOINUSER${NC}. Then hit ${GREEN}ENTER${NC}."
read -e PASSWORD
echo -e "Enter your ${RED}rpcuser${NC} you created in the cold wallet config file. Then hit ${GREEN}ENTER${NC}."
read -e RPCUSER
echo -e "Enter your ${RED}rpcpassword${NC} you created in the cold wallet config file. Then hit ${GREEN}ENTER${NC}."
read -e RPCPASSWORD

echo -e "${GREEN}Prepare to configure and start MamboCoin Masternode.${NC}"

read -p "Mambocoin user: " -i $DEFAULTMAMBOCOINUSER -e MAMBOCOINUSER
: ${MAMBOCOINUSER:=$DEFAULTMAMBOCOINUSER}
useradd $MAMBOCOINUSER; echo -e "$PASSWORD\$PASSWORD" | passwd $MAMBOCOINUSER
useradd -m $MAMBOCOINUSER >/dev/null
MAMBOCOINHOME=$(sudo -H -u $MAMBOCOINUSER bash -c 'echo $HOME')

DEFAULTMAMBOCOINFOLDER="$MAMBOCOINHOME/.MamboCoin"
read -p "Configuration folder: " -i $DEFAULTMAMBOCOINFOLDER -e MAMBOCOINFOLDER
: ${MAMBOCOINFOLDER:=$DEFAULTMAMBOCOINFOLDER}
mkdir -p $MAMBOCOINFOLDER

cat << EOF > $MAMBOCOIN/$DEFAULTCONFFILE
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
EOF
chown -R $MAMBOCOINUSER: $MAMBOCOINFOLDER >/dev/null

read -p "MAMBOCOIN Port: " -i $DEFAULTMAMBOCOINPORT -e MAMBOCOINPORT
: ${MAMBOCOINPORT:=$DEFAULTMAMBOCOINPORT}

echo -e "Enter your ${RED}Masternode Private Key${NC}. You will get it in your MamboCoin Cold wallet. Click on ${GREEN}MamboNodes${NC} tab then ${GREEN}My MamboNodes${NC} tab, click on ${GREEN}Get Config${NC} and paste the ${RED}Masternode Private Key${NC} here."
read -e MAMBOCOINKEY
if [[ -z "$MAMBOCOINKEY" ]]; then
 sudo -u $MAMBOCOINUSER /usr/local/bin/$DEFAULTMAMBOBINARY -conf=$MAMBOCOINFOLDER/$DEFAULTCONFFILE -datadir=$MAMBOCOINFOLDER
 sleep 5
 if [ -z "$(pidof $DEFAULTMAMBOBINARY)" ]; then
   echo -e "${RED}Mambocoind server couldn't start. Check /var/log/syslog for errors.{$NC}"
   exit 1
 fi
 MAMBOCOINKEY=$(sudo -u $MAMBOCOINUSER /usr/local/bin/$DEFAULTMAMBOBINARY -conf=$MAMBOCOINFOLDER/$DEFAULTCONFFILE -datadir=$MAMBOCOINFOLDER masternode genkey)
 kill $(pidof $DEFAULTMAMBOBINARY)
fi

sed -i 's/daemon=1/daemon=0/' $MAMBOCOINFOLDER/$DEFAULTCONFFILE
NODEIP=$(curl -s4 icanhazip.com)
cat << EOF >> $MAMBOCOINFOLDER/$DEFAULTCONFFILE
logtimestamps=1
maxconnections=256
masternode=1
staking=0
gen=0
masternodeprivkey=$MAMBOCOINKEY
masternodeaddr=$NODEIP:$MAMBOCOINPORT
EOF
chown -R $MAMBOCOINUSER: $MAMBOCOINFOLDER >/dev/null


systemd_mambocoin
enable_firewall


systemctl daemon-reload
sleep 3
systemctl start $DEFAULTMAMBOBINARY.service
systemctl enable $DEFAULTMAMBOBINARY.service


if [[ -z $(pidof $DEFAULTMAMBOBINARY) ]]; then
  echo -e "${RED}Mambocoind is not running${NC}, please investigate. You should start by running the following commands as root:"
  echo "systemctl start $DEFAULTMAMBOBINARY.service"
  echo "systemctl status $DEFAULTMAMBOBINARY.service"
  echo "less /var/log/syslog"
  exit 1
fi

echo
echo -e "======================================================================================================================="
echo -e "Mambocoin Masternode is up and running as user ${GREEN}$MAMBOCOINUSER${NC} and it is listening on port ${GREEN}$MAMBOCOINPORT${NC}."
echo -e "Configuration file is: ${RED}$MAMBOCOINFOLDER/$DEFAULTCONFFILE${NC}"
echo -e "VPS_IP:PORT ${RED}$NODEIP:$MAMBOCOINPORT${NC}"
echo -e "MASTERNODE PRIVATEKEY is: ${RED}$MAMBOCOINKEY${NC}"
echo -e "========================================================================================================================"
