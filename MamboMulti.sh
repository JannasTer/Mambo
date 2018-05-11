#/bin/bash

cd ~
echo "****************************************************************************"
echo "* Ubuntu 16.04 is the recommended opearting system for this install.       *"
echo "*                                                                          *"
echo "* This script will install and configure your Mambocoin masternodes.      *"
echo "****************************************************************************"
echo && echo && echo
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!                                                 !"
echo "! Make sure you double check before hitting enter !"
echo "!                                                 !"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo && echo && echo

echo "Do you want to install all needed dependencies (no if you did it before)? [y/n]"
read DOSETUP

if [[ $DOSETUP =~ "y" ]] ; then
  sudo apt-get update
  sudo apt-get -y upgrade
  sudo apt-get -y dist-upgrade
  sudo apt-get install -y nano htop git
  sudo apt-get install -y software-properties-common
  sudo apt-get install -y build-essential libtool autotools-dev pkg-config libssl-dev
  sudo apt-get install -y libboost-all-dev
  sudo apt-get install -y libevent-dev
  sudo apt-get install -y libminiupnpc-dev
  sudo apt-get install -y autoconf
  sudo apt-get install -y automake unzip libgmp-dev
  sudo add-apt-repository  -y  ppa:bitcoin/bitcoin
  sudo apt-get update
  sudo apt-get install -y libdb4.8-dev libdb4.8++-dev

  cd /var
  sudo touch swap.img
  sudo chmod 600 swap.img
  sudo dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
  sudo mkswap /var/swap.img
  sudo swapon /var/swap.img
  sudo free
  sudo echo "/var/swap.img none swap sw 0 0" >> /etc/fstab
  cd

  ## COMPILE AND INSTALL
  git clone https://github.com/MamboCoin/MamboCoin
  cd MamboCoin/src/
  make -f makefile.unix
  sudo chmod 755 mambocoind
  sudo mv mambocoind /usr/bin

  sudo apt-get install -y ufw
  sudo ufw allow ssh/tcp
  sudo ufw limit ssh/tcp
  sudo ufw logging on
  echo "y" | sudo ufw enable
  sudo ufw status

  mkdir -p ~/bin
  echo 'export PATH=~/bin:$PATH' > ~/.bash_aliases
  source ~/.bashrc
fi

## Setup conf
mkdir -p ~/bin
echo ""
echo "Configure your masternodes now!"
echo "Type the IP of this server, followed by [ENTER]:"
read IP

MNCOUNT=""
re='^[0-37]+$'
while ! [[ $MNCOUNT =~ $re ]] ; do
   echo ""
   echo "How many nodes do you want to create on this server?, followed by [ENTER]:"
   read MNCOUNT
done

for i in `seq 1 1 $MNCOUNT`; do
  echo ""
  echo "Enter alias for new node"
  read ALIAS  
  echo ""
  echo "Enter port for node $ALIAS"
  read PORT
  echo ""
  echo "Enter masternode private key for node $ALIAS"
  read PRIVKEY
  echo ""
  echo "Enter RPC Port (Any valid free port: i.E. 17200)"
  read RPCPORT
  ALIAS=${ALIAS,,}
  CONF_DIR=~/.MamboCoin_$ALIAS
  # Create scripts
  echo '#!/bin/bash' > ~/bin/mambocoind_$ALIAS.sh
  echo "mambocoind -conf=$CONF_DIR/MamboCoin.conf -datadir=$CONF_DIR "'$*' >> ~/bin/ariond_$ALIAS.sh
  chmod 755 ~/bin/arion*.sh
  mkdir -p $CONF_DIR
  echo "rpcuser=user"`shuf -i 100000-10000000 -n 1` >> MamboCoin.conf_TEMP
  echo "rpcpassword=pass"`shuf -i 100000-10000000 -n 1` >> MamboCoin.conf_TEMP
  echo "rpcallowip=127.0.0.1" >> MamboCoin.conf_TEMP
  echo "rpcport=$RPCPORT" >> MamboCoin.conf_TEMP
  echo "listen=1" >> MamboCoin.conf_TEMP
  echo "server=1" >> MamboCoin.conf_TEMP
  echo "daemon=1" >> MamboCoin.conf_TEMP
  echo "logtimestamps=1" >> MamboCoin.conf_TEMP
  echo "maxconnections=256" >> MamboCoin.conf_TEMP
  echo "masternode=1" >> MamboCoin.conf_TEMP
  echo "" >> MamboCoin.conf_TEMP
  echo "addnode=185.234.15.95" >> MamboCoin.conf_TEMP
  echo "addnode=45.56.123.13" >> MamboCoin.conf_TEMP
  echo "addnode=46.163.166.50" >> MamboCoin.conf_TEMP
  echo "" >> MamboCoin.conf_TEMP
  echo "port=$PORT" >> MamboCoin.conf_TEMP
  echo "masternodeaddr=$IP:$PORT" >> MamboCoin.conf_TEMP
  echo "masternodeprivkey=$PRIVKEY" >> MamboCoin.conf_TEMP
  sudo ufw allow $PORT/tcp
  mv MamboCoin.conf_TEMP $CONF_DIR/MamboCoin.conf 
  sh ~/bin/ariond_$ALIAS.sh
done
