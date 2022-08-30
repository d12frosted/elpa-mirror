This file should not be confused with Rick Bielawski's cobol-mode.el
(http://www.emacswiki.org/emacs/cobol-mode.el), which this mode attempts to
supersede.

This COBOL mode features syntax highlighting for most modern COBOL dialects,
indentation, code skeletons, rulers and basic formatting functions.
Highlighting changes with the code format, which can be specified using the
M-x customize menu.

Installation:

To install cobol-mode.el, save it to your .emacs.d/ directory and add the
following to your .emacs:
(autoload 'cobol-mode "cobol-mode" "Major mode for highlighting COBOL files." t nil)

To automatically load cobol-mode.el upon opening COBOL files, add this:
(setq auto-mode-alist
      (append
       '(("\\.cob\\'" . cobol-mode)
         ("\\.cbl\\'" . cobol-mode)
         ("\\.cpy\\'" . cobol-mode))
       auto-mode-alist))

Finally, I strongly suggest installing auto-complete-mode, which makes typing
long keywords and variable names a thing of the past.  See
https://github.com/auto-complete/auto-complete.

Known bugs:

* Switching source formats requires M-x customize settings to be changed,
  saved and cobol-mode to be unloaded then reloaded.
* Copying-and-pasting content in fixed-format sometimes results in content
  being pasted in column 1 and spaces inserted in the middle of it.
* The indentation code leaves a lot of trailing whitespace.
* Periods on their own line are sometimes indented strangely.
* String continuation does not work.

Missing features:

* Switch between dialect's reserved word lists via M-x customize (without
  unloading cobol-mode).
* Allow users to modify easily reserved word lists.
* Expand copybooks within a buffer.
* String continuation (see above).
* Allow users to modify start of program-name area.