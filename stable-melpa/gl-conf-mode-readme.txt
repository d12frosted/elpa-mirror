
Provides navigation utilities, syntax highlighting and indentation for
gitolite configuration files (gitolite.conf)

Add this code to your .emacs file to use the mode (and automatically
open gitolite.conf files in this mode)

(setq load-path (cons (expand-file-name "/directory/path/to/gitolite-conf-mode.el/") load-path))
(require 'gl-conf-mode)
(add-to-list 'auto-mode-alist '("gitolite\\.conf\\'" . gl-conf-mode))

If the file you want to edit is not named gitolite.conf, use
M-x gl-conf-mode, after opening the file

Automatic indentation for this mode is disabled by default.
If you want to enable it, go to Customization menu in Emacs,
then "Files", "Gitolite Config Files", and select the appropiate option.

The interesting things you can do are:
- move to next repository definition: C-c C-n
- move to previous repository definition: C-c C-p
- go to the include file on the line where the cursor is: C-c C-v
- open a navigation window with all the repositories (hyperlink enabled): C-c C-l
- mark the current repository and body: C-c C-m
- open a navigation window with all the defined groups (hyperlink enabled): C-c C-g
- offer context sentitive help linking to the original web documentation: C-c C-h

For the context sensitive help it can detect different positions, and will
offer help on that topic:

   - repo line
   - include line
   - permissions (R/RW/RWC/...)
   - refexes (branches, ...)
   - user or group permissions
   - groups
   - anything else (offer generic gitolite.conf help)

The help uses the main gitolite web documentation, linking directly into it
with a browser.
If the Emacs `w3m' module is available in the system, it will be used to open
the help inside Emacs, otherwise, the Emacs configured external browser will
be launched (Emacs variable `browse-url-browser-function')

Please note, that while it is not required by the license, I would
sincerely appreciate if you sent me enhancements / bugfixes you make
to integrate them in the master repo and make those changes accessible
to more people
