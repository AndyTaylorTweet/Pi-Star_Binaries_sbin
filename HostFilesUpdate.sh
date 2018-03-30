#!/bin/bash
#########################################################
#                                                       #
#              HostFilesUpdate.sh Updater               #
#                                                       #
#      Written for Pi-Star (http://www.pistar.uk/)      #
#               By Andy Taylor (MW0MWZ)                 #
#                                                       #
#                     Version 2.20                      #
#                                                       #
#   Based on the update script by Tony Corbett G0WFV    #
#                                                       #
#########################################################

# Check that the network is UP and die if its not
if [ "$(expr length `hostname -I | cut -d' ' -f1`x)" == "1" ]; then
	exit 0
fi

APRSHOSTS=/usr/local/etc/APRSHosts.txt
DCSHOSTS=/usr/local/etc/DCS_Hosts.txt
DExtraHOSTS=/usr/local/etc/DExtra_Hosts.txt
DMRIDFILE=/usr/local/etc/DMRIds.dat
DMRHOSTS=/usr/local/etc/DMR_Hosts.txt
DPlusHOSTS=/usr/local/etc/DPlus_Hosts.txt
P25HOSTS=/usr/local/etc/P25Hosts.txt
YSFHOSTS=/usr/local/etc/YSFHosts.txt
XLXHOSTS=/usr/local/etc/XLXHosts.txt
NXDNIDFILE=/usr/local/etc/NXDN.csv
NXDNHOSTS=/usr/local/etc/NXDNHosts.txt
TGLISTBM=/usr/local/etc/TGList_BM.txt

# How many backups
FILEBACKUP=1

# Check we are root
if [ "$(id -u)" != "0" ];then
	echo "This script must be run as root" 1>&2
	exit 1
fi

# Create backup of old files
if [ ${FILEBACKUP} -ne 0 ]; then
	cp ${APRSHOSTS} ${APRSHOSTS}.$(date +%Y%m%d)
	cp ${DCSHOSTS} ${DCSHOSTS}.$(date +%Y%m%d)
	cp ${DExtraHOSTS} ${DExtraHOSTS}.$(date +%Y%m%d)
	cp ${DMRIDFILE} ${DMRIDFILE}.$(date +%Y%m%d)
	cp ${DMRHOSTS} ${DMRHOSTS}.$(date +%Y%m%d)
	cp ${DPlusHOSTS} ${DPlusHOSTS}.$(date +%Y%m%d)
	cp ${P25HOSTS} ${P25HOSTS}.$(date +%Y%m%d)
	cp ${YSFHOSTS} ${YSFHOSTS}.$(date +%Y%m%d)
	cp ${XLXHOSTS} ${XLXHOSTS}.$(date +%Y%m%d)
	cp ${NXDNIDFILE} ${NXDNIDFILE}.$(date +%Y%m%d)
	cp ${NXDNHOSTS} ${NXDNHOSTS}.$(date +%Y%m%d)
	cp ${TGLISTBM} ${TGLISTBM}.$(date +%Y%m%d)
fi

# Prune backups
FILES="${APRSHOSTS}
${DCSHOSTS}
${DExtraHOSTS}
${DMRIDFILE}
${DMRHOSTS}
${DPlusHOSTS}
${P25HOSTS}
${YSFHOSTS}
${XLXHOSTS}
${NXDNIDFILE}
${NXDNHOSTS}
${TGLISTBM}"

for file in ${FILES}
do
  BACKUPCOUNT=$(ls ${file}.* | wc -l)
  BACKUPSTODELETE=$(expr ${BACKUPCOUNT} - ${FILEBACKUP})
  if [ ${BACKUPCOUNT} -gt ${FILEBACKUP} ]; then
	for f in $(ls -tr ${file}.* | head -${BACKUPSTODELETE})
	do
		rm $f
	done
  fi
done

# Generate Host Files
curl --fail -o ${APRSHOSTS} -s http://www.pistar.uk/downloads/APRS_Hosts.txt
curl --fail -o ${DCSHOSTS} -s http://www.pistar.uk/downloads/DCS_Hosts.txt
curl --fail -o ${DMRHOSTS} -s http://www.pistar.uk/downloads/DMR_Hosts.txt
if [ -f /etc/hostfiles.nodextra ]; then
  # Move XRFs to DPlus Protocol
  curl --fail -o ${DPlusHOSTS} -s http://www.pistar.uk/downloads/DPlus_WithXRF_Hosts.txt
  curl --fail -o ${DExtraHOSTS} -s http://www.pistar.uk/downloads/DExtra_NoXRF_Hosts.txt
else
  # Normal Operation
  curl --fail -o ${DPlusHOSTS} -s http://www.pistar.uk/downloads/DPlus_Hosts.txt
  curl --fail -o ${DExtraHOSTS} -s http://www.pistar.uk/downloads/DExtra_Hosts.txt
fi
curl --fail -o ${DMRIDFILE} -s http://www.pistar.uk/downloads/DMRIds.dat
curl --fail -o ${P25HOSTS} -s http://www.pistar.uk/downloads/P25_Hosts.txt
curl --fail -o ${YSFHOSTS} -s http://www.pistar.uk/downloads/YSF_Hosts.txt
#curl --fail -s http://www.pistar.uk/downloads/USTrust_Hosts.txt >> ${DExtraHOSTS}
curl --fail -o ${XLXHOSTS} -s http://www.pistar.uk/downloads/XLXHosts.txt
curl --fail -o ${NXDNIDFILE} -s http://www.pistar.uk/downloads/NXDN.csv
curl --fail -o ${NXDNHOSTS} -s http://www.pistar.uk/downloads/NXDN_Hosts.txt
curl --fail -o ${TGLISTBM} -s http://www.pistar.uk/downloads/TGList_BM.txt

# If there is a DMR Over-ride file, add it's contents to DMR_Hosts.txt
if [ -f "/root/DMR_Hosts.txt" ]; then
	cat /root/DMR_Hosts.txt >> ${DMRHOSTS}
fi

# Add some fixes for P25Gateway
if [[ $(/usr/local/bin/P25Gateway --version | awk '{print $3}' | cut -c -8) -gt "20180108" ]]; then
	sed -i 's/Hosts=\/usr\/local\/etc\/P25Hosts.txt/HostsFile1=\/usr\/local\/etc\/P25Hosts.txt\nHostsFile2=\/usr\/local\/etc\/P25HostsLocal.txt/g' /etc/p25gateway
	sed -i 's/HostsFile2=\/root\/P25Hosts.txt/HostsFile2=\/usr\/local\/etc\/P25HostsLocal.txt/g' /etc/p25gateway
fi

# If there is an XLX over-ride
if [ -f "/root/XLXHosts.txt" ]; then
	while IFS= read -r line; do
		if [[ $line != \#* ]]
		then
			xlxid=`echo $line | awk -F  ";" '{print $1}'`
			/bin/sed -i "/^$xlxid\;/c\\$line" /usr/local/etc/XLXHosts.txt
		fi
	done < /root/XLXHosts.txt
fi

exit 0
