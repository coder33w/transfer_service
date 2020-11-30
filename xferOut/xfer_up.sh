#!/bin/bash 

# set variables

yesterday="`date -d "yesterday"  "+%Y-%m-%d"`"
targetIP="52.9.204.32"
loginUN="transag23"
loginDat="$loginUN@$targetIP"
targetDir="/home/transag23/inbox"
srcDir="/data/bro/sensor*/$yesterday"



###  START ###

echo -e "\n\t[`date`] -> Test Connectivity to $targetIP\n\n"                                        # LOGGING / DEBUG

ssh -i /home/transag/.transag23.pem $loginDat date                                                  # Check connectivity to Target IP
if [ $? -eq 0 ]
then
  echo -e "\n\n\t[`date`] -> Postive Connectivity - Commencing Transfer Operations\n\n"             # LOGGING / DEBUG
  rsync --partial -rvzi --rsh="ssh -i /home/transag/.transag23.pem" $srcDir $loginDat:$targetDir
  
  if [ $? = 0 ]
  then
    echo -e "\n\n\t[`date`] -> RSYNC Push Completed Successfully\n\n"            # LOGGING / DEBUG
  else
    echo -e "\n\n\t[`date`] -> RSYNC Push FAILED\n\n"                                                   # LOGGING / DEBUG
  fi
else
  echo -e "\n\n\t[`date`] -> NEGATIVE CONNECTIVITY - COMMS FAILURE\n\n"                                 # LOGGING / DEBUG
fi

