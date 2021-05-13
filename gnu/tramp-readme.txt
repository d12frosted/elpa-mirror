Tramp stands for `Transparent Remote (file) Access, Multiple
Protocol'.  This package provides remote file editing, similar to
Ange-FTP.

The difference is that Ange-FTP uses FTP to transfer files between the
local and the remote host, whereas Tramp uses a combination of `rsh'
and `rcp' or other work-alike programs, such as `ssh'/`scp'.

A remote file name has always the syntax

  /method:user%domain@host#port:/path/to/file

Most of the parts are optional, read the manual for details.

Tramp must be compiled for the Emacs version you are running.  If you
experience compatibility error messages for the Tramp package, or if
you use another major Emacs version than the version Tramp has been
installed with, you must recompile the package.  Run the command

  M-x tramp-recompile-elpa

Afterwards, you must restart Emacs.
