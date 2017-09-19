# graphite-smartctl
It's a simple script which parses the output of all deteced hard disks via `smartctl` and feed it into graphite.
Only one connection is made to send all the catched metrics to graphite.

Tested on:
+ debian 9.0
+ armbian
+ enigma2 (VTi)
+ cygwin

## Configuration

Please adjust the variables
+ `_graphiteprefix`
+ `_graphitehost`
+ `_graphiteport`

... at the beginning of the file to match your environment.

## Single Disk Mode

Optionally you can provide a single disk via argument to gather statistics from:
`./graphite-smartctl.sh sda`


##

Copyright (c)2017 by [schachr](https://github.com/schachr)

This script comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to redistribute it
under certain conditions. See CC BY-NC-SA 4.0 for details.
https://creativecommons.org/licenses/by-nc-sa/4.0/
