stash.el provides lightweight, persistent caching of Lisp data.  It
enables the programmer to create variables which will be written to
disk after a certain amount of idle time, as to not cause
unnecessary blocks to execution.

The basic unit of stash.el is the app.  Apps define groups of
related variables.  At an interval defined by each application, its
variables are written to disk.  Where no app is given, the
`stash-default-application' is used, set to save every minute.

To get started, define an application using `defapp':

  (defapp my-app 120)

The above defines my-app to save its data every two minutes (and
when Emacs is killed, of course).

You can now define variables similarly as you would with `defvar',
but now you must provide a filename to save to (under
`stash-directory' and the applications's associated subdirectory):

  (defstash my-var "var.el" my-app 'spam
    "This docstring is marginally useful.")
