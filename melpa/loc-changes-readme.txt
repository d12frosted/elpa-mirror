This package lets users or programs set marks in a buffer prior to
changes so that we can track the original positions after the
change.

One common use is say when debugging a program.  The debugger has its static
notion of the file and positions inside that.  However it may be convenient
for a programmer to edit the program but not restart execution of the program.

Another use might be in a compilation buffer for errors and
warnings which refer to file and line positions.
