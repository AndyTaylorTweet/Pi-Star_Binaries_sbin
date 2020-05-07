#!/bin/bash
#########################################################
#                                                       #
#              HostFilesUpdate.sh Updater               #
#                                                       #
#      Written for Pi-Star (http://www.pistar.uk/)      #
#               By Andy Taylor (MW0MWZ)                 #
#                                                       #
#                     Version 2.6                       #
#                                                       #
#   Based on the update script by Tony Corbett G0WFV    #
#                                                       #
#########################################################


# Check that the network is UP and die if its not
if [ "$(expr length `hostname -I | cut -d' ' -f1`x)" == "1" ]; then
	exit 0
fi

# Get the Pi-Star Version
pistarCurVersion=$(awk -F "= " '/Version/ {print $2}' /etc/pistar-release)

# much of the following vars should probably be extracted to a
# "defaults" file and sourced here so that customizations can
# be set and not affected by upgrades.
DIST_DIR=/usr/local/etc
LOCAL_DIR=/home/pi-star/etc
BACKUP_DIR=${DIST_DIR}

APRSHOSTS=${DIST_DIR}/APRSHosts.txt
DCSHOSTS=${DIST_DIR}/DCS_Hosts.txt
DExtraHOSTS=${DIST_DIR}/DExtra_Hosts.txt
DMRIDFILE=${DIST_DIR}/DMRIds.dat
DMRHOSTS=${DIST_DIR}/DMR_Hosts.txt
DPlusHOSTS=${DIST_DIR}/DPlus_Hosts.txt
P25HOSTS=${DIST_DIR}/P25Hosts.txt
YSFHOSTS=${DIST_DIR}/YSFHosts.txt
FCSHOSTS=${DIST_DIR}/FCSHosts.txt
XLXHOSTS=${DIST_DIR}/XLXHosts.txt
NXDNIDFILE=${DIST_DIR}/NXDN.csv
NXDNHOSTS=${DIST_DIR}/NXDNHosts.txt
TGLISTBM=${DIST_DIR}/TGList_BM.txt
TGLISTP25=${DIST_DIR}/TGList_P25.txt
TGLISTNXDN=${DIST_DIR}/TGList_NXDN.txt
TGLISTYSF=${DIST_DIR}/TGList_YSF.txt

# How many backups
FILEBACKUP=1

