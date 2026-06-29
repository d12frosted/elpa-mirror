If you have cpupower installed, this provides a very simple wrapper
to that program.  You'll need to configure your system such that
the current user can run cpupower (maybe as `sudo cpupower` from a
command line).  You can configure how cpupower is called by
customizing cpupower-cmd.

The commands you'll probably want to use:
* cpupower-info
  - displays (briefly) the current cpupower information
* cpupower-set-governor
  - sets cpu governor for all cores.
* cpupower-helm-set-governor
  - sets cpu governor for all cores (uses helm)

Less useful commands:
* cpupower-get-current-frequencies
  - returns a list of all cpu frequencies in KHz by core.
* cpupower-get-current-governors
  - returns a list of all cpu governors by core.