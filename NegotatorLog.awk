#!/bin/awk -f

function parse_time(string) {
   return mktime(gensub(/([^/]*)\/([^ ]*) ([^:]*):([^:]*):([^ ]*) .*/,
                        "1984 \\1 \\2 \\3 \\4 \\5", "g"))
}

BEGIN { started = 0; finished = 0 }

/Started Negotiation Cycle/ {
   started = parse_time($0)
#   if (finished) print "Delay:", started - finished
   finished = 0
   matched = 0
}

/Matched/ {
   matched += 1
}

/Finished Negotiation Cycle/ {
   finished = parse_time($0)
   if (!started) next #{ print "Skipping first cycle"; next }
#   if (!matched) next #{ print "Skipping cycle with no matches"; next }
   duration = finished - started
   if (!duration) next # { print "Skipping zero second cycle"; next }
   print strftime("%m/%d %T", started), "::", matched, "matches in", duration, "seconds", "(" matched / duration, "matches/second)"
}

END {
   #if (!finished) print "Skipping last cycle"
}

