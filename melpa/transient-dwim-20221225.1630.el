;;; transient-dwim.el --- Useful preset transient commands  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Version: 1.0.9
;; Package-Version: 20221225.1630
;; Package-Commit: cb5e0d35729fc6448553b7a17fc5c843f00e8c1d
;; Keywords: tools
;; Package-Requires: ((emacs "26.1") (transient "0.1"))
;; URL: https://github.com/conao3/transient-dwim.el

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>

;;; Commentary:

;; Using transient to display the preconfigured transient dispatcher
;; for your situation (major-mode or installed packages).

;; By installing this package, if you want to know what features
;; exist in major-mode for the first time, or if you want to use
;; a package you can't remember keybindings for, pressing M-= (if
;; you're using the recommended settings) will be your first step.

;; You don't have to remember the cumbersome keybindings since
;; now.  Just look at the neatly aligned menu and press the key
;; that appears.

;; To use this package, simply add below code to your init.el:
;;   (define-key global-map (kbd "M-=") 'transient-dwim-dispatch)


;;; Code:

(require 'seq)
(require 'subr-x)
(require 'transient)

(defgroup transient-dwim nil
  "Useful preset transient commands."
  :prefix "transient-dwim-"
  :group 'tools
  :link '(url-link :tag "Github" "https://github.com/conao3/transient-dwim.el"))


;;; Functions

(declare-function magit-get "magit")
(declare-function magit-remote-p "magit")
(declare-function magit-commit-create "magit")
(declare-function magit-commit-amend "magit")
(declare-function magit-commit-extend "magit")
(declare-function magit-branch-and-checkout "magit")
(declare-function magit-get-current-branch "magit")

;;; Magit
(defun transient-dwim-magit-commit-all ()
  "Commit via magit with --all argument."
  (interactive)
  (magit-commit-create '("--all")))

(defun transient-dwim-magit-amend-all ()
  "Commit via magit with --all argument."
  (interactive)
  (magit-commit-amend '("--all")))

(defun transient-dwim-magit-extend-all ()
  "Commit via magit with --all argument."
  (interactive)
  (magit-commit-extend '("--all")))

(defun transient-dwim-magit-feature-checkout ()
  "Checkout feature branch.
If feature branch doesn't exist, create and checkout it."
  (interactive)
  (magit-branch-and-checkout "feature" "origin/master"))

(defun transient-dwim-magit-feature-pull-request ()
  "Do pull request from feature branch to origin/master."
  (interactive)
  (if (not (magit-get-current-branch))
      (user-error "No branch is currently checked out")
    (let ((username (magit-get "user.name")))
      (shell-command
       (mapconcat 'identity
                  `(,(if (magit-remote-p username) ":" "hub fork")
                    ,(format "git push %s" (shell-quote-argument username))
                    "hub pull-request &")
                  " && ")))))

(defun transient-dwim-magit-merge-remote-master ()
  "Checkout master and fetch, merge remote master."
  (interactive)
  (magit-checkout "master")
  (magit-pull-from-upstream nil))


;;; Main

(eval-and-compile
  (defvar transient-dwim-docstring-format
    "Transient-dwim for `%p'.

Depends packages:
%P
URL:
%U
This transient command is defined by `transient-dwim--define-transient-command-multi'.
If you want to customize this transient command, please use transient
customize scheme, https://magit.vc/manual/transient/Modifying-Existing-Transients.html

Or, please send a Issue/PR to https://github.com/conao3/transient-dwim.el"

    "The format string used to docstring for transients function.

The following %-sequences are supported:
  `%p': Target package name.
  `%p': Depends packages name.
  `%U': Depends packages URL.")

  (defun transient-dwim--create-docstring (pkg info)
    "Create docstring from PKG and transient-command-multi INFO."
    (let ((dep-pkgs-info (plist-get info :packages))
          (docstringspec (or (plist-get :docstring info) transient-dwim-docstring-format)))
      (let ((dep-pkgs-name (mapcar (lambda (elm) (alist-get 'name elm)) dep-pkgs-info))
            (dep-pkgs-url  (mapcar (lambda (elm) (alist-get 'url elm)) dep-pkgs-info)))
        (format-spec
         docstringspec
         `((?p . ,(symbol-name pkg))
           (?P . ,(if dep-pkgs-info
                      (cl-loop for elm in dep-pkgs-name
                               for i from 1
                               when elm
                               concat (format "  - %s [%d]\n" elm i))
                    "  None\n"))
           (?U . ,(if dep-pkgs-info
                      (cl-loop for elm in dep-pkgs-url
                               for i from 1
                               when elm
                               concat (format "  - %s [%d]\n" elm i))
                    "  None\n"))))))))

(defmacro transient-dwim--define-transient-command-multi (spec)
  "Define transient command with core information from SPEC."
  `(prog1 'transient-dwim
     ,@(mapcar
        (lambda (elm)
          (let ((pkg  (pop elm))
                (info (pop elm))
                (args elm))
            `(transient-define-prefix ,(intern (format "transient-dwim-%s" pkg)) ()
               ,(transient-dwim--create-docstring pkg info)
               ,@args)))
        spec)))

;;;###autoload (autoload 'transient-dwim-dispatch "transient-dwim" nil t)
(transient-dwim--define-transient-command-multi
 ((dispatch
   nil
   ["Dired-mode"
    :if-derived dired-mode
    ["Mark"
     ("mm"  "Mark"                 dired-mark)
     ("mM"  "Mark all"             dired-mark-subdir-files)
     ("mu"  "Unmark"               dired-unmark)
     ("mU"  "Unmark all"           dired-unmark-all-marks)
     ("m*"  "Executables"          dired-mark-executables)
     ("m/"  "Directories"          dired-mark-directories)
     ("m@"  "Symlinks"             dired-mark-symlinks)
     ("m&"  "Garbage files"        dired-flag-garbage-files)
     ("m#"  "Auto save files"      dired-flag-auto-save-files)
     ("m~"  "backup files"         dired-flag-backup-files)
     ("m."  "Numerical backups"    dired-clean-directory)
     ("m%"  "Regexp"               dired-mark-files-regexp)
     ("mg"  "Regexp file contents" dired-mark-files-containing-regexp)
     ("mc"  "Change mark"          dired-change-marks)
     ("mt"  "Toggle mark"          dired-toggle-marks)]
    ["Command for marked files"
     ("x"   "Do action"            dired-do-flagged-delete)
     ("C"   "Copy"                 dired-do-copy)
     ("D"   "Delete"               dired-do-delete)
     ("S"   "Symlink"              dired-do-symlink)
     ("H"   "Hardlink"             dired-do-hardlink)
     ("P"   "Print"                dired-do-print)
     ("A"   "Find"                 dired-do-find-regexp)
     ("Q"   "Replace"              dired-do-find-regexp-and-replace)
     ("B"   "Elisp bytecompile"    dired-do-byte-compile)
     ("L"   "Elisp load"           dired-do-load)
     ("X"   "Shell command"        dired-do-shell-command)
     ("Z"   "Compress"             dired-do-compress)
     ("z"   "Compress to"          dired-do-compress-to)
     ("!"   "Shell command"        dired-do-shell-command)
     ("&"   "Async shell command"  dired-do-async-shell-command)]
    ["Command"
     ("RET" "Open file"            dired-find-file)
     ("o" "  Open in other window" dired-find-file-other-window)
     ("C-o" "Open in other window (No select)" dired-display-file)
     ("v" "  Open file (View mode)"dired-view-file)
     ("=" "  Diff"                 dired-diff)
     ("j" "  Goto file"            dired-goto-file)
     ("w" "  Copy filename"        dired-copy-filename-as-kill)
     ("W" "  Open in browser"      browse-url-of-dired-file)
     ("y" "  Show file type"       dired-show-file-type)
     ("+" "  Create directory"     dired-create-directory)
     ("<" "  Jump prev directory"  dired-prev-dirline)
     (">" "  Jump next directory"  dired-next-dirline)
     ("^" "  Move up directory"    dired-up-directory)]
    ["Display"
     ("g" "  Refresh buffer"       revert-buffer)
     ("l" "  Refresh file"         dired-do-redisplay)
     ("k" "  Remove line"          dired-do-kill-lines)
     ("s" "  Sort"                 dired-sort-toggle-or-edit)
     ("(" "  Hide detail info"     dired-hide-details-mode)
     ("i" "  Insert subdir"        dired-maybe-insert-subdir)
     ("$" "  Hide subdir"          dired-hide-subdir)
     ("M-$" "Hide subdir all"      dired-hide-subdir)]
    ["Attribute"
     ("R"   "Name"                 dired-do-rename)
     ("G"   "Group"                dired-do-chgrp)
     ("M"   "Mode"                 dired-do-chmod)
     ("O"   "Owner"                dired-do-chown)
     ("T"   "Timestamp"            dired-do-touch)]
    ["Extension"
     ("e"   "wdired"               wdired-change-to-wdired-mode)
     ("p"   "image-dired"          transient-dwim-dired-mode--image)
     (":"   "epa-dired"            transient-dwim-dired-mode--epa)
     ("/"   "dired-filter"         ignore)
     ("n"   "dired-narrow"         ignore)
     ("V"   "dired-git"            transient-dwim-dired-mode--git)]]

   ["Image-dired-thumbnail-mode"
    :if-derived image-dired-thumbnail-mode
    ["Commands"
     ("d" "  Mark as delete"       image-dired-flag-thumb-original-file)
     ("m" "  Mark"                 image-dired-mark-thumb-original-file)
     ("u" "  Unmark"               image-dired-unmark-thumb-original-file)
     ("." "  Track"                image-dired-track-original-file)
     ("TAB" "Jump dired"           image-dired-jump-original-dired-buffer)
     ("gf" " Line up"              image-dired-line-up)
     ("gg" " Line up (dynamic)"    image-dired-line-up-dynamic)
     ("gi" " Line up (interactive)"image-dired-line-up-interactive)
     ("tt" " Tag"                  image-dired-tag-thumbnail)
     ("tr" " Delete tag"           image-dired-tag-thumbnail-remove)

     ("RET" "Open image"           image-dired-display-thumbnail-original-image)
     ("E" "  Open image external"  image-dired-thumbnail-display-external)

     ("l" "  Rotate left"          image-dired-rotate-thumbnail-left)
     ("r" "  Rotate right"         image-dired-rotate-thumbnail-right)
     ("L" "  Original rotate left" image-dired-rotate-original-left)
     ("R" "  Original rotate right"image-dired-rotate-original-right)

     ("D" "  Add description"      image-dired-thumbnail-set-image-description)
     ("C-d" "Delete thumnail"      image-dired-delete-char)
     ("SPC" "Show image and next"  image-dired-display-next-thumbnail-original)
     ("DEL" "Show image and prev"  image-dired-display-previous-thumbnail-original)
     ("c" "  Add comment"          image-dired-comment-thumbnail)]]

   ["Neotree"
    :if-derived neotree-mode
    ["Commands"
     ("RET" "  Open"               neotree-enter)
     ("M-RET" "Open external"      neotree-open-file-in-system-application)
     ("SPC" "  Quick Look"         neotree-quick-look)
     ("o2" "   Open (Horizontal)"  neotree-enter-horizontal-split)
     ("o3" "   Open (Vertical)"    neotree-enter-vertical-split)
     ("o4" "   Open (Ace window)"  neotree-enter-ace-window)
     ("k" "    Copy filepath"      neotree-copy-filepath-to-yank-ring)
     ("P" "    Projectile"         neotree-projectile-action)]
    ["Operations"
     ;; ("" "Rename current node as another path." neo-buffer--rename-node)
     ;; ("" "Copies current node as another path." neo-buffer--copy-node)
     ;; ("c" "Create"              neotree-create-node)
     ("R" "Rename"                 neotree-rename-node)
     ("C" "Copy"                   neotree-copy-node)
     ("D" "Delete"                 neotree-delete-node)
     ;; ("" "Show (Toggle)"        neotree-toggle)
     ;; ("" "Show"                 neotree-show)
     ("q" "Close"                  neotree-hide)
     ;; ("" "Select"               neo-global--select-window)
     ("g" "Refresh"                neotree-refresh)
     ;; ("" "Do auto refresh."     neo-global--do-autorefresh)
     ]
    ["Navigate"
     ("n" "next"                   neotree-next-line)
     ("p" "previous"               neotree-previous-line)
     ("d" "down"                   neotree-select-down-node)
     ;; ("" "Previous same level"  neotree-select-previous-sibling-node)
     ;; ("" "Next same level"      neotree-select-next-sibling-node)

     ;; ("" "Select Current buffer"neotree-find)
     ("/" "cd"                     neotree-change-root)
     ("^" "cd parent"              neotree-select-up-node)
     ;; ("" "Show and change root" neotree-dir)
     ("%" "Collapse"               neotree-collapse-all)]
    ["Toggle"
     ("A" "Stretch"                neotree-stretch-toggle)
     ("." "Hidden files"           neotree-hidden-file-toggle)]
    ["Misc"
     ;; ("" "Return list of unsaved buffers from projectile buffers." neo-get-unsaved-buffers-from-projectile)
     ;; ("" "Define the behaviors for keyboard event." neo-buffer--execute)
     ;; ("" "Toggle the variable neo-click-changes-root." neotree-click-changes-root-toggle)
     ]]

   ["EIN list"
    :if-derived ein:notebooklist-mode
    [("g" "Refresh list"           ein:notebooklist-reload)
     ("n" "New notebook"           ein:notebooklist-new-notebook-with-name)
     ("/" "New scratch notebook"   ein:notebooklist-new-notebook)
     ("l" "Login"                  ein:notebooklist-login)]]

   ["EIN"
    :if (lambda () (bound-and-true-p ein:notebook-mode))
    ["File"
     ("#" "Close"                  ein:notebook-close)
     ("o" "Open"                   ein:notebook-open)
     ("s" "Save"                   ein:notebook-save-notebook-command)
     ("S" "Save as"                ein:notebook-save-to-command)
     ("w" "Rename"                 ein:notebook-rename-command)
     ("/" "Open Scratch"           ein:notebook-scratchsheet-open)
     ("j" "Jump"                   ein:notebook-jump-to-opened-notebook)]
    ["Cell"
     ("RET" "    Execute cell"     ein:worksheet-execute-cell)
     ("M-RET" "  Execute/move"     ein:worksheet-execute-cell-and-goto-next)
     ("M-S-RET" "Execute/insert"   ein:worksheet-execute-cell-and-insert-below)
     ("A" "      Execute all"      ein:worksheet-execute-all-cells)
     ("<" "      Execute all above" ein:worksheet-execute-all-cells-above)
     (">" "      Execute all below" ein:worksheet-execute-all-cells-below)
     ("h" "      Hide/Unhide"      ein:worksheet-toggle-output)
     ("H" "      Unhide all"       ein:worksheet-set-output-visibility-all)
     ("c" "      Clear output"     ein:worksheet-clear-output)
     ("C" "      Clear output all" ein:worksheet-clear-all-output)]
    [("k" "Kill"                   ein:worksheet-kill-cell)
     ("K" "Copy"                   ein:worksheet-copy-cell)
     ("y" "Yank"                   ein:worksheet-yank-cell)
     ("a" "Insert above"           ein:worksheet-insert-cell-above)
     ("b" "Insert below"           ein:worksheet-insert-cell-below)
     ("t" "Toggle type"            ein:worksheet-toggle-cell-type)
     ("u" "Change type"            ein:worksheet-change-cell-type)
     ("-" "Split"                  ein:worksheet-split-cell-at-point)
     ("m" "Merge"                  ein:worksheet-merge-cell)]
    ["Navigate"
     ("n" "Next"                   ein:worksheet-goto-next-input)
     ("p" "Prev"                   ein:worksheet-goto-prev-input)
     ("N" "Next input"             ein:worksheet-goto-next-input)
     ("P" "Prev input"             ein:worksheet-goto-prev-input)
     ("M-<up>" "  Move above"      ein:worksheet-move-cell-up)
     ("M-<down>" "Move below"      ein:worksheet-move-cell-down)]
    ["Kernel"
     ("R" "Restart"                ein:notebook-restart-session-command)
     ("r" "Reconnect"              ein:notebook-reconnect-session-command)
     ("z" "Interrupt"              ein:notebook-kernel-interrupt-command)
     ("q" "Kill kernel"            ein:notebook-kill-kernel-then-close-command)
     ("*" "Change kernel"          ein:notebook-switch-kernel)]
    ["misc"
     ("$" "Show traceback"         ein:tb-show)
     ("f" "Open file"              ein:file-open)
     ("." "Jump definition"        ein:pytools-jump-to-source-command)
     ("," "Jump back"              ein:pytools-jump-back-command)
     ;; (";" "Exec cell/Show results in another buffer" ein:shared-output-show-code-cell-at-point)
     ]]

   ["Extension"
    [("M-=" "Magit"                transient-dwim-magit   :if (lambda () (require 'magit nil t)))
     ("M-a" "Oj"                   transient-dwim-oj      :if (lambda () (require 'oj nil t)))
     ("M-o" "Org"                  transient-dwim-org     :if (lambda () (require 'org nil t)))
     ("M-O" "Origami"              transient-dwim-origami :if (lambda () (require 'origami nil t)))
     ("M-N" "Neotree"              transient-dwim-neotree :if (lambda () (require 'neotree nil t)))]])

  (dired-mode--image
   (:packages (((name . "image-dired (builtin)"))))
   ["Commands"
    ("d"    "Open thumbnail buffer"image-dired-display-thumbs)
    ("j"    "Jump thumbnail buffer"image-dired-jump-thumbnail-buffer)
    ("a"    "Append thumnail buffer" image-dired-display-thumbs-append)
    ("i"    "Inline thumnail"      image-dired-dired-toggle-marked-thumbs)
    ("f"    "Display image"        image-dired-dired-display-image)
    ("x"    "Open external"        image-dired-dired-display-external)
    ("m"    "Mark via tag"         image-dired-mark-tagged-files)
    ("t"    "Edit tag"             image-dired-tag-files)
    ("r"    "Delete tag"           image-dired-delete-tag)
    ("c"    "Edit comment"         image-dired-dired-comment-files)
    ("e"    "Edit comment/tag"     image-dired-dired-edit-comment-and-tags)])

  (dired-mode--git
   (:packages (((name . "dired (builtin)"))))
   [["Worktree"
     ("c"   "Commit"               dired-git-commit)
     ("S"   "Stage"                dired-git-stage)
     ("U"   "Unstage"              dired-git-unstage)
     ("zz"  "Stash"                dired-git-stash)
     ("zp"  "Stash pop"            dired-git-stash-pop)
     ("X"   "Reset --hard"         dired-git-reset-hard)]
    ["Branch"
     ("b"   "Branch"               dired-git-branch)
     ("t"   "Tag"                  dired-git-tag)
     ("f"   "Fetch"                dired-git-fetch)
     ("F"   "Pull"                 dired-git-pull)
     ("m"   "Merge"                dired-git-merge)
     ("P"   "Push"                 dired-git-push)
     ("!"   "Run"                  dired-git-run)]])

  (dired-mode--epa
   (:packages (((name . "epa-dired (builtin)"))))
   ["Commands"
    ("e"    "Encrypt"              epa-dired-do-encrypt)
    ("d"    "Decrypt"              epa-dired-do-decrypt)
    ("v"    "Verify"               epa-dired-do-verify)
    ("s"    "Sign"                 epa-dired-do-sign)])

  (oj
   (:packages (((name . "oj (MELPA)")
                (url  . "https://github.com/conao3/oj.el"))))
   [["System"
     ("i"   "Install"              oj-install-packages)
     ("s"   "Open shell"           oj-open-shell)
     ("l"   "Login"                oj-login)
     ("o"   "Open home dir"        oj-open-home-dir)]
    ["Commands"
     ("r" "  Prepare"              oj-prepare)
     ("M-a" "Test"                 oj-test)
     ("S" "  Submit"               oj-submit)]
    ["Navigate"
     ("n"   "Next"                 oj-next)
     ("p"   "Prev"                 oj-prev)]])

  (origami
   (:packages (((name . "origami (MELPA)")
                (url  . "https://github.com/gregsexton/origami.el"))))
   [["Open/Close"
     ("s" "  Show"                 origami-show-node)
     ("S" "  Only show"            origami-show-only-node)
     ("o" "  Open"                 origami-open-node)
     ("O" "  Open all"             origami-open-all-nodes)
     ("C-o" "Open recursive"       origami-open-node-recursively)
     ("c" "  Close"                origami-close-node)
     ("C" "  Close all"            origami-close-all-nodes)
     ("C-c" "Close recursive"      origami-close-node-recursively)]
    ["Navigate"
     ("p" "  Previous"             origami-previous-fold)
     ("n" "  Next"                 origami-next-fold)
     ("f" "  Forward"              origami-forward-fold)
     ("C-f" "Forward same level"   origami-forward-fold-same-level)
     ("C-b" "Backward same level"  origami-backward-fold-same-level)]
    ["Toggle/Misc"
     ("t" "  Toggle"               origami-toggle-node)
     ("T" "  Toggle all"           origami-toggle-all-nodes)
     ("r" "  Toggle recursive"     origami-recursively-toggle-node)
     ("R" "  Forward toggle"       origami-forward-toggle-node)
     ("u" "  Undo"                 origami-undo)
     ("/" "  Redo"                 origami-redo)
     ("q" "  Reset"                origami-reset)]])

  (org
   (:pakcages (((name . "org (builtin)")
                (url  . "https://orgmode.org/"))))
   [["Commands"
     ("M-o" "capture"              org-capture)
     ("M-a" "agenda"               org-agenda)]])

  (neotree
   (:packages (((name . "neotree (MELPA)")
                (url  . "https://github.com/jaypei/emacs-neotree"))))
   [["Commands"
     ;; ("RET" "  Open"               neotree-enter)
     ;; ("M-RET" "Open external"      neotree-open-file-in-system-application)
     ;; ("SPC" "  Quick Look"         neotree-quick-look)
     ;; ("o2" "   Open (Horizontal)"  neotree-enter-horizontal-split)
     ;; ("o3" "   Open (Vertical)"    neotree-enter-vertical-split)
     ;; ("o4" "   Open (Ace window)"  neotree-enter-ace-window)
     ;; ("k" "    Copy filepath"      neotree-copy-filepath-to-yank-ring)
     ;; ("P" "    Projectile"         neotree-projectile-action)
     ]
    ["Operations"
     ;; ("" "Rename current node as another path." neo-buffer--rename-node)
     ;; ("" "Copies current node as another path." neo-buffer--copy-node)
     ;; ("c" "Create"              neotree-create-node)
     ;; ("R" "Rename"              neotree-rename-node)
     ;; ("C" "Copy"                neotree-copy-node)
     ;; ("D" "Delete"              neotree-delete-node)
     ("s" "Show"                   neotree-show)
     ("q" "Close"                  neotree-hide)
     ;; ("" "Select"               neo-global--select-window)
     ("g" "Refresh"                neotree-refresh)
     ;; ("" "Do auto refresh."     neo-global--do-autorefresh)
     ]
    ["Navigate"
     ;; ("n" "next"                neotree-next-line)
     ;; ("p" "previous"            neotree-previous-line)
     ;; ("d" "down"                neotree-select-down-node)
     ;; ("" "Previous same level"  neotree-select-previous-sibling-node)
     ;; ("" "Next same level"      neotree-select-next-sibling-node)

     ;; ("" "Select Current buffer"neotree-find)
     ;; ("/" "cd"                  neotree-change-root)
     ;; ("^" "cd parent"           neotree-select-up-node)
     ;; ("" "Show and change root" neotree-dir)
     ;; ("%" "Collapse"            neotree-collapse-all)
     ]
    ["Toggle"
     ("t" "Show"                   neotree-toggle)
     ("A" "Stretch"                neotree-stretch-toggle)
     ("." "Hidden files"           neotree-hidden-file-toggle)]
    ["Misc"
     ;; ("" "Return list of unsaved buffers from projectile buffers." neo-get-unsaved-buffers-from-projectile)
     ;; ("" "Define the behaviors for keyboard event." neo-buffer--execute)
     ;; ("" "Toggle the variable neo-click-changes-root." neotree-click-changes-root-toggle)
     ]])

  (magit
   (:packages (((name . "magit (MELPA)")
                (url  . "https://github.com/magit/magit"))))
   ["Arguments"
    ("-a" "Stage all modified and deleted files"   ("-a" "--all"))
    ("-e" "Allow empty commit"                     "--allow-empty")
    ("-v" "Show diff of changes to be committed"   ("-v" "--verbose"))
    ("-n" "Disable hooks"                          ("-n" "--no-verify"))
    ("-R" "Claim authorship and reset author date" "--reset-author")
    (magit:--author :description "Override the author")
    (7 "-D" "Override the author date" "--date=" transient-read-date)
    ("-s" "Add Signed-off-by line"                 ("-s" "--signoff"))
    (5 magit:--gpg-sign)
    (magit-commit:--reuse-message)]

   [["Commit"
     ("c" "  Commit"               magit-commit)
     ("M-=" "Commit -a"            transient-dwim-magit-commit-all)
     ("e" "  Extend"               magit-commit-extend)
     ("E" "  Extend -a"            transient-dwim-magit-extend-all)
     ("a" "  Amend"                magit-commit-amend)
     ("A" "  Amend -a"             transient-dwim-magit-amend-all)
     ("w" "  Reword"               magit-commit-reword)]
    ["Misc"
     ("U" "  Fixup"                magit-commit-instant-fixup)
     ("S" "  Squash"               magit-commit-instant-squash)
     ("s" "  Status"               magit-status)
     ("(" "  Checkout feature"     transient-dwim-magit-feature-checkout)
     (")" "  PR feature"           transient-dwim-magit-feature-pull-request)
     ("M-P" "Checkout/Pull master" transient-dwim-magit-merge-remote-master)]
    ["Magit dispatch"
     ;; ("A" "Apply"               magit-cherry-pick)
     ("b"   "Branch"               magit-branch)
     ("B"   "Bisect"               magit-bisect)
     ;; ("c" "Commit"              magit-commit)
     ("C"   "Clone"                magit-clone)
     ("d"   "Diff"                 magit-diff)
     ("D"   "Diff (change)"        magit-diff-refresh)
     ;; ("e" "Ediff (dwim)"        magit-ediff-dwim)
     ;; ("E" "Ediff"               magit-ediff)
     ("f"   "Fetch"                magit-fetch)
     ("F"   "Pull"                 magit-pull)
     ("l"   "Log"                  magit-log)
     ("L"   "Log (change)"         magit-log-refresh)]
    [""
     ("m"   "Merge"                magit-merge)
     ("M"   "Remote"               magit-remote)
     ("o"   "Submodule"            magit-submodule)
     ("O"   "Subtree"              magit-subtree)
     ("P"   "Push"                 magit-push)
     ("r"   "Rebase"               magit-rebase)
     ("t"   "Tag"                  magit-tag)
     ("T"   "Note"                 magit-notes)]
    [""
     ("V"   "Revert"               magit-revert)
     ;; ("w" "Apply patches"       magit-am)
     ("W"   "Format patches"       magit-patch)
     ("X"   "Reset"                magit-reset)
     ("y"   "Show Refs"            magit-show-refs)
     ("Y"   "Cherries"             magit-cherry)
     ("z"   "Stash"                magit-stash)
     ("!"   "Run"                  magit-run)
     ("%"   "Worktree"             magit-worktree)]])))

(provide 'transient-dwim)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; transient-dwim.el ends here
