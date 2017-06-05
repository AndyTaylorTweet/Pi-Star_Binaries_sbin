#!/bin/bash
#########################################################
#                                                       #
#               Config Restore on Bootup                #
#                                                       #
# Written for Pi-Star (http://www.mw0mwz.co.uk/pi-star) #
#               By Andy Taylor (MW0MWZ)                 #
#                                                       #
#                     Version 1.0                       #
#                                                       #
#########################################################

# Check we are root
if [ "$(id -u)" != "0" ]
then
        echo "This script must be run as root" 1>&2
        exit 1
fi

if [ ! -f /boot/Pi-Star_Config_*.zip ]; then
	exit 1
fi

# First lets make the working directory
if [ ! -d /tmp/config_restore ]; then
	mkdir /tmp/config_restore
fi

# Unpack the configs
unzip -j /boot/Pi-Star_Config_*.zip -d /tmp/config_restore/ 2>&1

# Stop the services
systemctl stop cron.service 2>&1
systemctl stop dstarrepeater.service 2>&1
systemctl stop mmdvmhost.service 2>&1
systemctl stop ircddbgateway.service 2>&1
systemctl stop timeserver.service 2>&1
systemctl stop pistar-watchdog.service 2>&1
systemctl stop ysfgateway.service 2>&1
systemctl stop p25gateway.service 2>&1

# Make the disk writable
mount -o remount,rw / 2>&1
mount -o remount,rw /boot 2>&1

# Overwrite the configs
rm -f /etc/dstar-radio.* 2>&1
mv -f /tmp/config_restore/ircddblocal.php /var/www/dashboard/config/ 2>&1
mv -f /tmp/config_restore/config.php /var/www/dashboard/config/ 2>&1
mv -f /tmp/config_restore/wpa_supplicant.conf /etc/wpa_supplicant/ 2>&1
mv -f /tmp/config_restore/* /etc/ 2>&1

#Set the Timezone
timedatectl set-timezone `grep date /var/www/dashboard/config/config.php | grep -o "'.*'" | sed "s/'//g"`

# Clean up
rm -rf /boot/Pi-Star_Config_*.zip 2>&1

reboot

exit 0
