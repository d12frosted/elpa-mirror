Installing Tramp via GNU ELPA
*****************************

Tramp stands for "Transparent Remote (file) Access, Multiple Protocol".
This package provides remote file editing, similar to Ange-FTP.

The difference is that Ange-FTP uses FTP to transfer files between the
local and the remote host, whereas Tramp uses a combination of ‘rsh’ and
‘rcp’ or other work-alike programs, such as ‘ssh’/‘scp’.

A remote file name has always the syntax

     /method:user%domain@host#port:/path/to/file

Most of the parts are optional, read the manual
<https://www.gnu.org/software/tramp/> for details.

Tramp must be compiled for the Emacs version you are running.  If you
experience compatibility error messages for the Tramp package, or if you
use another major Emacs version than the version Tramp has been
installed with, you must recompile the package:

Emacs 29 or newer
-----------------

   • Recompile the Tramp package

          M-x package-recompile RET tramp

Emacs 28 or older
-----------------

   • Remove all byte-compiled Tramp files

          $ rm -f ~/.emacs.d/elpa/tramp-2.7.1.1/tramp*.elc

   • Start Emacs with Tramp's source files

          $ emacs -L ~/.emacs.d/elpa/tramp-2.7.1.1 -l tramp

     This should not give you the error.

   • Recompile the Tramp package *with this running Emacs instance*

          M-x tramp-recompile-elpa

     Afterwards, you must restart Emacs.

Mitigation of a bug in Emacs 29.1
---------------------------------

Due to a bug in Emacs 29.1, you must apply the following change prior
installation or upgrading Tramp 2.7.1.1 from GNU ELPA:

     (when (string-equal emacs-version "29.1")
       (with-current-buffer
           (url-retrieve-synchronously
            "https://git.savannah.gnu.org/cgit/emacs.git/plain/lisp/emacs-lisp/loaddefs-gen.el?h=emacs-29")
         (goto-char (point-min))
         (while (looking-at "^.+$") (forward-line))
         (eval-region (point) (point-max))))
