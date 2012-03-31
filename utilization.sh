#!/bin/sh

UNUSABLE=FALSE
if [ ! -z "$1" ]; then
  UNUSABLE="$1"
fi
UNUSED='State == "Unclaimed"'
USED='State != "Owner" && State != "Unclaimed"'
UNAVAILABLE="State == \"Owner\" || ($UNUSED && $UNUSABLE)"
AVAILABLE="($UNAVAILABLE) == FALSE"

# NOTE: If using an UNUSABLE filter, it is possible to have
#       Unavailable+Used slots. A filter such as Cpus==0 will not have
#       this problem. The result of Unvail+Used is that the Avail %
#       for slots can be >100%. Either the >100% needs to be allowed
#       or the Avail % could be adjusted to filter out
#       Unavailable+Used.

TMP=$(mktemp $0.XXXXXX)
condor_status -format '%d' "$UNAVAILABLE" -format '\t%d' "$AVAILABLE" -format '\t%d' "$USED" -format '\t%d' Cpus -format '\t%d\n' Memory > $TMP

printf "       Unavailable Available    Total     Used:  Avail   Total\n"
awk '$1 ~ /1/ {unslots+=1;unmem+=$5;uncpus+=$4}
       $2 ~ /1/ {slots+=1;mem+=$5;cpus+=$4}
       $3 ~ /1/ {useslots+=1;usemem+=$5;usecpus+=$4}
       END {printf "Slots  %11d %9d %8d %8d %6.2f%% %6.2f%%\n", unslots, slots, (unslots+slots), useslots, (useslots/slots)*100, (useslots/(slots+unslots))*100
           printf "Cpus   %11d %9d %8d %8d %6.2f%% %6.2f%%\n", uncpus, cpus, (uncpus+cpus), usecpus, (usecpus/cpus)*100, (usecpus/(cpus+uncpus))*100
           printf "Memory %11d %9d %8d %8d %6.2f%% %6.2f%%\n", unmem, mem, (unmem+mem), usemem, (usemem/mem)*100, (usemem/(mem+unmem))*100}' $TMP

rm $TMP