# The update_file() function will retrieve the latest data from
# www.pistar.uk or specifed URL as the second param and then perform
# the appropriate overrides / additions from $LOCAL_DIR. Final file
# gets written to $DIST_DIR
update_file() {
	file=$1
	url=${2-http://www.pistar.uk/downloads/${file}}

	# Look for an override file
	if [[ -r ${LOCAL_DIR}/${file}-override ]]; then
		cp ${LOCAL_DIR}/${file}-override ${DIST_DIR}/${file}
	else
		# Download the latest file from www.pistar.uk
		curl --fail -o "${file}".$$ -s ${url} --user-agent "Pi-Star_${pistarCurVersion}"

		# Look for prepend / append files
		[[ -r ${LOCAL_FILE}/${file}-prepend ]] && prepend=${LOCAL_FILE}/${file}-prepend || prepend=''
		[[ -r ${LOCAL_FILE}/${file}-append ]] && prepend=${LOCAL_FILE}/${file}-append || append=''

		# create the DIST_DIR file
		cat ${prepend} ${file}.$$ ${append} > ${DIST_DIR}/${file}
		rm ${file}.$$
	fi

	# Finally allow a hook script to execute if available
	if [[ -x ${LOCAL_DIR}/${file}.sh ]]; then
		${LOCAL_DIR}/${file}.sh ${DIST_DIR}/${file}
	fi
}

# Check we are root
if [ "$(id -u)" != "0" ];then
	echo "This script must be run as root" 1>&2
	exit 1
fi

# Create backup of old files
if [ ${FILEBACKUP} -ne 0 ]; then
	cp ${DIST_DIR}/${APRSHOSTS} ${BACKUP_DIR}/${APRSHOSTS}.$(date +%Y%m%d)
	cp ${DIST_DIR}/${DCSHOSTS} ${BACKUP_DIR}/${DCSHOSTS}.$(date +%Y%m%d)
	cp ${DIST_DIR}/${DExtraHOSTS} ${BACKUP_DIR}/${DExtraHOSTS}.$(date +%Y%m%d)
	cp ${DIST_DIR}/${DMRIDFILE} ${BACKUP_DIR}/${DMRIDFILE}.$(date +%Y%m%d)
	cp ${DIST_DIR}/${DMRHOSTS} ${BACKUP_DIR}/${DMRHOSTS}.$(date +%Y%m%d)
	cp ${DIST_DIR}/${DPlusHOSTS} ${BACKUP_DIR}/${DPlusHOSTS}.$(date +%Y%m%d)
	cp ${DIST_DIR}/${P25HOSTS} ${BACKUP_DIR}/${P25HOSTS}.$(date +%Y%m%d)
	cp ${DIST_DIR}/${YSFHOSTS} ${BACKUP_DIR}/${YSFHOSTS}.$(date +%Y%m%d)
	cp ${DIST_DIR}/${FCSHOSTS} ${BACKUP_DIR}/${FCSHOSTS}.$(date +%Y%m%d)
	cp ${DIST_DIR}/${XLXHOSTS} ${BACKUP_DIR}/${XLXHOSTS}.$(date +%Y%m%d)
	cp ${DIST_DIR}/${NXDNIDFILE} ${BACKUP_DIR}/${NXDNIDFILE}.$(date +%Y%m%d)
	cp ${DIST_DIR}/${NXDNHOSTS} ${BACKUP_DIR}/${NXDNHOSTS}.$(date +%Y%m%d)
	cp ${DIST_DIR}/${TGLISTBM} ${BACKUP_DIR}/${TGLISTBM}.$(date +%Y%m%d)
	cp ${DIST_DIR}/${TGLISTP25} ${BACKUP_DIR}/${TGLISTP25}.$(date +%Y%m%d)
	cp ${DIST_DIR}/${TGLISTNXDN} ${BACKUP_DIR}/${TGLISTNXDN}.$(date +%Y%m%d)
	cp ${DIST_DIR}/${TGLISTYSF} ${BACKUP_DIR}/${TGLISTYSF}.$(date +%Y%m%d)
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
${FCSHOSTS}
${XLXHOSTS}
${NXDNIDFILE}
${NXDNHOSTS}
${TGLISTBM}
${TGLISTP25}
${TGLISTNXDN}
${TGLISTYSF}"

for file in ${FILES}
do
  BACKUPCOUNT=$(ls ${BACKUP_DIR}/${file}.* | wc -l)
  BACKUPSTODELETE=$(expr ${BACKUPCOUNT} - ${FILEBACKUP})
  if [ ${BACKUPCOUNT} -gt ${FILEBACKUP} ]; then
	for f in $(ls -tr ${BACKUP_DIR}/${file}.* | head -${BACKUPSTODELETE})
	do
		rm $f
	done
  fi
done

# Generate Host Files
update_file "${APRSHOSTS}" http://www.pistar.uk/downloads/APRS_Hosts.txt
update_file "${DCSHOSTS}" http://www.pistar.uk/downloads/DCS_Hosts.txt
update_file "${DMRHOSTS}" http://www.pistar.uk/downloads/DMR_Hosts.txt
if [ -f /etc/hostfiles.nodextra ]; then
  # Move XRFs to DPlus Protocol
  update_file "${DPlusHOSTS}" http://www.pistar.uk/downloads/DPlus_WithXRF_Hosts.txt
  update_file "${DExtraHOSTS}" http://www.pistar.uk/downloads/DExtra_NoXRF_Hosts.txt
else
  # Normal Operation
  update_file "${DPlusHOSTS}" http://www.pistar.uk/downloads/DPlus_Hosts.txt
  update_file "${DExtraHOSTS}" http://www.pistar.uk/downloads/DExtra_Hosts.txt
fi
update_file "${DMRIDFILE}" http://www.pistar.uk/downloads/DMRIds.dat
update_file "${P25HOSTS}" http://www.pistar.uk/downloads/P25_Hosts.txt
update_file "${YSFHOSTS}" http://www.pistar.uk/downloads/YSF_Hosts.txt
update_file "${FCSHOSTS}" http://www.pistar.uk/downloads/FCS_Hosts.txt
# update_file "${DExtraHOSTS}" http://www.pistar.uk/downloads/USTrust_Hosts.txt
update_file "${XLXHOSTS}" http://www.pistar.uk/downloads/XLXHosts.txt
update_file "${NXDNIDFILE}" http://www.pistar.uk/downloads/NXDN.csv
update_file "${NXDNHOSTS}" http://www.pistar.uk/downloads/NXDN_Hosts.txt
update_file "${TGLISTBM}" http://www.pistar.uk/downloads/TGList_BM.txt
update_file "${TGLISTP25}" http://www.pistar.uk/downloads/TGList_P25.txt
update_file "${TGLISTNXDN}" http://www.pistar.uk/downloads/TGList_NXDN.txt
update_file "${TGLISTYSF}" http://www.pistar.uk/downloads/TGList_YSF.txt

# This is left here as to not break anyone using it, but should be
# phased out when sites have had sufficient time to change to the
# new override model.
# If there is a DMR Over-ride file, add it's contents to DMR_Hosts.txt
if [ -f "/root/DMR_Hosts.txt" ]; then
	cat /root/DMR_Hosts.txt >> ${DIST_DIR}/${DMRHOSTS}
fi

# Add custom YSF Hosts
if [ -f "/root/YSFHosts.txt" ]; then
	cat /root/YSFHosts.txt >> ${YSFHOSTS}
fi

# Fix DMRGateway issues with brackets
if [ -f "/etc/dmrgateway" ]; then
	sed -i '/Name=.*(/d' /etc/dmrgateway
	sed -i '/Name=.*)/d' /etc/dmrgateway
fi

# Add some fixes for P25Gateway
if [[ $(/usr/local/bin/P25Gateway --version | awk '{print $3}' | cut -c -8) -gt "20180108" ]]; then
	sed -i 's/Hosts=\/usr\/local\/etc\/P25Hosts.txt/HostsFile1=\/usr\/local\/etc\/P25Hosts.txt\nHostsFile2=\/usr\/local\/etc\/P25HostsLocal.txt/g' /etc/p25gateway
	sed -i 's/HostsFile2=\/root\/P25Hosts.txt/HostsFile2=\/usr\/local\/etc\/P25HostsLocal.txt/g' /etc/p25gateway
fi
# This is left here as to not break anyone using it, but should be
# phased out when sites have had sufficient time to change to the
# new override model.
if [ -f "/root/P25Hosts.txt" ]; then
	cat /root/P25Hosts.txt > ${DIST_DIR}/${P25HOSTS}
fi

# Fix up new NXDNGateway Config Hostfile setup
if [[ $(/usr/local/bin/NXDNGateway --version | awk '{print $3}' | cut -c -8) -gt "20180801" ]]; then
	sed -i 's/HostsFile=\/usr\/local\/etc\/NXDNHosts.txt/HostsFile1=\/usr\/local\/etc\/NXDNHosts.txt\nHostsFile2=\/usr\/local\/etc\/NXDNHostsLocal.txt/g' /etc/nxdngateway
fi
if [ ! -f "/root/NXDNHosts.txt" ]; then
	touch /root/NXDNHosts.txt
fi
if [ ! -f "${DIST_DIR}/NXDNHostsLocal.txt" ]; then
	touch ${DIST_DIR}/NXDNHostsLocal.txt
fi

# This is left here as to not break anyone using it, but should be
# phased out when sites have had sufficient time to change to the
# new override model.
# Add custom NXDN Hosts
if [ -f "/root/NXDNHosts.txt" ]; then
	cat /root/NXDNHosts.txt > ${DIST_DIR}/NXDNHostsLocal.txt
fi

# If there is an XLX over-ride
if [ -f "/root/XLXHosts.txt" ]; then
        while IFS= read -r line; do
                if [[ $line != \#* ]] && [[ $line = *";"* ]]
                then
                        xlxid=`echo $line | awk -F  ";" '{print $1}'`
						xlxip=`echo $line | awk -F  ";" '{print $2}'`
                        #xlxip=`grep "^${xlxid}" ${DIST_DIR}/XLXHosts.txt | awk -F  ";" '{print $2}'`
						xlxroom=`echo $line | awk -F  ";" '{print $3}'`
                        xlxNewLine="${xlxid};${xlxip};${xlxroom}"
                        /bin/sed -i "/^$xlxid\;/c\\$xlxNewLine" ${DIST_DIR}/XLXHosts.txt
                fi
        done < /root/XLXHosts.txt
fi

# Yaesu FT-70D radios only do upper case
if [ -f "/etc/hostfiles.ysfupper" ]; then
	sed -i 's/\(.*\)/\U\1/' ${DIST_DIR}/${YSFHOSTS}
	sed -i 's/\(.*\)/\U\1/' ${DIST_DIR}/${FCSHOSTS}
fi

# Fix up ircDDBGateway Host Files on v4
if [ -d "${DIST_DIR}/ircddbgateway" ]; then
	if [[ -f "${DIST_DIR}/ircddbgateway/DCS_Hosts.txt" && ! -L "${DIST_DIR}/ircddbgateway/DCS_Hosts.txt" ]]; then
		rm -rf ${DIST_DIR}/ircddbgateway/DCS_Hosts.txt
		ln -s ${DIST_DIR}/DCS_Hosts.txt ${DIST_DIR}/ircddbgateway/DCS_Hosts.txt
	fi
	if [[ -f "${DIST_DIR}/ircddbgateway/DExtra_Hosts.txt" && ! -L "${DIST_DIR}/ircddbgateway/DExtra_Hosts.txt" ]]; then
		rm -rf ${DIST_DIR}/ircddbgateway/DExtra_Hosts.txt
		ln -s ${DIST_DIR}/DExtra_Hosts.txt ${DIST_DIR}/ircddbgateway/DExtra_Hosts.txt
	fi
	if [[ -f "${DIST_DIR}/ircddbgateway/DPlus_Hosts.txt" && ! -L "${DIST_DIR}/ircddbgateway/DPlus_Hosts.txt" ]]; then
		rm -rf ${DIST_DIR}/ircddbgateway/DPlus_Hosts.txt
		ln -s ${DIST_DIR}/DPlus_Hosts.txt ${DIST_DIR}/ircddbgateway/DPlus_Hosts.txt
	fi
	if [[ -f "${DIST_DIR}/ircddbgateway/CCS_Hosts.txt" && ! -L "${DIST_DIR}/ircddbgateway/CCS_Hosts.txt" ]]; then
		rm -rf ${DIST_DIR}/ircddbgateway/CCS_Hosts.txt
		ln -s ${DIST_DIR}/CCS_Hosts.txt ${DIST_DIR}/ircddbgateway/CCS_Hosts.txt
	fi
fi

exit 0
