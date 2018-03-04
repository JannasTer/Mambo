# Cold/Hot Wallet Setup for MamboCoin
Shell script to install a [MamboCoin Masternode](http://mambocoin.com) on a Linux server running Ubuntu 16.04. Use it on your own risk.

***

## Desktop wallet setup  

1.  Synchronize your local wallet.
2.  Open the MamboCoin Desktop Wallet.  
3.  Go to **MamboNodes** tab click on **My MamboNodes**
4.  Click **Create** and fill the details:  
    * Alias: **MN1**  
    * Address: **VPS_IP:PORT**  
5.  Click **OK** to add the masternode
6.  Click on MN created: **MN1** and click **Copy Address** 
7.  Send **30000** MAMBO to copied address
8.  Wait for **20** confirmations.
9.  Click button **Get Config** and copy the contents.
10. Create or Edit a file named MamboCoin.conf inside this folder
    * Windows:  **C:\Users<YOUR_USER>\Appdata\Roaming\MamboCoin**  
    * Mac:      **~/Library/Application Support/MamboCoin** 
    * Linux:    **~/.MamboCoin**
11. Replace the **rpcuser, rpcpass and port (21410)** fields.
12. Open the port on your router/firewall
13. Restart the wallet
14. Unlock the wallet
15.  Click **Start All** 

***

## VPS Setup:  

After the Cold Wallet is up and running, you need to configure the VPS accordingly. Here are the steps:

wget -q https://raw.githubusercontent.com/JannasTer/Mambo/master/mambocoin.sh

bash mambocoin.sh

Supply the script all info received from the **Get Config** details, including the changed **rpcuser, rpcpass and port** fields

***

## Usage:  

For security reasons **MamboCoin** is installed under **mambocoin** user, hence you need to **su - mambocoin** before checking:    

```
su - mambocoin
mambocoind masternode status
mambocoind getinfo
```  
Also, if you want to check/start/stop **mambocoind** , run one of the following commands as **root**:
```
systemctl status mambocoind #To check the service is running  
systemctl start mambocoind #To start mambocoind service  
systemctl stop mambocoind #To stop mambocoind service  
```


***

  
Any donation is highly appreciated  

**MAMBO**: mPL37kxmoVXffSFTdEqRHPgz4dSPR4JnF5   
**BTC**: 18uctxP5sbMkm3CMeVymUoTxQHk34hhLCQ  
**ETH**: 0x1c4a11c22Cb33E93C3c7CEb7f7a10D653CDacf56  

