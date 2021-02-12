Requirement:
   org-mode 6.33x or higher version
   The latest version of the org-mode is recommended.
                     (see https://orgmode.org/)

Usage:
   1. Put this elisp into your load-path
   2. Add (require 'org-tree-slide) in your .emacs
   3. Open an org-mode file
   4. Toggle org-tree-slide-mode (M-x org-tree-slide-mode)
      then Slideshow will start and you can find "TSlide" in mode line.
   5. `C-<'/`C->' will move between slides
   6. `C-x s c' will show CONTENT of the org buffer
      Select a heading and type `C-<', then Slideshow will start again.
   7. Toggle org-tree-slide-mode again to exit this minor mode

Recommended minimum settings:
   (global-set-key (kbd "<f8>") 'org-tree-slide-mode)
   (global-set-key (kbd "S-<f8>") 'org-tree-slide-skip-done-toggle)

 and three useful profiles are available.

   1. Simple use
      M-x org-tree-slide-simple-profile

   2. Presentation use
      M-x org-tree-slide-presentation-profile

   3. TODO Pursuit with narrowing
      M-x org-tree-slide-narrowing-control-profile

   Type `C-h f org-tree-slide-mode', you can find more detail.

Note:
   - Make sure key maps below when you introduce this elisp.
   - Customize variables, M-x customize-group ENT org-tree-slide ENT
   - see also moom.el (https://github.com/takaxp/moom) to control Emacs frame
