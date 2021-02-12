This file allows you to split Emacs customizations (set via M-x
customize) into different files, based on the names of the
variables.  It uses a regexp to match against each face and
variable name, and associates with a file that the variable should
be stored in.

To use it, just load the file in your .emacs:

  (load "initsplit")

If you want configuration files byte-compiled, add this after it:

  (add-hook 'after-save-hook 'initsplit-byte-compile-files t)

Note that that you *must* load each file that contains your various
customizations from your .emacs.  Otherwise, the variables won't
all be set, and the next time you use the customize interface, it
will delete the settings in those other files.

Then, customize the variable `initsplit-customizations-alist', to
associate various configuration names with their respective
initialization files.

I find this module most useful for splitting up Gnus and Viper
customizations.
