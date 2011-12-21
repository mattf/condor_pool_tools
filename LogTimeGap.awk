#!/bin/awk -f

function parse_time(string) {
   return mktime(gensub(/([^/]*)\/([^ ]*)\/([^ ]*) ([^:]*):([^:]*):([^ ]*) .*/,
                        "1984 \\1 \\2 \\4 \\5 \\6", "g"))
}

BEGIN {
   previous_time = 0; previous_line = ""; current_time = 0
   ARGC = 1
   MAX_GAP = ARGV[1]
   if (MAX_GAP == "") MAX_GAP = 30
   print "Maximum allowable gap:", MAX_GAP, "seconds"
}

{
   current_time = parse_time($0)
   gap = current_time - previous_time
   if (previous_time > 0 && gap > MAX_GAP) {
	   print "Found gap of " gap " seconds:\n", previous_line "\n", $0
   }
   previous_line = $0
   previous_time = current_time
}

END { }

