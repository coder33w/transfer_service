#!/bin/bash 

# set variables

yesterday="`date -d "yesterday"  "+%Y-%m-%d"`"
sensips=("10.1.10.10" "10.1.10.11" "10.1.10.12")
act_logs="/nsm/bro/logs/$yesterday"
subtr=9

###  START ###

# Test if we can reach the sensors, then completes rsync pull via SSH tunnel.
for ip in ${sensips[@]}                                                                         # iterates through Sensor IPs
do
  echo -e "\n\t[`date`] -> Test Connectivity to $ip\n\n"                                        # LOGGING / DEBUG
  ping -c 4 $ip>&1 >/dev/null                                                                   # Pings Sensor IP
  
  if [ $? -eq 0 ]
  then
    echo -e "\n\n\t[`date`] -> Postive Connectivity - Commencing Transfer Operations\n\n"             # LOGGING / DEBUG
    lastoct=`echo $ip|cut -d. -f4`
#    echo $lastoct                   # DEBUG
    sensnum="$(($lastoct-$subtr))"
#    echo $sensnum                   # DEBUG
    
    rsync --partial --chown=admin:transag -rvzi --rsh="ssh -i /home/admin/.adminpull.pem" sensoradmin@$ip:$act_logs /data/bro/sensor$sensnum/
    if [ $? = 0 ]
    then
      echo -e "\n\n\t[`date`] -> RSYNC Pull Completed Successfully on Sensor $sensnum - Starting Permissions Run\n\n"            # LOGGING / DEBUG    
    
      chown -R admin:transag /data/bro/sensor$sensnum
      if [ $? = 0 ]
      then
        chmod -R 750 /data/bro/sensor$sensnum
        if [ $? = 0 ]
        then
          echo -e "\n\n\t[`date`] -> Permissions Set Complete on /data/bro/sensor$sensnum\n\n"      # LOGGING / DEBUG
        else
          echo -e "\n\n\t[`date`] -> Ownership Verified - Permissions Set FAILED on Sensor $sensnum\n\n"                                                   # LOGGING / DEBUG
        fi

      else
        echo -e "\n\n\t[`date`] -> Ownership Set FAILED on Sensor $sensnum\n\n"                                                   # LOGGING / DEBUG
      fi

    else
      echo -e "\n\n\t[`date`] -> RSYNC Pull FAILED on Sensor $sensnum\n\n"                                                   # LOGGING / DEBUG
    fi

  else
    echo -e "\n\n\t[`date`] -> NEGATIVE CONNECTIVITY - COMMS FAILURE on Sensor $sensnum\n\n"                                                   # LOGGING / DEBUG
  fi   

done
