#!/bin/sh

# USAGE -
#  0) tsdb mkmetric condor.schedd.jobs.idle condor.schedd.jobs.running condor.schedd.jobs.held condor.schedd.jobs.mean_runtime condor.schedd.jobs.mean_waittime condor.schedd.jobs.historical.mean_runtime condor.schedd.jobs.historical.mean_waittime condor.schedd.jobs.submission_rate condor.schedd.jobs.start_rate condor.schedd.jobs.completion_rate
#  1) while true; do ./schedd_stats_for_opentsdb.sh; sleep 15; done | nc -w 30 tsdb-host 4242

# TODO -
#  condor.pool.jobs.*

condor_status -schedd \
              -format "%s" Name \
              -format " %d" TotalIdleJobs \
              -format " %d" TotalRunningJobs \
              -format " %d" TotalHeldJobs \
              -format " %f" MeanRunningTime \
              -format " %f" MeanTimeToStart \
              -format " %f" MeanRunningTimeCum \
              -format " %f" MeanTimeToStartCum \
              -format " %f" JobSubmissionRate \
              -format " %f" JobStartRate \
              -format " %f" JobCompletionRate \
              -format "\n" TRUE | \
  awk -v pool=$(condor_config_val COLLECTOR_HOST) \
      'BEGIN { time = systime() }
         func put(name, value, schedd) { print "put " name, time, value, "pool=" pool, "schedd=" schedd }
         { put("condor.schedd.jobs.idle", $2, $1);
           put("condor.schedd.jobs.running", $3, $1);
           put("condor.schedd.jobs.held", $4, $1);
           put("condor.schedd.jobs.mean_runtime", $5, $1);
           put("condor.schedd.jobs.mean_waittime", $6, $1);
           put("condor.schedd.jobs.historical.mean_runtime", $7, $1);
           put("condor.schedd.jobs.historical.mean_waittime", $8, $1);
           put("condor.schedd.jobs.submission_rate", $9, $1);
           put("condor.schedd.jobs.start_rate", $10, $1);
           put("condor.schedd.jobs.completion_rate", $11, $1)}'
