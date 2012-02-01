#!/bin/sh

condor_status -master \
   -constraint '((MyCurrentTime-LastHeardFrom) > 60) || ((MyCurrentTime-LastHeardFrom) < -60)' \
   -format "%s\t" Name \
   -format "%d\n" '(MyCurrentTime - LastHeardFrom)'
