#!/bin/bash

#usage
if [ -z $1 ]
then 
	echo "Usage: lootscore.sh [input csv file]"
	exit 1
fi

#create required directories
if [ ! -d "./worksheets" ]
then
	mkdir ./worksheets
fi

if [ ! -d "./logs" ]
then
	mkdir ./logs
fi

if [ ! -d "./scores" ]
then
	mkdir ./scores
fi

#set & clean files before starting
outputfile="./lootscore_$(date -d "today" +"%Y%m%d%H%M").txt"
logfile="./logs/logs_$(date -d "today" +"%Y%m%d%H%M").txt"
echo "" > $logfile
echo "" > $outputfile
echo "" > ./worksheets/worksheet.csv

#remove headers line
tail -n +2 $1 > worksheets/worksheet.csv
#keep only loot received records
grep "received" worksheets/worksheet.csv > worksheets/worksheet_received.csv


#column headers for reference:

#type,raid_group_name,member_name,character_name,character_class,character_is_alt,character_inactive_at,character_note,sort_order,item_name,item_id,is_offspec,note,received_at,import_id,item_note,item_prio_note,item_tier,item_tier_label,created_at,updated_at

#clear scores tables first
while IFS="," read -r c_type c_groupname c_membername c_charname c_class c_isalt c_inactiveat c_note c_sortorder c_itemname c_itemid c_isoffspec c_note c_received_at c_importid c_itemnote c_itemprionote c_x c_itemtier c_itemtierlabel c_createdat c_updatedat 
do
  echo "" > ./scores/$c_charname
done < ./worksheets/worksheet_received.csv

#build a file for each player in scores directory containing a list of all received item scores
while IFS="," read -r c_type c_groupname c_membername c_charname c_class c_isalt c_inactiveat c_note c_sortorder c_itemname c_itemid c_isoffspec c_note c_received_at c_importid c_itemnote c_itemprionote c_x c_itemtier c_itemtierlabel c_createdat c_updatedat 
do
  if [ ! $c_isoffspec -eq 1 ]
  then
    if [[ -z "$c_itemtier" ]]
	then
	  echo "$c_charname : Skipping $c_itemname as it has no tier assigned (received at $c_received_at)"
	  echo "$c_charname : Skipping $c_itemname as it has no tier assigned (received at $c_received_at)" >> $logfile
	elif [[ $c_received_at =~ "2022-10-09 00:00:00" ]] || [[ $c_received_at =~ "2022-10-10 00:00:00" ]]
	then
	  echo "$c_charname : Skipping $c_itemname as it was received during a SR raid (received at $c_received_at)"
	  echo "$c_charname : Skipping $c_itemname as it was received during a SR raid (received at $c_received_at)" >> $logfile
	else
      value=$((7 - $c_itemtier))
      echo "$c_charname : Adding $value for item $c_itemname (received at $c_received_at)"
      echo "$c_charname : Adding $value for item $c_itemname (received at $c_received_at)" >> $logfile
	  echo $value >> ./scores/$c_charname
	fi
  else 
    echo "$c_charname : Adding 0 for OFFSPEC item $c_itemname (received at $c_received_at)"
    echo "$c_charname : Adding 0 for OFFSPEC item $c_itemname (received at $c_received_at)" >> $logfile
	echo 0 >> ./scores/$c_charname
  fi
done < ./worksheets/worksheet_received.csv

#add scores per player together & spit output to lootscore.txt
scoresfiles="./scores/*"
for f in $scoresfiles
do

totalscore=$(awk '{s+=$1} END {print s}' $f)

#  totalscore=0
#  while read line
#  do
#    totalscore=`expr $totalscore + $line`
#  done < $f
  charname=${f:9}
  echo "Total score for $charname = $totalscore"
  echo "Total score for $charname = $totalscore" >> $logfile
  echo "$totalscore for $charname" >> $outputfile
done
sort -n -o $outputfile $outputfile
    
echo "All done!"
echo "All done!" >> $logfile
exit 0