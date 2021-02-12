Sadly, Emacs (unlike Spacemacs, which has `spacemacs/find-dotfile') doesn't have
a function to open its own init file, so thousands of users have to write their owns.
I'm not different :)

`iqa-find-user-init-file' is a shorthand to open user init file.
By default `user-init-file' is used.  If your configuration is generated
from org-mode source you may want to point it to your org file.

(setq iqa-user-init-file (concat user-emacs-directory "init.org"))

File is opened by `find-file', but you can redefine it by e.g.

(setq iqa-find-file-function #'find-file-other-window)

`iqa-reload-user-init-file' reloads `user-init-file' (not `iqa-user-init-file')
For a full restart take a look at `restart-emacs' package.

`iqa-find-user-custom-file' opens custom-file

`iqa-find-user-init-directory' opens init file directory

`iqa-setup-default' defines keybindings:
"C-x M-f" — `iqa-find-user-init-file'
"C-x M-c" — `iqa-find-user-custom-file'
"C-x M-r" — `iqa-reload-user-init-file'
"C-x M-d" — `iqa-find-user-init-directory'


Installation:

(use-package iqa
  ;; use this if your config is generated from an org file
  ;; :custom
  ;; (iqa-user-init-file (concat user-emacs-directory "README.org") "Edit README.org by default.")
  :config
  (iqa-setup-default))
