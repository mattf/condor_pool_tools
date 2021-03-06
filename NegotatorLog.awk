#!/usr/bin/awk -f

function parse_time(string) {
   return mktime(gensub(/([^/]*)\/([^ ]*)\/([^ ]*) ([^:]*):([^:]*):([^ ]*) .*/,
                        "1984 \\1 \\2 \\4 \\5 \\6", "g"))
}

BEGIN { started = 0; finished = 0 }

/Started Negotiation Cycle/ {
   started = parse_time($0)
#   if (finished) print "Delay:", started - finished
   finished = 0; matched = 0; rejected = 0; submitters = 0; slots = 0
}

/Matched/ {
   matched += 1
}

/Rejected/ {
   rejected += 1
}

/Public ads include .* submitter, .* startd/ {
   submitters = $6
   slots = $8
}

/Finished Negotiation Cycle/ {
   finished = parse_time($0)
   if (!started) next #{ print "Skipping first cycle"; next }
#   if (!matched) next #{ print "Skipping cycle with no matches"; next }
   duration = finished - started
   if (!duration) next # { print "Skipping zero second cycle"; next }
   print strftime("%m/%d %T", started), "::",
       matched, "matches in",
       duration, "seconds",
       "(" matched / duration "/s) with",
       rejected, "rejections,",
       submitters, "submitters,",
       slots, "slots"
}

END {
   #if (!finished) print "Skipping last cycle"
}
