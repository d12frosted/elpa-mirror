Installing TRAMP via GNU ELPA
*****************************

Tramp stands for "Transparent Remote (file) Access, Multiple Protocol".
This package provides remote file editing, similar to Ange-FTP.

The difference is that Ange-FTP uses FTP to transfer files between the
local and the remote host, whereas Tramp uses a combination of 'rsh' and
'rcp' or other work-alike programs, such as 'ssh'/'scp'.

A remote file name has always the syntax

     /method:user%domain@host#port:/path/to/file

Most of the parts are optional, read the manual
<https://www.gnu.org/software/tramp/> for details.

Tramp must be compiled for the Emacs version you are running.  If you
experience compatibility error messages for the Tramp package, or if you
use another major Emacs version than the version Tramp has been
installed with, you must recompile the package:

   * Remove all byte-compiled Tramp files

          $ rm -f ~/.emacs.d/elpa/tramp-2.5.3.3/tramp*.elc

   * Start Emacs with Tramp's source files

          $ emacs -L ~/.emacs.d/elpa/tramp-2.5.3.3 -l tramp

     This should not give you the error.

   * Recompile the Tramp package *with this running Emacs instance*

          M-x tramp-recompile-elpa

     Afterwards, you must restart Emacs.
