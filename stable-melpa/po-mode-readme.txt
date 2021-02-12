This package provides the tools meant to help editing PO files,
as documented in the GNU gettext user's manual.  See this manual
for user documentation, which is not repeated here.

To install, merely put this file somewhere GNU Emacs will find it,
then add the following lines to your .emacs file:

  (autoload 'po-mode "po-mode"
            "Major mode for translators to edit PO files" t)
  (setq auto-mode-alist (cons '("\\.po\\'\\|\\.po\\." . po-mode)
                              auto-mode-alist))

To use the right coding system automatically under Emacs 20 or newer,
also add:

  (autoload 'po-find-file-coding-system "po-compat")
  (modify-coding-system-alist 'file "\\.po\\'\\|\\.po\\."
                              'po-find-file-coding-system)

You may also adjust some variables, below, by defining them in your
'.emacs' file, either directly or through command 'M-x customize'.

TODO:
Plural form editing:
 - When in edit mode, currently it highlights (in green) the msgid;
   it should also highlight the msgid_plural string, I would say, since
   the translator has to look at both.
 - After the translator finished the translation of msgstr[0], it would
   be nice if the cursor would automatically move to the beginning of the
   msgstr[1] line, so that the translator just needs to press RET to edit
   that.
 - If msgstr[1] is empty but msgstr[0] is not, it would be ergonomic if the
   contents of msgstr[0] would be copied. (Not sure if this should happen
   at the end of the editing msgstr[0] or at the beginning of the editing
   of msgstr[1].) Reason: These two strings are usually very similar.
