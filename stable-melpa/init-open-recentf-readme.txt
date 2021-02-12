
Open recentf immediately after Emacs is started.
Here are some example scenarios for when Emacs is started from the command line:
  - If files are opened (e.g. '$ emacs file1.txt'), nothing out of the ordinary occurs-- the file is opened.
  - However if a file is not indicated (e.g. '$ emacs '), recentf will be opened after emacs is initialized.
This script uses only the inbuilt advice function for startup.  It does not require or use any interactive function.
(This approach is a dirty hack, but an alternative hook to accomplish the same thing does not exist.)

Put the following into your .emacs file (~/.emacs.d/init.el)

  (init-open-recentf)

`init-open-recentf' supports the following frameworks: helm, ido, anything (and the default Emacs setup without those frameworks).
 The package determines the frameworks from your environment, but you can also indicate it explicitly.

  (setq init-open-recentf-interface 'ido)
  (init-open-recentf)

Another possible configuration is demonstrated below if you want to specify an arbitrary function.

  (setq init-open-recentf-function #'awesome-open-recentf)
  (init-open-recentf)
