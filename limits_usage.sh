#!/bin/sh

WARN=0
if [ -n "$1" ]; then WARN=$1; fi

percent()
{
   echo "scale=4;($1/$2)*100" | bc
}

TMP=$(mktemp $0.XXXXXX)
# This could time out if the negotiator is busy
condor_userprio -l | awk '/^ConcurrencyLimit_/ {split($1, l, "_"); print l[2], int($3)}' > $TMP

printf "         Limit    Use    Max   Diff      %%\n"
while read line; do
   limit=${line% *}
   use=${line#* }
   max=$(condor_config_val ${limit}_LIMIT 2> /dev/null)
   if [ $? -ne 0 ]; then continue; fi

   printf "%14.14s %6d %6d %6d %6.2f" $limit $use $max $((max - use)) $(percent $use $max)
   if [ $((max - use)) -le $WARN ]; then printf " *"; fi
   printf "\n"
done < $TMP

rm $TMP
