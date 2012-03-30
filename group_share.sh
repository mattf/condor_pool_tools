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
condor_status -format '%d' "$UNAVAILABLE" -format '\t%d' "$AVAILABLE" -format '\t%d' "$USED" -format '\t%d' Cpus -format '\t%d' Memory -format '\t%s\n' 'ifThenElse(AccountingGroup=!=UNDEFINED, AccountingGroup, "None")' > $TMP

printf "Used ( Avail) Group\n"
(awk '$1 ~ /1/ {unavail+=$4}
        $2 ~ /1/ {avail+=$4}
        $3 ~ /1/ {used+=$4;groups[substr($6,0,index($6,"@")-1)]+=$4}
        $3 ~ /1/ $6 ~ /None/ {used+=$4;groups[$6]+=$4}
        END {for (group in groups)
                printf "%4d (%5.2f%%) %s\n", groups[group], (groups[group]/avail)*100, group
             printf "%4d  %5.2f%% - Total\n", used, (used/avail)*100}' $TMP
) | sort -k1 -n

rm $TMP
