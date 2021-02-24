#!/bin/bash
#########################################################
#                                                       #
#              HostFilesUpdate.sh Updater               #
#                                                       #
#      Written for Pi-Star (http://www.pistar.uk/)      #
#               By Andy Taylor (MW0MWZ)                 #
#                                                       #
#                     Version 2.5                       #
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
FCSHOSTS=/usr/local/etc/FCSHosts.txt
XLXHOSTS=/usr/local/etc/XLXHosts.txt
NXDNIDFILE=/usr/local/etc/NXDN.csv
NXDNHOSTS=/usr/local/etc/NXDNHosts.txt
TGLISTBM=/usr/local/etc/TGList_BM.txt
TGLISTP25=/usr/local/etc/TGList_P25.txt
TGLISTNXDN=/usr/local/etc/TGList_NXDN.txt
TGLISTYSF=/usr/local/etc/TGList_YSF.txt

ICONV_TO_ASCII="iconv -f utf-8 -t ascii//TRANSLIT"
ICONV_PRUNE="iconv -f utf-8 -t ascii//IGNORE"

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
	cp ${FCSHOSTS} ${FCSHOSTS}.$(date +%Y%m%d)
	cp ${XLXHOSTS} ${XLXHOSTS}.$(date +%Y%m%d)
	cp ${NXDNIDFILE} ${NXDNIDFILE}.$(date +%Y%m%d)
	cp ${NXDNHOSTS} ${NXDNHOSTS}.$(date +%Y%m%d)
	cp ${TGLISTBM} ${TGLISTBM}.$(date +%Y%m%d)
	cp ${TGLISTP25} ${TGLISTP25}.$(date +%Y%m%d)
	cp ${TGLISTNXDN} ${TGLISTNXDN}.$(date +%Y%m%d)
	cp ${TGLISTYSF} ${TGLISTYSF}.$(date +%Y%m%d)
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

