#! /bin/bash

###############################################################################
#
# HostsFilesUpdate.sh
#
# Copyright (C) 2016 by Tony Corbett G0WFV
# Adapted by Andy Taylor MW0MWZ on 16-Feb-2017 with all crdeit
# to G0WFV for the orignal script.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
###############################################################################
#
#                              CONFIGURATION
#
# Full path to Host Files
#
###############################################################################

APRSHOSTS=/usr/local/etc/APRSHosts.txt
DCSHOSTS=/usr/local/etc/DCS_Hosts.txt
DExtraHOSTS=/usr/local/etc/DExtra_Hosts.txt
DMRIDFILE=/usr/local/etc/DMRIds.dat
DMRHOSTS=/usr/local/etc/DMR_Hosts.txt
DPlusHOSTS=/usr/local/etc/DPlus_Hosts.txt
P25HOSTS=/usr/local/etc/P25Hosts.txt
YSFHOSTS=/usr/local/etc/YSFHosts.txt

# How many DCSHosts files do you want backed up (0 = do not keep backups)
FILEBACKUP=1

###############################################################################
#
# Do not edit below here
#
###############################################################################

# Check we are root
if [ "$(id -u)" != "0" ]
then
	echo "This script must be run as root" 1>&2
	exit 1
fi

# Create backup of old files
if [ ${FILEBACKUP} -ne 0 ]
then
	cp ${APRSHOSTS} ${APRSHOSTS}.$(date +%Y%m%d)
	cp ${DCSHOSTS} ${DCSHOSTS}.$(date +%Y%m%d)
	cp ${DExtraHOSTS} ${DExtraHOSTS}.$(date +%Y%m%d)
	cp ${DMRIDFILE} ${DMRIDFILE}.$(date +%Y%m%d)
	cp ${DMRHOSTS} ${DMRHOSTS}.$(date +%Y%m%d)
	cp ${DPlusHOSTS} ${DPlusHOSTS}.$(date +%Y%m%d)
	cp ${P25HOSTS} ${P25HOSTS}.$(date +%Y%m%d)
	cp ${YSFHOSTS} ${YSFHOSTS}.$(date +%Y%m%d)
fi

# Prune backups
FILES="${APRSHOSTS}
${DCSHOSTS}
${DExtraHOSTS}
${DMRIDFILE}
${DMRHOSTS}
${DPlusHOSTS}
${P25HOSTS}
${YSFHOSTS}"

for file in ${FILES}
do
  BACKUPCOUNT=$(ls ${file}.* | wc -l)
  BACKUPSTODELETE=$(expr ${BACKUPCOUNT} - ${FILEBACKUP})

  if [ ${BACKUPCOUNT} -gt ${FILEBACKUP} ]
  then
	for f in $(ls -tr ${file}.* | head -${BACKUPSTODELETE})
	do
		rm $f
	done
  fi
done

# Generate Host Files
curl --fail -s http://www.mw0mwz.co.uk/pi-star/APRS_Hosts.txt > ${APRSHOSTS}
curl --fail -s http://www.mw0mwz.co.uk/pi-star/DCS_Hosts.txt > ${DCSHOSTS}
curl --fail -s http://www.mw0mwz.co.uk/pi-star/DMR_Hosts.txt > ${DMRHOSTS}
curl --fail -s http://www.mw0mwz.co.uk/pi-star/DPlus_Hosts.txt > ${DPlusHOSTS}
curl --fail -s http://www.mw0mwz.co.uk/pi-star/DExtra_Hosts.txt >> ${DPlusHOSTS}
curl --fail -s http://www.mw0mwz.co.uk/pi-star/DMRIds.dat > ${DMRIDFILE}
curl --fail -s http://www.mw0mwz.co.uk/pi-star/P25_Hosts.txt > ${P25HOSTS}
curl --fail -s http://www.mw0mwz.co.uk/pi-star/YSF_Hosts.txt > ${YSFHOSTS}
curl --fail -s http://www.mw0mwz.co.uk/pi-star/USTrust_Hosts.txt > ${DExtraHOSTS}

exit 0
