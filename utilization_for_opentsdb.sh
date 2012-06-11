#!/bin/sh

# USAGE -
#  0) tsdb mkmetric condor.pool.slots.unavail condor.pool.slots.avail condor.pool.slots.total condor.pool.slots.used condor.pool.slots.used_of_avail condor.pool.slots.used_of_total condor.pool.cpus.unavail condor.pool.cpus.avail condor.pool.cpus.total condor.pool.cpus.used condor.pool.cpus.used_of_avail condor.pool.cpus.used_of_total condor.pool.memory.unavail condor.pool.memory.avail condor.pool.memory.total condor.pool.memory.used condor.pool.memory.used_of_avail condor.pool.memory.used_of_total
#  1) while true; do ./utilization_for_opentsdb.sh; sleep 15; done | nc -w 30 tsdb-host 4242

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

condor_status -format '%d' "$UNAVAILABLE" -format '\t%d' "$AVAILABLE" -format '\t%d' "$USED" -format '\t%d' Cpus -format '\t%d\n' Memory | \
awk -v pool=$(condor_config_val COLLECTOR_HOST) \
    'BEGIN { time = systime() }
       func put(name, value) { print "put " name, time, value, "pool=" pool }
       $1 ~ /1/ {unslots+=1;unmem+=$5;uncpus+=$4}
       $2 ~ /1/ {slots+=1;mem+=$5;cpus+=$4}
       $3 ~ /1/ {useslots+=1;usemem+=$5;usecpus+=$4}
       END {put("condor.pool.slots.unavail", unslots);
            put("condor.pool.slots.avail", slots);
            put("condor.pool.slots.total", (unslots+slots));
            put("condor.pool.slots.used", useslots);
            put("condor.pool.slots.used_of_avail", useslots/slots);
            put("condor.pool.slots.used_of_total", useslots/(unslots+slots));
            put("condor.pool.cpus.unavail", uncpus);
            put("condor.pool.cpus.avail", cpus);
            put("condor.pool.cpus.total", (uncpus+cpus));
            put("condor.pool.cpus.used", usecpus);
            put("condor.pool.cpus.used_of_avail", usecpus/cpus);
            put("condor.pool.cpus.used_of_total", usecpus/(uncpus+cpus));
            put("condor.pool.memory.unavail", unmem);
            put("condor.pool.memory.avail", mem);
            put("condor.pool.memory.total", (unmem+mem));
            put("condor.pool.memory.used", usemem);
            put("condor.pool.memory.used_of_avail", usemem/mem);
            put("condor.pool.memory.used_of_total", usemem/(unmem+mem))}'