## Get DMRIds from two different sources, then merge them
curl --fail -o /tmp/DMRIds_1.dat -s http://www.pistar.uk/downloads/DMRIds.dat
curl --fail -o /tmp/DMRIds_2.dat -s http://registry.dstar.su/dmr/DMRIds2.php
if [ -f "/etc/theshield.enabled" ]; then
    curl --fail -s "http://theshield.site/local_subscriber_ids.json" | tee >(python3 -c "exec('import sys, json\nresults = json.load(sys.stdin)[\'results\']\nfor entry in results:\n\ttry:\n\t\tprint(\'{}\\t{}\\t{}\'.format(entry[\'id\'], entry[\'callsign\'], entry[\'fname\'].encode(\'utf-8\', \'ignore\').decode()))\n\texcept:\n\t\tpass\n')" > /tmp/DMRIds_3.dat) >(python3 -c "exec('import sys, json\nresults = json.load(sys.stdin)[\'results\']\nfor entry in results:\n\ttry:\n\t\tplaceHolder=\"\"\n\t\tfname=\"\"\n\t\tcity=\"\"\n\\t\tstate=\"\"\n\t\tcountry=\"\"\n\t\ttry:\n\t\t\tfname=entry[\'fname\'].encode(\'utf-8\', \'ignore\').decode()\n\t\t\tcity=entry[\'city\'].encode(\'utf-8\', \'ignore\').decode()\n\t\t\tstate=entry[\'state\'].encode(\'utf-8\', \'ignore\').decode()\n\t\t\tcountry=entry[\'country\'].encode(\'utf-8\', \'ignore\').decode()\n\t\texcept:\n\t\t\tpass\n\t\tprint(\'{},{},{},{},{},{},{},{}\'.format(entry[\'id\'], entry[\'callsign\'], fname, placeHolder, city, state, country, placeHolder))\n\texcept:\n\t\tpass')" > /tmp/stripped.csv) > /dev/null 2<&1

    ## Wait for the processing to finish
    while [ ! -z "$(ps ax | grep "python3 -c exec('import sys, json" | grep -v grep)" ]; do
	sleep 1s
    done
fi

cat /tmp/DMRIds_1.dat /tmp/DMRIds_2.dat /tmp/DMRIds_3.dat 2>/dev/null | grep -v ^# | awk '($1 > 9999) && ($1 < 10000000) { print $0 }' | sort -un -k1n -o ${DMRIDFILE}
rm -f /tmp/DMRIds_1.dat /tmp/DMRIds_2.dat /tmp/DMRIds_3.dat

# Some downloaded files are badly encoded, fix this on the fly.
curl --fail -s http://www.pistar.uk/downloads/P25_Hosts.txt | ${ICONV_TO_ASCII} > ${P25HOSTS}
curl --fail -s http://www.pistar.uk/downloads/YSF_Hosts.txt | ${ICONV_TO_ASCII} > ${YSFHOSTS}
curl --fail -o ${FCSHOSTS} -s http://www.pistar.uk/downloads/FCS_Hosts.txt
#curl --fail -s http://www.pistar.uk/downloads/USTrust_Hosts.txt >> ${DExtraHOSTS}
curl --fail -o ${XLXHOSTS} -s http://www.pistar.uk/downloads/XLXHosts.txt
curl --fail -o ${NXDNIDFILE} -s http://www.pistar.uk/downloads/NXDN.csv
curl --fail -s http://www.pistar.uk/downloads/NXDN_Hosts.txt | ${ICONV_TO_ASCII} > ${NXDNHOSTS}
curl --fail -o ${TGLISTBM} -s http://www.pistar.uk/downloads/TGList_BM.txt
curl --fail -s http://www.pistar.uk/downloads/TGList_P25.txt | ${ICONV_PRUNE} > ${TGLISTP25}
curl --fail -s http://www.pistar.uk/downloads/TGList_NXDN.txt | ${ICONV_PRUNE} > ${TGLISTNXDN}
curl --fail -o ${TGLISTYSF} -s http://www.pistar.uk/downloads/TGList_YSF.txt

# NextionDriver stuff
if [ "`sed -nr "/^\[NextionDriver\]/,/^\[/{ :l /^\s*[^#].*/ p; n; /^\[/ q; b l; }" /etc/mmdvmhost | grep "Enable" | cut -d= -f 2`" == "1" ]; then
    curl --fail -k -o /usr/local/etc/groups.txt -s https://api.brandmeister.network/v1.0/groups/
    curl --fail -o /tmp/stripped_upstream.csv -s https://database.radioid.net/static/user.csv
    cat /tmp/stripped_upstream.csv /tmp/stripped.csv 2>/dev/null | sort -un -k1n -o /usr/local/etc/stripped.csv
    rm -f /tmp/stripped_upstream.csv
fi
rm -f /tmp/stripped.csv


# If there is a DMR Over-ride file, add it's contents to DMR_Hosts.txt
if [ -f "/root/DMR_Hosts.txt" ]; then
	cat /root/DMR_Hosts.txt >> ${DMRHOSTS}
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
if [ -f "/root/P25Hosts.txt" ]; then
	cat /root/P25Hosts.txt > /usr/local/etc/P25HostsLocal.txt
fi

# Fix up new NXDNGateway Config Hostfile setup
if [[ $(/usr/local/bin/NXDNGateway --version | awk '{print $3}' | cut -c -8) -gt "20180801" ]]; then
	sed -i 's/HostsFile=\/usr\/local\/etc\/NXDNHosts.txt/HostsFile1=\/usr\/local\/etc\/NXDNHosts.txt\nHostsFile2=\/usr\/local\/etc\/NXDNHostsLocal.txt/g' /etc/nxdngateway
fi
if [ ! -f "/root/NXDNHosts.txt" ]; then
	touch /root/NXDNHosts.txt
fi
if [ ! -f "/usr/local/etc/NXDNHostsLocal.txt" ]; then
	touch /usr/local/etc/NXDNHostsLocal.txt
fi

# Add custom NXDN Hosts
if [ -f "/root/NXDNHosts.txt" ]; then
	cat /root/NXDNHosts.txt > /usr/local/etc/NXDNHostsLocal.txt
fi

# If there is an XLX over-ride
if [ -f "/root/XLXHosts.txt" ]; then
        while IFS= read -r line; do
                if [[ $line != \#* ]] && [[ $line = *";"* ]]
                then
                        xlxid=`echo $line | awk -F  ";" '{print $1}'`
			xlxip=`echo $line | awk -F  ";" '{print $2}'`
                        #xlxip=`grep "^${xlxid}" /usr/local/etc/XLXHosts.txt | awk -F  ";" '{print $2}'`
			xlxroom=`echo $line | awk -F  ";" '{print $3}'`
                        xlxNewLine="${xlxid};${xlxip};${xlxroom}"
                        /bin/sed -i "/^$xlxid\;/c\\$xlxNewLine" /usr/local/etc/XLXHosts.txt
                fi
        done < /root/XLXHosts.txt
fi

# Yaesu FT-70D radios only do upper case
if [ -f "/etc/hostfiles.ysfupper" ]; then
	sed -i 's/\(.*\)/\U\1/' ${YSFHOSTS}
	sed -i 's/\(.*\)/\U\1/' ${FCSHOSTS}
fi

# Fix up ircDDBGateway Host Files on v4
if [ -d "/usr/local/etc/ircddbgateway" ]; then
	if [[ -f "/usr/local/etc/ircddbgateway/DCS_Hosts.txt" && ! -L "/usr/local/etc/ircddbgateway/DCS_Hosts.txt" ]]; then
		rm -rf /usr/local/etc/ircddbgateway/DCS_Hosts.txt
		ln -s /usr/local/etc/DCS_Hosts.txt /usr/local/etc/ircddbgateway/DCS_Hosts.txt
	fi
	if [[ -f "/usr/local/etc/ircddbgateway/DExtra_Hosts.txt" && ! -L "/usr/local/etc/ircddbgateway/DExtra_Hosts.txt" ]]; then
		rm -rf /usr/local/etc/ircddbgateway/DExtra_Hosts.txt
		ln -s /usr/local/etc/DExtra_Hosts.txt /usr/local/etc/ircddbgateway/DExtra_Hosts.txt
	fi
	if [[ -f "/usr/local/etc/ircddbgateway/DPlus_Hosts.txt" && ! -L "/usr/local/etc/ircddbgateway/DPlus_Hosts.txt" ]]; then
		rm -rf /usr/local/etc/ircddbgateway/DPlus_Hosts.txt
		ln -s /usr/local/etc/DPlus_Hosts.txt /usr/local/etc/ircddbgateway/DPlus_Hosts.txt
	fi
	if [[ -f "/usr/local/etc/ircddbgateway/CCS_Hosts.txt" && ! -L "/usr/local/etc/ircddbgateway/CCS_Hosts.txt" ]]; then
		rm -rf /usr/local/etc/ircddbgateway/CCS_Hosts.txt
		ln -s /usr/local/etc/CCS_Hosts.txt /usr/local/etc/ircddbgateway/CCS_Hosts.txt
	fi
fi

exit 0
