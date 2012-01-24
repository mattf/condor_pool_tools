#!/bin/sh

UNUSABLE=FALSE
if [ ! -z "$1" ]; then
  UNUSABLE="$1"
fi
UNUSED='State == "Unclaimed"'
USED='State != "Owner" && State != "Unclaimed"'
UNAVAILABLE="State == \"Owner\" || ($UNUSED && $UNUSABLE)"
AVAILABLE="($UNAVAILABLE) == FALSE"

unavailable_cpus=$(condor_status -constraint "$UNAVAILABLE" -format '%d\n' Cpus | awk 'BEGIN{sum=0} {sum+=$1} END{print sum}')
available_cpus=$(condor_status -constraint "$AVAILABLE" -format '%d\n' Cpus | awk 'BEGIN{sum=0} {sum+=$1} END{print sum}')
total_cpus=$((unavailable_cpus + available_cpus))
used_cpus=$(condor_status -constraint "$USED" -format '%d\n' Cpus | awk 'BEGIN{sum=0} {sum+=$1} END{print sum}')

unavailable_memory=$(condor_status -constraint "$UNAVAILABLE" -format '%d\n' Memory | awk 'BEGIN{sum=0} {sum+=$1} END{print sum}')
available_memory=$(condor_status -constraint "$AVAILABLE" -format '%d\n' Memory | awk 'BEGIN{sum=0} {sum+=$1} END{print sum}')
total_memory=$((unavailable_memory + available_memory))
used_memory=$(condor_status -constraint "$USED" -format '%d\n' Memory | awk 'BEGIN{sum=0} {sum+=$1} END{print sum}')

unavailable_slots=$(condor_status -constraint "$UNAVAILABLE" -format '1\n' None | awk 'BEGIN{sum=0} {sum+=$1} END{print sum}')
available_slots=$(condor_status -constraint "$AVAILABLE" -format '1\n' None | awk 'BEGIN{sum=0} {sum+=$1} END{print sum}')
total_slots=$((unavailable_slots + available_slots))
used_slots=$(condor_status -constraint "$USED" -format '1\n' None | awk 'BEGIN{sum=0} {sum+=$1} END{print sum}')

percent()
{
   echo "scale=4;($1/$2)*100" | bc
}

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
