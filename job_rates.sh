#!/bin/sh

# condor_history -format "%d " EnteredCurrentStatus \
#                -format "%d " CompletionDate \
#                -format "%d\n" JobFinishedHookDone
#
# EnteredCurrentStatus CompletionDate JobFinishedHookDone
# ...
DATA_FILE=$1

echo "jobs / second : occurances (EnteredCurrentStatus)"
awk '{print $1}' < $DATA_FILE | sort | uniq -c | awk '{print $1}' | sort -n | uniq -c | awk '{print $2 " : " $1}'

echo "jobs / second : occurances (CompletionDate)"
awk '{if ($2 > 0) print $2}' < $DATA_FILE | sort | uniq -c | awk '{print $1}' | sort -n | uniq -c | awk '{print $2 " : " $1}'

echo "jobs / second : occurances (JobFinishedHookDone)"
awk '{print $3}' < $DATA_FILE | sort | uniq -c | awk '{print $1}' | sort -n | uniq -c | awk '{print $2 " : " $1}'

echo "CompletionDate - EnteredCurrentStatus: occurances"
awk '{if ($2 > 0) print $2 - $1}' < $DATA_FILE | sort | uniq -c | awk '{print $2 " : " $1}' | sort -n

echo "CompletionDate - JobFinishedHookDone: occurances"
awk '{print $3 - $1}' < $DATA_FILE | sort | uniq -c | awk '{print $2 " : " $1}' | sort -n

echo "JobFinishedHookDone - CompletionDate: occurances"
awk '{if ($2 > 0) print $3 - $2}' < $DATA_FILE | sort | uniq -c | awk '{print $2 " : " $1}' | sort -n

