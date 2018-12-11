#!/bin/bash
echo ""

# load setup config
source /home/admin/raspiblitz.info

# load version
source /home/admin/_version.info

# show info to user
dialog --backtitle "RaspiBlitz - Setup" --title " RaspiBlitz Setup is done :) " --msgbox "
    After reboot RaspiBlitz
    needs to be unlocked and
    sync with the network.

    Press OK for a final reboot.
" 10 42

# init the RASPIBLITZ Config
configFile="/mnt/hdd/raspiblitz.conf"
echo "# RASPIBLITZ CONFIG FILE" > $configFile
echo "raspiBlitzVersion='${codeVersion}'" >> $configFile
sudo chmod 777 ${configFile}

# transfer data from SD info file
echo "hostname=${hostname}" >> $configFile
echo "network=${network}" >> $configFile
echo "chain=${chain}" >> $configFile

# let migration/init script do the rest
./_bootstrap.migration.sh

# set raspi config as environment for lnd service
sudo systemctl stop lnd
sudo systemctl disable lnd
sed -i "s/^EnvironmentFile=.*/EnvironmentFile=${configFile}/g" /etc/systemd/system/lnd.service
sudo systemctl enable lnd

# copy logfile to analyse setup
cp $logFile /home/admin/raspiblitz.setup.log

# set the hostname inputed on initDialog
if [ ${#hostname} -gt 0 ]; then
  echo "Setting new network hostname '$hostname'"
  sudo raspi-config nonint do_hostname ${hostname}
else
  echo "WARN: hostname not set"
fi

# mark setup is done (100%)
sudo sed -i "s/^setupStep=.*/setupStep=100/g" /home/admin/raspiblitz.info

clear
echo "Setup done. Rebooting now."

sleep 3
sudo shutdown -r now