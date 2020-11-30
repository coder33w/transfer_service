#!/bin/bash 

# set variables

yesterday="`date -d "yesterday"  "+%Y-%m-%d"`"
srcDir="/data/bro/sensor*/$yesterday"



###  START ###

echo -e "\n\n\t[`date`] -> Starting Cleanup\n\n"            # LOGGING / DEBUG

    rm -rf $srcDir

    if [ $? = 0 ]
    then
      echo -e "\n\n\t[`date`] -> Cleanup Complete\n\n"                                                  # LOGGING / DEBUG
    else 
      echo -e "\n\n\t[`date`] -> Cleanup FAILED\n\n"                                                    # LOGGING / DEBUG
    fi

 
