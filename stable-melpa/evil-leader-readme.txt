
Known Bugs:
See http://github.com/cofi/evil-leader/issues

Install:
(require 'evil-leader)

Usage:

(global-evil-leader-mode)

   to enable `evil-leader' in every buffer where `evil' is enabled.

   Note: You should enable `global-evil-leader-mode' before you enable
         `evil-mode', otherwise `evil-leader' won't be enabled in initial
         buffers (*scratch*, *Messages*, ...).

   Use `evil-leader/set-key' to bind keys in the leader map.
   For example:

(evil-leader/set-key "e" 'find-file)

   You can also bind several keys at once:

(evil-leader/set-key
  "e" 'find-file
  "b" 'switch-to-buffer
  "k" 'kill-buffer)

   The key map can of course be filled in several places.

   After you set up the key map you can access the bindings by pressing =<leader>=
   (default: \) and the key(s). E.g. \ e would call `find-file' to open a file.

   If you wish to change so you can customize =evil-leader/leader= or call
   `evil-leader/set-leader', e.g. (evil-leader/set-leader ",") to change it to
   ",".
   The leader has to be readable by `read-kbd-macro', so using Space as a
   prefix key would be (evil-leader/set-leader "<SPC>").

   Beginning with version 0.3 evil-leader has support for mode-local bindings:

(evil-leader/set-key-for-mode 'emacs-lisp-mode "b" 'byte-compile-file)

   Again, you can bind several keys at once.

   A mode-local binding shadows a normal mode-independent binding.
