Major mode for editing Python files with some fontification and
indentation bits extracted from original Dave Love's python.el
found in GNU/Emacs.

Implements Syntax highlighting, Indentation, Movement, Shell
interaction, Shell completion, Shell virtualenv support, Shell
package support, Shell syntax highlighting, Pdb tracking, Symbol
completion, Skeletons, FFAP, Code Check, Eldoc, Imenu.

Syntax highlighting: Fontification of code is provided and supports
python's triple quoted strings properly.

Indentation: Automatic indentation with indentation cycling is
provided, it allows you to navigate different available levels of
indentation by hitting <tab> several times.  Also electric-indent-mode
is supported such that when inserting a colon the current line is
dedented automatically if needed.

Movement: `beginning-of-defun' and `end-of-defun' functions are
properly implemented.  There are also specialized
`forward-sentence' and `backward-sentence' replacements called
`python-nav-forward-block', `python-nav-backward-block'
respectively which navigate between beginning of blocks of code.
Extra functions `python-nav-forward-statement',
`python-nav-backward-statement',
`python-nav-beginning-of-statement', `python-nav-end-of-statement',
`python-nav-beginning-of-block', `python-nav-end-of-block' and
`python-nav-if-name-main' are included but no bound to any key.  At
last but not least the specialized `python-nav-forward-sexp' allows
easy navigation between code blocks.  If you prefer `cc-mode'-like
`forward-sexp' movement, setting `forward-sexp-function' to nil is
enough, You can do that using the `python-mode-hook':

(add-hook 'python-mode-hook
          (lambda () (setq forward-sexp-function nil)))

Shell interaction: is provided and allows opening Python shells
inside Emacs and executing any block of code of your current buffer
in that inferior Python process.

Besides that only the standard CPython (2.x and 3.x) shell and
IPython are officially supported out of the box, the interaction
should support any other readline based Python shells as well
(e.g. Jython and PyPy have been reported to work).  You can change
your default interpreter and commandline arguments by setting the
`python-shell-interpreter' and `python-shell-interpreter-args'
variables.  This example enables IPython globally:

(setq python-shell-interpreter "ipython"
      python-shell-interpreter-args "-i")

