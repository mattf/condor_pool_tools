#!/bin/sh

UNUSABLE=FALSE
if [ ! -z "$1" ]; then
  UNUSABLE="$1"
fi
UNUSED='State == "Unclaimed"'
USED='State != "Owner" && State != "Unclaimed"'
UNAVAILABLE="State == \"Owner\" || ($UNUSED && $UNUSABLE)"
AVAILABLE="($UNAVAILABLE) == FALSE"

TMP=$(mktemp $0.XXXXXX)
condor_status -format '%d' "$UNAVAILABLE" -format '\t%d' "$AVAILABLE" -format '\t%d' "$USED" -format '\t%d' Cpus -format '\t%d\n' Memory > $TMP

unavailable_cpus=$(awk 'BEGIN{sum=0} {sum+=$4*$1} END{print sum}' $TMP)
available_cpus=$(awk 'BEGIN{sum=0} {sum+=$4*$2} END{print sum}' $TMP)
used_cpus=$(awk 'BEGIN{sum=0} {sum+=$4*$3} END{print sum}' $TMP)
total_cpus=$((unavailable_cpus + available_cpus))

unavailable_memory=$(awk 'BEGIN{sum=0} {sum+=$5*$1} END{print sum}' $TMP)
available_memory=$(awk 'BEGIN{sum=0} {sum+=$5*$2} END{print sum}' $TMP)
used_memory=$(awk 'BEGIN{sum=0} {sum+=$5*$3} END{print sum}' $TMP)
total_memory=$((unavailable_memory + available_memory))

unavailable_slots=$(awk 'BEGIN{sum=0} {sum+=$1} END{print sum}' $TMP)
available_slots=$(awk 'BEGIN{sum=0} {sum+=$2} END{print sum}' $TMP)
used_slots=$(awk 'BEGIN{sum=0} {sum+=$3} END{print sum}' $TMP)
total_slots=$((unavailable_slots + available_slots))

rm $TMP

percent()
{
   echo "scale=4;($1/$2)*100" | bc
}

if [ $total_slots -eq 0 ]; then
   echo "Well done, 100% utilization"
   exit 0
fi

used_avail_cpu_percent=$(percent $used_cpus $available_cpus)
used_tot_cpu_percent=$(percent $used_cpus $total_cpus)

used_avail_memory_percent=$(percent $used_memory $available_memory)
used_tot_memory_percent=$(percent $used_memory $total_memory)

used_avail_slots_percent=$(percent $used_slots $available_slots)
used_tot_slots_percent=$(percent $used_slots $total_slots)

printf "       Unavailable Available    Total     Used:  Avail   Total\n"
printf "Slots  %11d %9d %8d %8d %6.2f%% %6.2f%%\n" $unavailable_slots $available_slots $total_slots $used_slots $used_avail_slots_percent $used_tot_slots_percent
printf "Cpus   %11d %9d %8d %8d %6.2f%% %6.2f%%\n" $unavailable_cpus $available_cpus $total_cpus $used_cpus $used_avail_cpu_percent $used_tot_cpu_percent
printf "Memory %11d %9d %8d %8d %6.2f%% %6.2f%%\n" $unavailable_memory $available_memory $total_memory $used_memory $used_avail_memory_percent $used_tot_memory_percent
