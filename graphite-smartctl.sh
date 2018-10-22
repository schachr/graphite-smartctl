#!/bin/bash

# please use your graphite preferences here
_graphiteprefix="schachr"
_graphitehost="graphitehost.example.com"
_graphiteport="2003"

# generated variables
_device=${1:-$(for device in /dev/sd? ; do basename /dev/$device ; done)}
_hostname=$(hostname -s | tr '[:upper:]' '[:lower:]')
_date=$(date +%s)
_cygwinfix=$(if ! uname -a | egrep -q "(Cygwin| mips )" ; then echo -n "-q0" ; fi)
smartctlcmd=$(which smartctl 2>/dev/null)
declare -a _output

# sanity check device
if [[ -z ${_device} ]] ; then
    echo "No device set or found."
    exit 1
fi

# sanity check smartctl
if   [[ -z $smartctlcmd && -f /usr/sbin/smartctl ]] ; then
    smartctlcmd="/usr/sbin/smartctl"
elif [[ -z $smartctlcmd ]] ; then
    echo "smartctl not found."
    exit 1
fi

# do not power on sleeping disks
smartctlcmd="${smartctlcmd} --nocheck standby"

# sanity check smartctl output and get header
for device in $_device ; do
    header=$($smartctlcmd -a /dev/$device | awk "/^ID#/ {printline = 1; print; next} /^$/ {printline = 0} printline" | head -n1)
    [[ ! -z $header ]] && break
done
# try to detect usb bridges
if [[ -z $header ]] ; then
    smartctlcmd="${smartctlcmd} -d sat"
    for device in $_device ; do
        header=$($smartctlcmd -a /dev/$device | awk "/^ID#/ {printline = 1; print; next} /^$/ {printline = 0} printline" | head -n1)
        [[ ! -z $header ]] && break
    done
fi

# sanity check header
if [[ -z $header ]] ; then
    echo "A header in smartctl for device values could not be found."
    exit 1
fi

# process output of smartctl
for device in $_device ; do
    _serial=$($smartctlcmd -i $device | egrep -i "^Serial Number" | sed 's/^Serial Number: *//I')
    _graphiteserial=${_serial:-${device}}

    while IFS= read -r line ; do
        prefix=$(echo $line | awk '{print $1"."$2}')

        # dynamic fields - slower
        #for i in $( seq 2 $(awk '{print NF}' <<< $line) ) ; do
        # static fields - faster
        for i in 4 5 6 10 ; do 
            value=$(echo $line | cut -f$i -d" ")

            if [[ $value =~ ^-?[0-9]+([.][0-9]+)?$ ]] ; then
                _output+=("$_graphiteprefix.$_hostname.disk.$_graphiteserial.smart.$prefix.$(echo $header | cut -f$i -d" ") $value "$_date)
                [ -t 1 ] && echo ${_output[-1]}
            fi

        done
    done < <($smartctlcmd -a /dev/$device | awk "/^ID#/ {printline = 1; print; next} /^$/ {printline = 0} printline" | tail -n+2)
done

# send to graphite
[[ ! $(echo ${#_output[@]}) -eq 0 ]] && printf '%s\n' "${_output[@]}" | nc $_cygwinfix $_graphitehost $_graphiteport > /dev/null 2>&1
