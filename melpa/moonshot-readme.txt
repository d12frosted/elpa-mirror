This package locates a project build directory for the current
buffer, and makes it easier to run common debug and execution
commands from that directory.

<< Determining the Project Build Directory >>

1) If file local variable `moonshot-project-build-dir' is set:
  a) if it starts with "/", use it as-is
  b) if it does not start with "/":
     - Append it to project root directory or the directory of current buffer.
     - If the directory of current buffer is not available, it's nil.
  c) if it is a sexp, run `eval' on it and return the value
  d) Implemented in `moonshot-project-build-dir-by-value' function.
2) Otherwise, check projectile
3) Otherwise, use the directory of current buffer

<< Launching an Executable >>

 This is accomplished using `moonshot-run-executable':
 1) It will search executable files under `moonshot-project-build-dir'.
 2) It will suggest executable files based on the buffer filename.

<< Launching a Debugger with Executable >>

 This is accomplished using `moonshot-run-debugger':
 - Similar to `moonshot-run-executable', choose an executable to debug.
 - The supported debuggers are listed in `moonshot-debuggers'.

<< Running a Shell Command in Compilation-Mode >>

 This is accomplished using `moonshot-run-runner':
 - Global shell command presets are `moonshot-runners-preset'.
 - Per project commands can be added to `moonshot-runners', by specifying variable in `.dir-locals.el' etc.

 <<< Command String Expansion >>>
   - The following format specifiers are will expanded in command string:
     %a  absolute pathname            ( /usr/local/bin/netscape.bin )
     %f  file name without directory  ( netscape.bin )
     %n  file name without extension  ( netscape )
     %e  extension of file name       ( bin )
     %d  directory                    ( /usr/local/bin/ )
     %p  project root directory       ( /home/who/blah/ ), using Projectile
     %b  project build directory      ( /home/who/blah/build/ ), using `moonshot-project-build-dir'"
