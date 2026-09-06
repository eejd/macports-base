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

    set path_var MACPORTS_TEST_TCLLIBPATH_PREFIX
    set had_path_prefix [info exists env($path_var)]
    if {$had_path_prefix} {
        set saved_path_prefix $env($path_var)
    }
    set env($path_var) [list $poison_dir]
    try {
        port_index -e
    } finally {
        if {$had_path_prefix} {
            set env($path_var) $saved_path_prefix
        } else {
            unset env($path_var)
        }
    }

    expr {[file exists [file join $test_root ports PortIndex]]
          && [file exists [file join $test_root ports PortIndex.quick]]}
} -result 1

cleanupTests
