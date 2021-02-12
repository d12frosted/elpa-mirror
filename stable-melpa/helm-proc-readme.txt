
This package provides a helm source `helm-source-proc' and a
configured helm `helm-proc'.  It is meant to be used to manage
emacs-external unix processes.

With `helm-proc' a helm session is launched and you can perform
various helm actions on processes like sending signals, changing to
the corresponding /proc dir, attach strace...

Example:

Call `helm-proc' and:
type 'firefox'
=> lists all processes named firefox or with firefox in args
press RET to send TERM signal
 or
press TAB for list of possible actions
