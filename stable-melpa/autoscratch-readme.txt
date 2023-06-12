;; Introduction:
This simple  major mode can be  used as the initial  major mode for
the scratch buffer.  It automatically switches to another major mode
based on regexes triggered by text input.

In   the   default  configuration   it   responds   to  the   first
non-whitespace  character  entered  into  the  scratch  buffer  and
switches   major   mode   based   on  this.    See   the   variable
`autoscratch-triggers-alist' for the defaults.  For example, if you
enter a paren, it will switch to `emacs-lisp-mode'.

;; Configuration:

The minimum configuration looks like this:

    (require 'autoscratch)
    (setq initial-major-mode 'autoscratch-mode)
    (setq initial-scratch-message "")
    (setq inhibit-startup-screen t)

You     may,     however,     configure    the     trigger     list
`autoscratch-triggers-alist' according  to your  preferences.  This
list consists  of cons cells, where  the `car' is a  regexp and the
`cdr' an Emacs Lisp form (e.g. a  lambda or defun).  If you want to
use regexps which  match more than one character, then  you need to
set `autoscratch-trigger-on-first-char' to  `nil' and possibly tune
`autoscratch-trigger-after' accordingly.

If   no  regexp   matches  and/or   `autoscratch-trigger-after'  is
exceeded,  then  the  `autoscratch-default-trigger'  form  will  be
executed, which  by default is  `fundamental-mode', but you  can of
course change this.

Autoscratch can  also be  configured to  rename the  current buffer
after  it  switched mode  based  on  a  trigger  and create  a  new
`autoscratch-buffer'  in the  background.  In  order to  enable this
feature, set `autoscratch-fork-after-trigger' to t.

To   further    tune   the   trigger   bahavior    you   can   tune
`autoscratch-trigger-hook' which will be called after executing the
form of the matching trigger.
