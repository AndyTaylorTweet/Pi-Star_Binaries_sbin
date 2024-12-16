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
if [ "$(id -u)" != "0" ]; then
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
systemctl stop nextiondriver.service 2>&1
systemctl stop ircddbgateway.service 2>&1
systemctl stop timeserver.service 2>&1
systemctl stop pistar-watchdog.service 2>&1
systemctl stop pistar-remote.service 2>&1
systemctl stop ysfgateway.service 2>&1
systemctl stop ysfparrot.service 2>&1
systemctl stop ysf2dmr.service 2>&1
systemctl stop ysf2p25.service 2>&1
systemctl stop ysf2nxdn.service 2>&1
systemctl stop p25gateway.service 2>&1
systemctl stop dapnetgateway.service 2>&1
systemctl stop p25parrot.service 2>&1
systemctl stop nxdngateway.service 2>&1
systemctl stop nxdnparrot.service 2>&1
systemctl stop m17gateway.service 2>&1
systemctl stop dmr2ysf.service 2>&1
systemctl stop dmr2nxdn.service 2>&1
systemctl stop dmrgateway.service 2>&1
systemctl stop aprsgateway.service 2>&1

# Make the disk writable
fw=$(sed -n "s|/dev/.*/boot\(.*\) [ve].*|\1|p"  /proc/mounts)
mount -o remount,rw /
mount -o remount,rw /boot${fw}

# Overwrite the configs
rm -f /etc/dstar-radio.* 2>&1

mv -f /tmp/config_restore/ircddblocal.php /var/www/dashboard/config/ 2>&1
mv -f /tmp/config_restore/config.php /var/www/dashboard/config/ 2>&1
mv -f /tmp/config_restore/wpa_supplicant.conf /etc/wpa_supplicant/ 2>&1
mv -f /tmp/config_restore/* /etc/ 2>&1

# Just in case
sudo dos2unix /etc/wpa_supplicant/wpa_supplicant.conf 2>&1
sudo dos2unix /etc/pistar-remote 2>&1

# Set the Timezone
timedatectl set-timezone `grep date /var/www/dashboard/config/config.php | grep -o "'.*'" | sed "s/'//g"`

# Clean up
rm -rf /boot/Pi-Star_Config_*.zip 2>&1
sync: sync; sync;
reboot

exit 0
