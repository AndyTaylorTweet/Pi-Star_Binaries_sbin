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

if [ -f /boot/Pi-Star_Config_*.zip ]; then
	# Create the working directory
	if [ ! -d /tmp/config_restore ]; then
		mkdir /tmp/config_restore
	fi
	# Unpack the configs
	unzip -j /boot/Pi-Star_Config_*.zip -d /tmp/config_restore/ 2>&1
elif [ -f /boot/firmware/Pi-Star_Config_*.zip ]; then
	# Create the working directory
	if [ ! -d /tmp/config_restore ]; then
		mkdir /tmp/config_restore
	fi
	# Unpack the configs
	unzip -j /boot/firmware/Pi-Star_Config_*.zip -d /tmp/config_restore/ 2>&1
else
	exit 1
fi

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
if [ -d /boot/firmware ]; then
  (sudo mount -o remount,rw / 2>/dev/null ; sudo mount -o remount,rw /boot/firmware 2>/dev/null)
else
  mount -o remount,rw /boot
  mount -o remount,rw /
fi

# Overwrite the configs
rm -f /etc/dstar-radio.* 2>&1
mv -f /tmp/config_restore/ircddblocal.php /var/www/dashboard/config/ 2>&1
mv -f /tmp/config_restore/config.php /var/www/dashboard/config/ 2>&1
mv -f /tmp/config_restore/wpa_supplicant.conf /etc/wpa_supplicant/ 2>&1
mv -f /tmp/config_restore/* /etc/ 2>&1

#Set the Timezone
timedatectl set-timezone `grep date /var/www/dashboard/config/config.php | grep -o "'.*'" | sed "s/'//g"`

# Clean up
if [ -d /boot/firmware ]; then
  rm -rf /boot/firmware/Pi-Star_Config_*.zip 2>&1
else
  rm -rf /boot/Pi-Star_Config_*.zip 2>&1
fi
sync: sync; sync;
reboot

exit 0
