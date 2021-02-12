Generalized automatic execution in a single frame

This is a library that package developers can use to provide user
friendly single window per frame execution of buffer exposing
commands, as well as to use in personal Emacs configurations to attain
the same goal for packages that don't use =fullframe= or the likes of
it themself.

 Example: Setup =magit-status= to open in one window in the current
 frame when called
Example:
- Open magit-status in a single window in fullscreen
  (require 'fullframe)
  (fullframe magit-status magit-mode-quit-window nil)
