                           ━━━━━━━━━━━━━━━━━
                            KEYMAP-POPUP.EL
                           ━━━━━━━━━━━━━━━━━


A macro that defines a keymap with embedded descriptions and a popup to
display them.

`One definition, two uses: direct key dispatch and interactive menu.'

Requires Emacs 29.1+.


1 Quick start
═════════════

  ┌────
  │ (keymap-popup-define my-commands-map
  │   "My commands."
  │   :group "Edit"
  │   "c" ("Comment" comment-dwim)
  │   "r" ("Rename" rename-file)
  │   :group "View"
  │   "g" ("Refresh" revert-buffer)
  │   "q" ("Quit" quit-window))
  │ 
  │ ;; Use as a normal keymap:
  │ (keymap-set some-mode-map "C-c m" my-commands-map)
  │ 
  │ ;; Or show the popup directly:
  │ (keymap-popup my-commands-map)
  └────

  Press `h' in the keymap to open the popup. Press `q' to dismiss.


2 Features
══════════

  • `:switch' – buffer-local toggle with `[on]/[off]' display
  • `:keymap' – sub-menu with stack navigation (`q' / `C-g' pops back)
  • `:stay-open' – command executes without dismissing the popup
  • `:inapt-if' – grays out and blocks entries based on a predicate
  • `:c-u' – prefix argument mode (`C-u' highlights eligible entries)
  • `:if' – conditionally hide entries
  • `:group' / `:row' – column layout
  • Dynamic descriptions via lambdas
  • `keymap-popup-annotate' – add popup descriptions to existing keymaps


3 Full example
══════════════

  Eval this block, then `M-x kp-test'.  It creates a buffer with state,
  a popup with switches, sub-menus, inapt entries, dynamic descriptions,
  and prefix argument support.

  ┌────
  │ (require 'keymap-popup)
  │ 
  │ ;; Force fresh keymaps on re-eval (defvar won't re-set bound variables)
  │ (mapc #'makunbound
  │       (cl-remove-if-not #'boundp '(kp-test--map kp-test--sub-map)))
  │ 
  │ ;;; Buffer rendering
  │ 
  │ (defvar-local kp-test--name nil)
  │ 
  │ 
  │ (defun kp-test--render ()
  │   "Redraw the *kp-test* buffer from buffer-local state."
  │   (let ((inhibit-read-only t))
  │     (erase-buffer)
  │     (insert (propertize "keymap-popup live test\n" 'face 'bold)
  │             (make-string 40 ?-) "\n\n"
  │             (format "  Name:     %s\n" (or kp-test--name "(not set)"))
  │             "\n"
  │             (propertize "Press h for popup, H for child-frame, q to quit.\n" 'face 'shadow))))
  │ 
  │ (defun kp-test--refresh ()
  │   "Refresh the display (stay-open)."
  │   (interactive)
  │   (kp-test--render)
  │   (message "Refreshed"))
  │ 
  │ ;;; Commands
  │ 
  │ (defun kp-test--greet ()
  │   "Greet using buffer-local state."
  │   (interactive)
  │   (let ((name (or kp-test--name "world"))
  │         (loud current-prefix-arg))
  │     (message (if loud
  │                  (format "%s!!!" (upcase name))
  │                (format "Hello, %s." name)))
  │     (kp-test--render)))
  │ 
  │ (defun kp-test--sub-action ()
  │   (interactive)
  │   (message "Sub-menu action! prefix=%s" current-prefix-arg))
  │ 
  │ ;;; Sub-menu keymap
  │ 
  │ (keymap-popup-define kp-test--sub-map
  │   :description "Sub menu"
  │   :group "Sub-menu"
  │   "s" ("Sub action" kp-test--sub-action)
  │   "x" ("Greet from sub" kp-test--greet))
  │ 
  │ ;;; Root keymap
  │ 
  │ (keymap-popup-define kp-test--map
  │   "Test popup"
  │   :description (lambda ()
  │                  (concat (propertize (format-time-string "%H:%M:%S") 'face 'bold)
  │                          " "
  │                          (propertize (format-time-string "%a %d %b") 'face 'shadow)))
  │   :group "Actions"
  │   "a" ("Greet" kp-test--greet :c-u "SHOUT (C-u)")
  │   "g" ("Refresh" kp-test--refresh :stay-open t)
  │   :group "Infixes"
  │   "v" ("Verbose" :switch kp-test--verbose)
  │   "n" ((lambda () (concat "Name ="
  │                          (if (and kp-test--name (not (string-empty-p kp-test--name)))
  │                              (propertize kp-test--name 'face 'success)
  │                            (propertize "?" 'face 'warning))))
  │        (lambda () (interactive)
  │          (setq-local kp-test--name (read-string "Your name: "))
  │          (keymap-popup kp-test--map)))
  │   :group "Navigate"
  │   "s" ("Sub-menu" :keymap kp-test--sub-map)
  │   "q" ("Quit" quit-window)
  │   "H" ("Popup (child-frame)" (lambda () (interactive)
  │                                 (let ((keymap-popup-backend #'keymap-popup-backend-child-frame))
  │                                   (keymap-popup kp-test--map))))
  │   :row
  │   :group "Inapt (entry-level)"
  │   "m" ("Merge (always blocked)" kp-test--greet :inapt-if (lambda () t))
  │   "d" ("Dynamic inapt" kp-test--greet
  │        :inapt-if (lambda () (not kp-test--verbose)))
  │   :group ("Group inapt (when verbose off)" :inapt-if (lambda () (not kp-test--verbose)))
  │   "x" ("Group-blocked cmd" kp-test--greet)
  │   :group ("Toggle (visible when verbose)" :if (lambda () kp-test--verbose))
  │   "t" ("Verbose-only action" kp-test--greet))
  │ 
  │ ;;; Entry point
  │ 
  │ (defun kp-test ()
  │   "Open the *kp-test* buffer and activate the popup.
  │ h opens side-window popup, H opens child-frame popup."
  │   (interactive)
  │   (let ((buf (get-buffer-create "*kp-test*")))
  │     (with-current-buffer buf
  │       (setq-local buffer-read-only t)
  │       (kp-test--render)
  │       (use-local-map kp-test--map))
  │     (pop-to-buffer-same-window buf)
  │     (keymap-popup kp-test--map)))
  │ 
  └────


4 Annotating existing keymaps
═════════════════════════════

  ┌────
  │ (keymap-popup-annotate dired-mode-map
  │   :popup-key "h"
  │   :group "Navigate"
  │   dired-next-line "Next"
  │   dired-previous-line "Previous"
  │   :group "Mark"
  │   dired-mark "Mark"
  │   dired-unmark "Unmark")
  └────

  Keys are resolved dynamically via `where-is-internal', so the popup
  always reflects the user's current bindings.


4.1 Full example
────────────────

  ┌────
  │ (require 'dired)
  │ (require 'dired-x)
  │ 
  │ ;;; Helpers
  │ 
  │ (defun keymap-popup-live-test--marked-p ()
  │   "Non-nil when at least one file is marked."
  │   (dired-get-marked-files nil nil nil t))
  │ 
  │ (defun keymap-popup-live-test--marked-count ()
  │   "Return count of marked files as a string."
  │   (let ((files (dired-get-marked-files nil nil nil t)))
  │     (if (and files (not (eq (car files) t)))
  │         (format " [%d marked]" (length files))
  │       "")))
  │ 
  │ ;;; Sub-menu: mark operations
  │ 
  │ (keymap-popup-define keymap-popup-live-test-mark-map
  │   :description "Mark operations"
  │   :group "Mark"
  │   "m" ("Mark" dired-mark :stay-open t)
  │   "u" ("Unmark" dired-unmark :stay-open t)
  │   "U" ("Unmark All" dired-unmark-all-marks)
  │   "t" ("Toggle" dired-toggle-marks :stay-open t)
  │   :group ("Regexp" :inapt-if (lambda () (not (keymap-popup-live-test--marked-p))))
  │   "r" ("Rename" dired-do-rename-regexp)
  │   "c" ("Copy" dired-do-copy-regexp)
  │   :group "Flag"
  │   "#" ("Auto-save files" dired-flag-auto-save-files :stay-open t)
  │   "~" ("Backups" dired-flag-backup-files :stay-open t)
  │   "x" ("Delete Flagged" dired-do-flagged-delete))
  │ 
  │ ;;; Main annotated popup for dired-mode-map
  │ 
  │ (keymap-popup-annotate dired-mode-map
  │   :popup-key "?"
  │   :persistent t
  │   :exit-key "x"
  │   :description (lambda ()
  │                  (format "Dired: %s%s"
  │                          (abbreviate-file-name default-directory)
  │                          (keymap-popup-live-test--marked-count)))
  │   :group "File"
  │   dired-find-file-other-window "Open other"
  │   dired-view-file "View"
  │   dired-do-copy "Copy"
  │   dired-do-rename "Rename"
  │   dired-do-delete "Delete"
  │   dired-do-shell-command "Shell cmd"
  │   dired-do-async-shell-command "Shell cmd &"
  │   :group "Navigate"
  │   dired-up-directory (lambda ()
  │                        (format "Up to %s"
  │                                (abbreviate-file-name
  │                                 (file-name-directory
  │                                  (directory-file-name default-directory)))))
  │   dired-previous-line "Prev"
  │   dired-next-line "Next"
  │   dired-goto-file "Goto file"
  │   :group "Directory"
  │   revert-buffer "Revert"
  │   wdired-change-to-wdired-mode "Edit (wdired)"
  │   dired-hide-details-mode (lambda ()
  │                             (if (bound-and-true-p dired-hide-details-mode)
  │                                 "Show details" "Hide details"))
  │   dired-omit-mode (lambda ()
  │                     (if (bound-and-true-p dired-omit-mode)
  │                         "Show omitted" "Omit files"))
  │   dired-create-directory "New directory"
  │   ;; Sub-menu via string key + :keymap
  │   "M" ("Mark" :keymap keymap-popup-live-test-mark-map)
  │   :group ("Bulk" :inapt-if (lambda () (not (keymap-popup-live-test--marked-p))))
  │   dired-do-chmod "Chmod"
  │   dired-do-chown "Chown"
  │   dired-do-compress "Compress")
  │ 
  │ (dired default-directory)
  │ (message "Press ? in the dired buffer to open the popup")
  │ 
  └────
