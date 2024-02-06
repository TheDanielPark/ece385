#
# This file allows you to call any available BSP procedure.
# This is handy for having finer control over Tcl execution.
#

proc usage {} {
    error {Usage: proc-name [<proc-args>]}
}

# Get the path to this script.
# This uses the $argv0 pre-set variable which contains the
# complete path to this script.
set mydir [file dirname $argv0]

# Read in required utility scripts.
source $mydir/bsp-stdio-utils.tcl
source $mydir/bsp-timer-utils.tcl
source $mydir/bsp-linker-utils.tcl
source $mydir/bsp-bootloader-utils.tcl
source $mydir/bsp-exception-utils.tcl

# Make sure command line isn't empty.
if { $argc == 0 } {
    usage
}

# Extra procedure name from command line.
set proc_name [lindex $argv 0]

if { [ info procs $proc_name ] != $proc_name } {
    log_default "Unknown procedure name $proc_name"
    usage
}

# Call specified procedure
eval $argv