Using the "console" subcommand to start IPython in server-client
mode is known to fail intermittently due a bug on IPython itself
(see URL `https://debbugs.gnu.org/cgi/bugreport.cgi?bug=18052#27').
There seems to be a race condition in the IPython server (A.K.A
kernel) when code is sent while it is still initializing, sometimes
causing the shell to get stalled.  With that said, if an IPython
kernel is already running, "console --existing" seems to work fine.

Running IPython on Windows needs more tweaking.  The way you should
set `python-shell-interpreter' and `python-shell-interpreter-args'
is as follows (of course you need to modify the paths according to
your system):

(setq python-shell-interpreter "C:/Python27/python.exe"
      python-shell-interpreter-args
      "-i C:/Python27/Scripts/ipython-script.py")

Missing or delayed output used to happen due to differences between
Operating Systems' pipe buffering (e.g. CPython 3.3.4 in Windows 7.
See URL `https://debbugs.gnu.org/cgi/bugreport.cgi?bug=17304').  To
avoid this, the `python-shell-unbuffered' defaults to non-nil and
controls whether `python-shell-calculate-process-environment'
should set the "PYTHONUNBUFFERED" environment variable on startup:
See URL `https://docs.python.org/3/using/cmdline.html#cmdoption-u'.

The interaction relies upon having prompts for input (e.g. ">>> "
and "... " in standard Python shell) and output (e.g. "Out[1]: " in
IPython) detected properly.  Failing that Emacs may hang but, in
the case that happens, you can recover with \\[keyboard-quit].  To
avoid this issue, a two-step prompt autodetection mechanism is
provided: the first step is manual and consists of a collection of
regular expressions matching common prompts for Python shells
stored in `python-shell-prompt-input-regexps' and
`python-shell-prompt-output-regexps', and dir-local friendly vars
`python-shell-prompt-regexp', `python-shell-prompt-block-regexp',
`python-shell-prompt-output-regexp' which are appended to the
former automatically when a shell spawns; the second step is
automatic and depends on the `python-shell-prompt-detect' helper
function.  See its docstring for details on global variables that
modify its behavior.

Shell completion: hitting tab will try to complete the current
word.  The two built-in mechanisms depend on Python's readline
module: the "native" completion is tried first and is activated
when `python-shell-completion-native-enable' is non-nil, the
current `python-shell-interpreter' is not a member of the
`python-shell-completion-native-disabled-interpreters' variable and
`python-shell-completion-native-setup' succeeds; the "fallback" or
"legacy" mechanism works by executing Python code in the background
and enables auto-completion for shells that do not support
receiving escape sequences (with some limitations, i.e. completion
in blocks does not work).  The code executed for the "fallback"
completion can be found in `python-shell-completion-setup-code' and
`python-shell-completion-string-code' variables.  Their default
values enable completion for both CPython and IPython, and probably
any readline based shell (it's known to work with PyPy).  If your
Python installation lacks readline (like CPython for Windows),
installing pyreadline (URL `http://ipython.org/pyreadline.html')
should suffice.  To troubleshoot why you are not getting any
completions, you can try the following in your Python shell:

>>> import readline, rlcompleter

If you see an error, then you need to either install pyreadline or
setup custom code that avoids that dependency.

Shell virtualenv support: The shell also contains support for
virtualenvs and other special environment modifications thanks to
`python-shell-process-environment' and `python-shell-exec-path'.
These two variables allows you to modify execution paths and
environment variables to make easy for you to setup virtualenv rules
or behavior modifications when running shells.  Here is an example
of how to make shell processes to be run using the /path/to/env/
virtualenv:

(setq python-shell-process-environment
      (list
       (format "PATH=%s" (mapconcat
                          'identity
                          (reverse
                           (cons (getenv "PATH")
                                 '("/path/to/env/bin/")))
                          ":"))
       "VIRTUAL_ENV=/path/to/env/"))
(python-shell-exec-path . ("/path/to/env/bin/"))

Since the above is cumbersome and can be programmatically
calculated, the variable `python-shell-virtualenv-root' is
provided.  When this variable is set with the path of the
virtualenv to use, `process-environment' and `exec-path' get proper
values in order to run shells inside the specified virtualenv.  So
the following will achieve the same as the previous example:

(setq python-shell-virtualenv-root "/path/to/env/")

Also the `python-shell-extra-pythonpaths' variable have been
introduced as simple way of adding paths to the PYTHONPATH without
affecting existing values.

Shell package support: you can enable a package in the current
shell so that relative imports work properly using the
`python-shell-package-enable' command.

Shell remote support: remote Python shells are started with the
correct environment for files opened remotely through tramp, also
respecting dir-local variables provided `enable-remote-dir-locals'
is non-nil.  The logic for this is transparently handled by the
`python-shell-with-environment' macro.

Shell syntax highlighting: when enabled current input in shell is
highlighted.  The variable `python-shell-font-lock-enable' controls
activation of this feature globally when shells are started.
Activation/deactivation can be also controlled on the fly via the
`python-shell-font-lock-toggle' command.

Pdb tracking: when you execute a block of code that contains some
call to pdb (or ipdb) it will prompt the block of code and will
follow the execution of pdb marking the current line with an arrow.

Symbol completion: you can complete the symbol at point.  It uses
the shell completion in background so you should run
`python-shell-send-buffer' from time to time to get better results.

Skeletons: skeletons are provided for simple inserting of things like class,
def, for, import, if, try, and while.  These skeletons are
integrated with abbrev.  If you have `abbrev-mode' activated and
`python-skeleton-autoinsert' is set to t, then whenever you type
the name of any of those defined and hit SPC, they will be
automatically expanded.  As an alternative you can use the defined
skeleton commands: `python-skeleton-<foo>'.

FFAP: You can find the filename for a given module when using ffap
out of the box.  This feature needs an inferior python shell
running.

Code check: Check the current file for errors with `python-check'
using the program defined in `python-check-command'.

Eldoc: returns documentation for object at point by using the
inferior python subprocess to inspect its documentation.  As you
might guessed you should run `python-shell-send-buffer' from time
to time to get better results too.

Imenu: There are two index building functions to be used as
`imenu-create-index-function': `python-imenu-create-index' (the
default one, builds the alist in form of a tree) and
`python-imenu-create-flat-index'.  See also
`python-imenu-format-item-label-function',
`python-imenu-format-parent-item-label-function',
`python-imenu-format-parent-item-jump-label-function' variables for
changing the way labels are formatted in the tree version.

If you used python-mode.el you may miss auto-indentation when
inserting newlines.  To achieve the same behavior you have two
options:

1) Enable the minor-mode `electric-indent-mode' (enabled by
   default) and use RET.  If this mode is disabled use
   `newline-and-indent', bound to C-j.

2) Add the following hook in your .emacs:

(add-hook 'python-mode-hook
  #'(lambda ()
      (define-key python-mode-map "\C-m" 'newline-and-indent)))

I'd recommend the first one since you'll get the same behavior for
all modes out-of-the-box.