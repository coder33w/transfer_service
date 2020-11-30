#!/bin/bash 

### Global Variable Declarations ###

export yesterday="`date -d "yesterday"  "+%Y-%m-%d"`"
export today="`date "+%Y-%m-%d"`"
export subtr=9
export ret_flag=""
export flag_ex=""

export sensips=("10.1.10.10" "10.1.10.11" "10.1.10.12")
export act_logs="/nsm/bro/logs/$yesterday"

export srcDir="/data/bro/sensor*/$yesterday"
export loginUN="transag23"
export targetIP="52.9.204.32"
export loginDat="$loginUN@$targetIP"
export targetDir="/home/transag23/inbox"



### Function Declarations ###

function xfer_fm_below
{
  # Test if we can reach the sensors, then completes rsync pull via SSH tunnel.
  for ip in ${sensips[@]}                                                                         # iterates through Sensor IPs
  do
    # echo -e "\n\t[`date`] -> Test Connectivity to $ip\n\n"                                        # LOGGING / DEBUG
    ping -c 4 $ip>&1 >/dev/null                                                                   # Pings Sensor IP
  
    if [ $? -eq 0 ]
    then
      # echo -e "\n\n\t[`date`] -> Postive Connectivity - Commencing Transfer Operations\n\n"             # LOGGING / DEBUG
      lastoct=`echo $ip|cut -d. -f4`
  #    echo $lastoct                   # DEBUG
      sensnum="$(($lastoct-$subtr))"
  #    echo $sensnum                   # DEBUG
    
      rsync --partial --chown=admin:transag -rvzi --rsh="ssh -i /home/admin/.adminpull.pem" sensoradmin@$ip:$act_logs /data/bro/sensor$sensnum/ 
      if [ $? = 0 ]
      then
        # echo -e "\n\n\t[`date`] -> RSYNC Pull Completed Successfully on Sensor $sensnum - Starting Permissions Run\n\n"            # LOGGING / DEBUG    
    
        chown -R admin:transag /data/bro/sensor$sensnum
        if [ $? = 0 ]
        then
          chmod -R 750 /data/bro/sensor$sensnum
          if [ $? = 0 ]
          then
            # echo -e "\n\n\t[`date`] -> Permissions Set Complete on /data/bro/sensor$sensnum\n\n"      # LOGGING / DEBUG
          else
            # echo -e "\n\n\t[`date`] -> Ownership Verified - Permissions Set FAILED on Sensor $sensnum\n\n"                                                   # LOGGING / DEBUG
            ret_flag=$ret_flag+perms
          fi

        else
          # echo -e "\n\n\t[`date`] -> Ownership Set FAILED on Sensor $sensnum\n\n"                                                   # LOGGING / DEBUG
          ret_flag=$ret_flag+own
        fi

      else
        # echo -e "\n\n\t[`date`] -> RSYNC Pull FAILED on Sensor $sensnum\n\n"                                                   # LOGGING / DEBUG
        ret_flag=$ret_flag+rsf$sensnum
      fi

    else
      # echo -e "\n\n\t[`date`] -> NEGATIVE CONNECTIVITY - COMMS FAILURE on Sensor $sensnum\n\n"                                                   # LOGGING / DEBUG
      ret_flag=$ret_flag+comms$sensnum
    fi   

  done

  if [ $ret_flag -ne "" ]
  then
    return 9
  else
    return 0
  fi

}


function xfer_to_mp
{
  echo -e "\n\t[`date`] -> Test Connectivity to $targetIP\n\n"                                        # LOGGING / DEBUG

  ssh -i /home/transag/.transag23.pem $loginDat date                                                  # Check connectivity to Target IP
  if [ $? -eq 0 ]
  then
    # echo -e "\n\n\t[`date`] -> Postive Connectivity - Commencing Transfer Operations\n\n"             # LOGGING / DEBUG
    rsync --partial -rvzi --rsh="ssh -i /home/transag/.transag23.pem" $srcDir $loginDat:$targetDir

    if [ $? = 0 ]
    then
      # echo -e "\n\n\t[`date`] -> RSYNC Push Completed Successfully\n\n"            # LOGGING / DEBUG
    else
      # echo -e "\n\n\t[`date`] -> RSYNC Push FAILED\n\n"                                                   # LOGGING / DEBUG
      ret_flag=$ret_flag+ursf
    fi
  else
    # echo -e "\n\n\t[`date`] -> NEGATIVE CONNECTIVITY - COMMS FAILURE\n\n"                                 # LOGGING / DEBUG
    ret_flag=$ret_flag+ucomms
  fi

  if [ $ret_flag -ne "" ]
  then
    return 6
  else
    return 0
  fi
}


function xfer_cleanup
{
#  echo -e "\n\n\t[`date`] -> Starting Cleanup\n\n"            # LOGGING / DEBUG

  rm -rf $srcDir

  if [ $? = 0 ]
  then
#    echo -e "\n\n\t[`date`] -> Cleanup Complete\n\n"                                                  # LOGGING / DEBUG
  else 
#    echo -e "\n\n\t[`date`] -> Cleanup FAILED\n\n"                                                    # LOGGING / DEBUG
    ret_flag=$ret_flag+clean
  fi

  if [ $ret_flag -ne "" ]
  then
    echo $ret_flag
    return 1
  else
    return 0
  fi
}


function flag_id
{
  case $1 
  in
    perms)
      flag_ex="Permission Set Failure on Data Pull"
    ;;
    own)
      flag_ex="Ownership Set Failure on Data Pull"
    ;;
    rsf[1-3])
      num=`echo $1 | cut -b4`
      flag_ex="Rsync Failure on Sensor $num Pull"
    ;;
    comms[1-3])
      num=`echo $1 | cut -b4`
      flag_ex="Comms Failure on Sensor $num Pull"
    ;;
    ursf)
      flag_ex="Rsync Failure on Data Push"
    ;;
    ucomms)
      flag_ex="Comms Failure on Data Push"
    ;;
    clean)
      flag_ex="Cleanup Failure"
    ;;
    *)
      flag_ex="UNKNOWN ERROR"
    ;;
  esac
}





###  START ###

export -f xfer_fm_below

xfer_fm_below
if [ $? -ne 0 ]
then
  flags=`echo $ret_flag | cut -d+ -f2- --output-delimiter=" "`
  echo -e "\n\n"

  for flg in ${flags[@]}
  do
    flag_id $flg
    echo "$flag_ex"
  done 

  ret_flag=""

#  echo -e "\n\n\n\t*** TERMINATING EXECUTION ***\n\n\n\n"
#  exit 126
fi

export -f xfer_to_mp

xfer_to_mp
if [ $? -ne 0 ]
then
  flags=`echo $ret_flag | cut -d+ -f2- --output-delimiter=" "`
  echo -e "\n\n"

  for flg in ${flags[@]}
  do
    flag_id $flg
    echo "$flag_ex"
  done 

  echo -e "\n\n\n\t*** TERMINATING EXECUTION ***\n\n\n\n"

else
  export -f xfer_cleanup

  xfer_cleanup
  if [ $? -ne 0 ]
  then
    flags=`echo $ret_flag | cut -d+ -f2- --output-delimiter=" "`
    echo -e "\n\n"

    for flg in ${flags[@]}
    do
      flag_id $flg
      echo "$flag_ex"
    done 
  fi
fi