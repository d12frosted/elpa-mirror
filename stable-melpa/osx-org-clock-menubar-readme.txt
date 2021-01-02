
This tool will display your current org-clock task in the osx menubar
like org-clock displays it in the modeline

The server that displays items in the menubar requires MacRuby to be
installed.

You can run the server process external of emacs or as a subprocess

Simpley run M-x `org-clock-menubar-mode' to start things off, you will be
prompted to start the server if it is not running.

If you would not like to be prompted, set `ocm-start-server-no-prompt' to t.

Disabling `org-clock-menubar-mode' does not stop the server, if you  would
like to kill the subprocess use `ocm-stop-emacs-server-process'.
