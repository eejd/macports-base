package require tcltest 2
namespace import tcltest::*

set pwd [file dirname [file normalize $argv0]]

source ../library.tcl
load_variables $pwd
set_dir

test portindex-deferred-loading-1.0 {
    portindex must not load a target's runtime package while evaluating Portfiles.
} -body {
    global env test_root top_srcdir

    set poison_dir [file join $test_root poisoned-run-packages]
    file mkdir $poison_dir
    set fd [open [file join $poison_dir pkgIndex.tcl] w]
    foreach run_file [glob -tails -directory [file join $top_srcdir src port1.0] *_run.tcl] {
        set runpkg [file rootname $run_file]
        puts $fd [list package ifneeded $runpkg 1.0 [list error "Runtime package $runpkg loaded while indexing"]]
    }
    close $fd

    set had_tcllibpath [info exists env(TCLLIBPATH)]
    if {$had_tcllibpath} {
        set saved_tcllibpath $env(TCLLIBPATH)
    }
    set env(TCLLIBPATH) [list $poison_dir]
    try {
        port_index
    } finally {
        if {$had_tcllibpath} {
            set env(TCLLIBPATH) $saved_tcllibpath
        } else {
            unset env(TCLLIBPATH)
        }
    }

    expr {[file exists [file join $test_root ports PortIndex]]
          && [file exists [file join $test_root ports PortIndex.quick]]}
} -result 1

cleanupTests
