#!/bin/bash

## /srv/scripts/part_cleanup.sh
#
## Cleanup script based on pcap_clean.sh
## Modified for more general use

### BEGIN Set GLOBAL variables ###

PART_NAME='/ep_logs'                ## Partition mount point
PART_SUBDIR="$PART_NAME/raw_logs"   ## Subdirectory containing actual data files
ARCHIVE_DIR="$PART_NAME/ARCHIVE"
DISK_OK=50
DISK_ACT=70                         ## Percentage of disk usage that will trigger compression
DISK_MAX=95                         ## Set MAX percentage of disk usage
ZIP_ATATIME=100                     ## Number of files to ZIP
DEL_ATATIME=5                       ## How many files to delete per iteration

### END Set GLOBAL variables ###


### BEGIN MAIN ###

while `pgrep capPay2ascii.sh > /dev/null`
do
  disk_used=`df -h $PART_NAME | awk '{print $5}' | grep -v Use | tr \% " "`   ## Get initial partition usage info

  while ([ "$disk_used" -ge "$DISK_OK" ])
  do
    oldest_n_files=`find $PART_SUBDIR -type f -printf '%T+ %p\n' | sort | head -n $ZIP_ATATIME | cut -d" " -f 2`   ## List N oldest files
    ref_date=`date +%s`

    oldest_date=`echo $oldest_n_files|cut -d" " -f1|cut -d- -f2|cut -d. -f1`
    newest_date=`echo $oldest_n_files|cut -d" " -f$ZIP_ATATIME|cut -d- -f2|cut -d. -f1`
    archive_filename="$ARCHIVE_DIR/$oldest_date-$newest_date.tar.bz2"

    tar -I 'pbzip2 -m2000 -p14' -cvf $archive_filename $oldest_n_files >> /srv/scripts/LOGS/TAR_DEBUG.$ref_date.log

    if [[ $? -ne 0 ]]
    then
      echo "!! TAR-ING ERROR - $? - $archive_filename - `clock` !!" # >> /srv/scripts/LOGS/TAR_DEBUG.$ref_date.log
    else
      for i in "$oldest_n_files"
      do 
        rm -fv $i >> /srv/scripts/LOGS/cleanup_$ref_date.log   ## Remove x of N oldest files
        echo "$i archived and removed, DTG: `clock`" >> /srv/scripts/LOGS/cleanup_$ref_date.log   ## Log file removed
      done
    fi
    
    disk_used=`df -h $PART_NAME | awk '{print $5}' | grep -v Use | tr \% " "`   ## Re-check partition usage info
  
  done

  echo "Disk is within configured capacity limits ($disk_used < $DISK_ACT) . . ."
  sleep 180

done

# while ([ "$disk_used" -ge "$DISK_MAX" ])
# do
#   oldest_n_files=`find $PART_SUBDIR -type f -printf '%T+ %p\n' | sort | head -n $DEL_ATATIME | cut -d" " -f 2`   ## List N oldest files
#   ref_date=`date +%s`
 
#   for i in "$oldest_n_files"
#   do 
#     rm -f $i   ## Remove x of N oldest files
#     echo "$i removed, DTG: `clock`" >> /srv/scripts/cleanup_$ref_date.log   ## Log file removed
#   done
#   disk_used=`df -h $PART_NAME | awk '{print $5}' | grep -v Use | tr \% " "`   ## Re-check partition usage info
# done

### END MAIN ###
