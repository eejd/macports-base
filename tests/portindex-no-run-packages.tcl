#!/usr/bin/env tclsh

# Run portindex with every in-tree runtime package poisoned. This checks a full
# ports tree without executing targets: Portfile parsing must need only the
# parse-time target packages.

if {$argc != 2} {
    puts stderr "usage: $argv0 PORTINDEX PORTS_TREE"
    exit 2
}

set portindex [file normalize [lindex $argv 0]]
set ports_tree [file normalize [lindex $argv 1]]
set top_srcdir [file dirname [file dirname [file normalize [info script]]]]

if {![file executable $portindex] || ![file isdirectory $ports_tree]} {
    puts stderr "PORTINDEX must be executable and PORTS_TREE must be a directory"
    exit 2
}

set temp_channel [file tempfile poison_file]
close $temp_channel
file delete $poison_file
set poison_dir [file normalize "${poison_file}-run-packages"]
file mkdir $poison_dir
try {
    set output_dir [file join $poison_dir index]
    file mkdir $output_dir
    set fd [open [file join $poison_dir pkgIndex.tcl] w]
    foreach run_file [glob -tails -directory [file join $top_srcdir src port1.0] *_run.tcl] {
        set runpkg [file rootname $run_file]
        puts $fd [list package ifneeded $runpkg 1.0 [list error "Runtime package $runpkg loaded while indexing"]]
    }
    close $fd

    set had_tcllibpath [info exists ::env(TCLLIBPATH)]
    if {$had_tcllibpath} {
        set saved_tcllibpath $::env(TCLLIBPATH)
    }
    set ::env(TCLLIBPATH) [list $poison_dir]
    try {
        exec -ignorestderr $portindex -e -f -o $output_dir $ports_tree 2>@1
        if {![file exists [file join $output_dir PortIndex]]} {
            error "portindex did not create the isolated PortIndex"
        }
    } finally {
        if {$had_tcllibpath} {
            set ::env(TCLLIBPATH) $saved_tcllibpath
        } else {
            unset ::env(TCLLIBPATH)
        }
    }
} finally {
    file delete -force $poison_dir
}
