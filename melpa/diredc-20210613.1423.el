;;; diredc.el --- Extensions for dired -*- lexical-binding: t -*-

;; Copyright © 2020-2021, Boruch Baum <boruch_baum@gmx.com>

;; Author/Maintainer: Boruch Baum <boruch_baum@gmx.com>
;; Homepage: https://github.com/Boruch-Baum/emacs-diredc
;; License: GPL3+
;; Keywords: files
;; Package-Version: 20210613.1423
;; Package-Commit: 5e13b7c088e2554b2aa406581520d53902c74016
;; Package: diredc
;; Version: 1.0
;; Package-Requires: ((emacs "26.1") (key-assist "1.0"))
;;
;;   (emacs "24.1") for: split-window-right
;;   (emacs "24.3") for: lexical-binding, user-error, cl-lib, defvar-local
;;   (emacs "24.4") for: advice-remove
;;   (emacs "25.1") for: save-mark-and-excursion
;;   (emacs "26.1") for: copied version of dired-internal-noselect

;; This file is NOT part of GNU Emacs.

;; This is free software: you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation, either version 3 of the License, or (at your
;; option) any later version.

;; This software is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
;; Public License for more details.

;; You should have received a copy of the GNU General Public License along
;; with this software. If not, see <https://www.gnu.org/licenses/>.

;;
;;; Commentary:
;;
;; This package extends and configures `dired' with features found in
;; almost all 'file managers', and also some unique features:
;;
;;   * Resilient dedicated dual-pane frame.
;;     * similar look to 'midnight commander'.
;;     * intelligent recovery of manually altered frame configuration
;;     * exit diredc/dired cleanly and totally
;;   * Navigable directory history
;;     * backward, forward, or to a direct history entry
;;   * File quick-preview mode
;;     * inspired by, and similar to, midnight commander's "C-x q"
;;     * customizable exclusion criteria to suppress undesirable files
;;       (eg. binaries)
;;   * Current file's supplemental information in minibuffer (optional)
;;     * eg. output from 'getfattr', 'getfacl', 'stat', 'exif'.
;;   * Multiple panel views
;;     * inspired by, and similar to, midnight commander's "M-t"
;;       * superior configurability
;;       * directly choose a specific panel view, or toggle to next
;;   * Extensive and easy-to-use sort options
;;     * including options not in 'ls': sort by chmod, owner, group
;;   * Swap panels (use "M-u")
;;     * inspired by, and similar to, midnight commander's "C-u"
;;       * a TRUE and complete swap (including history entries)
;;   * Trash management
;;     * per xfreedesktop standard
;;     * restore trashed files to their original locations
;;     * empty the trash, along with its administrative overhead
;;     * view trash summary information
;;   * Navigate 'up' n parent directories
;;   * Launch persistent asynchronous processes for files
;;     * Processes will survive even after exiting Emacs.
;;   * Quick shell window
;;     * choose your default shell / terminal emulation mode
;;     * choose your default shell program
;;     * easily opt for pre-configured alternatives
;;     * useful pre-defined shell variables
;;       * $d1, $d2  dired-directory in this/other pane
;;       * $f1, $f2  current dired file in this/other pane
;;       * $t1, $t2  tagged elements in this other pane
;;         * as a shell array variable, if supported by the shell
;;   * Bookmark support
;;   * Edit dired buffers (really `wdired-mode', not `diredc')
;;   * Set both panels to same directory (use "=" or "C-u =")
;;     * inspired by 'midnight commander's "M-i"
;;
;; Bonus customization features
;;   * Customize colors for chmod bits (font-lock)
;;   * toggle display of "hidden" or "undesirable" files (dired-omit mode)
;;   * auto-refresh buffers (auto-revert-mode)
;;   * highlight current line (hl-line-mode)
;;     * current buffer highlights with a unique face.
;;   * don't wrap long lines (toggle-truncate-lines)
;;   * to disable:
;;     * option 1: M-x customize-variable diredc-bonus-configuration
;;     * option 2: (setq diredc-bonus-configuration nil)

;;
;;; Dependencies (all are already part of Emacs):
;;
;;   autorevert -- for auto-revert-mode
;;   dired       -- ... (doh) ...
;;   dired-x     -- for dired-guess-default, dired-omit-mode
;;   dired-aux   -- for dired-compress-files
;;   help-mode   -- for help button widget
;;   hl-line     -- for hl-line-mode
;;   subr        -- for string-match-p
;;   term        -- for term-line-mode, term-send-input
;;   view        -- for view-mode
;;
;; Suggested (not part of Emacs):
;;
;;   popup       -- for popup-menu*
;;   key-assist  -- for key-assist

;;
;;; Installation:
;;
;; 1) Evaluate or load this file.
;;
;; 2) I recommend defining a global keybinding for function `diredc',
;;    with a preference for Shift-F11, as follows:
;;
;;      (global-set-key (kbd "S-<f11>") 'diredc))
;;
;;    An alternative or additional option would be:
;;
;;      (global-set-key [remap dired-other-frame] 'diredc)


;;
;;; Operation:
;;
;; Running `diredc' an initial time creates and selects a frame named
;; `diredc' with two side-by-side `dired' windows / buffers. Repeating the
;; command will return you to your prior frame / window / buffer.
;; Subsequent use of the command continues to toggle back and forth to/from
;; the named `diredc' frame.
;;
;; In addition to the usual Emacs keybinding help, diredc provides two
;; combination keybinding cheat-sheets and command launchers, both using
;; optional dependency package `key-assist'. You can also interactively
;; call M-x `key-assist' <RET> <RET> to view an exhaustive `dired'
;; keybinding listing. A separate `key-assist' is provided for
;; trash-related functions because it also displays the current trash state
;; statistics.
;;
;;     h                        `diredc-key-assist'
;;     C-<delete> ?             `diredc-trash-key-assist'
;;     ?                        `diredc-summary'
;;     C-h m                    `describe-mode'
;;
;; Navigation from one `dired' panel to another can be accomplished using
;; '<TAB>' or 'S-<TAB>'. As long as you are in `diredc' mode, navigating to
;; new directories should not accumulate additional `dired' buffers and
;; your directory navigation history for each panel should be remembered.
;; If ever you find that the frame configuration has become botched, or you
;; somehow accumulate or have lost `dired' buffers, Run M-x
;; `diredc-recover'. You can also cleanly kill all `dired' buffers and the
;; `diredc' frame using `C-q' (M-x `diredc-quit'). And, if you want to use
;; `dired' without the `diredc' features, run M-x `diredc-mode' to toggle
;; the mode off.
;;
;; As mentioned above, each `dired' panel now 'remembers' its navigation
;; history. The history can be traversed sequentially backward 'C-<left>'
;; or forward 'C-<right>' without losing elements, and can be viewed and
;; traversed non-sequentially using 'C-u /'. Use '/' to directly navigate
;; to a directory not 'nearby'.
;;
;; A 'file preview' mode can be entered or exited using 'C-x q' (M-x
;; `diredc-browse-mode'). In that mode, whenever a `dired' buffer's POINT
;; is on a file's line, that file will be opened on the other pane, in
;; read-only emacs `view-mode' (see there for the navigation and other
;; features of that mode). The `view-mode' buffer is deleted automatically
;; when you either disable the mode or you move point to another line in
;; the `dired' buffer. Use '<TAB>' or 'S-<TAB>' to navigate between the
;; `dired' buffer window and the file preview window. There are several
;; options for excluding undesirable files (eg. binaries) from preview; see
;; the mode's docstring for details.
;;
;; The traditional `dired' operations that 'find' or 'open' a file should
;; do so to a separate frame, most likely the one from which you came to
;; the `diredc' frame.
;;
;; The traditional `dired' feature to perform arbitrary asynchronous
;; operations on a file or set of files has been enhanced to make those
;; processes persistent, to survive even after exiting Emacs. Thus, with
;; the default keybinding, you can press '&' <RET> and have the selected
;; file(s) launched in the system-default external application. Do be
;; advised, though, that this comes at the expense of losing the processes'
;; *Async Shell Command* buffer and its log of STDOUT / STDERR for the
;; processes. The former, non-persistent behavior can be opted for at
;; run-time by prefixing the command with a SPACE (eg. " foo") or for the
;; default command simply enter just a SPACE. The former, non-persistent
;; behavior can be made default by modifying variable
;; `diredc-async-processes-are-persistent'.
;;
;; The display format of `dired' buffers can be "hot-swapped" using 'M-t'
;; (M-x `diredc-display-toggle'). Use 'C-u M't' to select from available
;; display formats, and customize the list using defcustom variable
;; `diredc-display--listing-switches-list'. Four views are provided by
;; default, all long-format but with different file block-sizes (byte, Kb,
;; Mb), and several other differences.
;;
;; The traditional `dired' sort feature has been greatly enhanced with a
;; clearer UI and many more sorting options.
;;
;; The `diredc' buffers themselves can also be "hot-swapped", using 'M-u'
;; (M-x `diredc-swap-windows').
;;
;; While emacs does have a native defcustom variable
;; `delete-by-moving-to-trash' to control whether to "really" delete files,
;; `diredc' allows one or more trashed items to be restored, allows the
;; trash to be emptied, and conveniently present trash statistics. Here are
;; the relevant commands and their default keybindings. See each's
;; docstring for more details:
;;
;;     C-<delete> SPC           `diredc-trash-toggle'
;;     C-<delete> <insertchar>  `diredc-trash-toggle'
;;
;;     C-<delete> i             `diredc-trash-info'
;;
;;     C-<delete> j             `diredc-trash-view'
;;     C-<delete> v             `diredc-trash-view'
;;
;;     C-<delete> C-<delete>    `diredc-trash-empty'
;;     C-<delete> x             `diredc-trash-empty'
;;
;;     C-<delete> r             `diredc-trash-restore'
;;
;;     C-k                      `diredc-trash-quick-delete'
;;
;;     C-<delete> ?             `diredc-trash-key-assist'
;;
;; A limitation in `dired' is its inability to natively present a file's
;; supplemental information, such as its possible extended access control
;; list or extended file attributes. `diredc' allows this and more to be
;; presented in the minibuffer echo area as you navigate a `diredc' buffer.
;; Use M-x `diredc-show-more-file-info' to toggle through the default
;; possibilities, or customize the `diredc-show-more-file-info-list' to
;; present the metadata of your choice.
;;
;;     C-c ?     `diredc-show-more-file-info'
;;
;; `diredc' brings bookmarks to dired:
;;
;;     C-c + a   `diredc-bookmark-add'
;;     C-c + j   `diredc-bookmark-jump'
;;     C-c + e   `diredc-bookmark-edit'
;;
;; Emacs has a nifty mode to "edit" a `dired' buffer, bringing the power of
;; emacs to the application of renaming files. `diredc' just gives you the
;; little bit of extra help with convenient keybindings `E' and `e' to
;; enter the mode. If you're happy with your edits, you apply them and exit
;; the mode with `C-c C-c', or abort your editing session with `C-c C-k'.
;;
;; The `diredc-shell' command opens up any type of emacs shell or terminal
;; emulator window and pre-seeds it with useful `dired' values (see section
;; 'Extra Features', below).
;;
;;     '         `diredc-shell'
;;     C-c !     `diredc-shell'
;;     C-c C-k   `diredc-shell-kill'
;;
;; For further information, KRTM, the package's docstrings and the
;; package's defcustom group.

;;
;;; Configuration
;;
;; You can browse and edit this mode's list of `defcustom's using "M-x
;; `customize-group' diredc", but there isn't too much to be found there.
;; Separately, you might want to redefine the default keybindings, but
;; otherwise there is nothing really important about `diredc' itself to
;; configure.
;;
;; `dired' mode itself, however, is a complex and highly configurable
;; package that has been under development for over 25 years. That's a long
;; time for options to accumulate and for opinions to multiply. The
;; `diredc' developer (ahem: me) has considerately imposed his preferences
;; upon you by default, in a way trivial to over-ride. If you don't want
;; them, toggle the value of defcustom `diredc-bonus-configuration' to nil,
;; an the settings will revert upon selecting new buffers. The bonus
;; customization features are listed above, in the 'Commentary' section, or
;; you could peek at the source code of function
;; `diredc-bonus-configuration'.
;;
;; The colorization for each buffer's selected line is set as part of
;; `diredc-bonus-configuration', but because it's controlled by
;; `hl-line-mode'; you can independently toggle the feature per-buffer, and
;; you can change the highlighting colors using "M-x `customize-face'" for
;; faces `hl-line' and `diredc-hl-current-buffer'. The colorization of the
;; chmod bits are also set as part of `diredc-bonus-configuration'; you can
;; find their definitions and edit them using "M-x `customize-group'
;; diredc".

;;
;;; Extra Features:
;;
;; *] Navigating to a parent directory with `dired-up-directory' (default:
;;    `^') can use the prefix-argument to navigate multiple levels in one
;;    operation.
;;
;; *] Use `dired-hist-change-directory' (default: `/') to jump to a
;;    location not nearby without losing the current dired buffer's
;;    history.
;;
;; *] Use the `prefix-argument' with `diredc-hist-change-directory' to have
;;    `diredc-hist-select' display all elements of the Dired buffer's
;;    history and allow you to jump directly to any of them.
;;
;; *] Use `diredc-hist-duplicate' (default: `=') to either navigate to
;;    another `dired' buffer to your current one's directory, or with the
;;    `prefix-argument' to navigate your current `dired' buffer to
;;    another's directory.
;;
;; *] Modify data structure `diredc-recover-schemes' to apply your own
;;    custom recovery strategies. Share them for others' benefit!
;;
;; *) Use `diredc-trash-quick-delete' (default: `C-k') on a POINT or a
;;    REGION to quick-delete the selected files. Use the prefix-arg to
;;    toggle between "trashing" or deleting.
;;
;; *] When `diredc-hist-mode' is disabled, the following functions continue
;;    to operate, but without updating the history records, so you can use
;;    them as your default `dired' functions even if you don't always want
;;    to use `diredc-hist-mode'.
;;
;;      `diredc-hist-change-directory'
;;      `diredc-hist-up-directory'
;;      `diredc-hist-duplicate'
;;      `diredc-hist-find-file'
;;      `diredc-hist-find-file-other-window'
;;      `diredc-hist-find-alternate-file'
;;
;; *] `diredc' passes to the shell/terminal-emulator instance the following
;;    shell variables:
;;
;;      $d1 - this `diredc' windows's directory name
;;      $d2 - directory name of other visible `diredc' window
;;      $f1 - this `diredc' window's file name at POINT
;;      $f2 - file name at POINT  of other visible `diredc' window
;;      $t1 - this `diredc' window's list of tagged file names
;;      $t2 - list of tagged file names  of other visible `diredc' window
;;
;;    If the selected shell supports array variables, then $t1 and $t2 will
;;    be set as such; Otherwise, elements will be quoted and delimited with
;;    a space.

;; *) universal fallback guess shell command(s)

;;
;;; Feedback:
;;
;; It's best to contact me by opening an 'issue' on the program's github
;; repository (see above) or, distant second-best, by direct e-mail.
;;
;; Code contributions are welcome and github starring is appreciated.
;;

;;
;;; Compatibility
;;
;; This package has been tested under debian linux emacs version 26
;; and 27. The main compatibility issue to be aware of is that this
;; suite needs to modify[1] a single line in function
;; `dired-internal-no-select' of the standard emacs file `dired.el'
;; This was accomplished by advising a wrapper function
;; `diredc--advice--dired-internal-noselect' around the original. If
;; that function ever changes, that advice function and this suite
;; will need to account for that.
;;
;; [1] emacs bug #44023: https://debbugs.gnu.org/cgi/bugreport.cgi?bug=44023"


;;
;;; Code:

;;
;;; Dependencies
(require 'dired)     ; ... (doh)
(require 'dired-aux) ; dired-compress-files-alist
(require 'dired-x)   ; dired-guess-default, dired-omit-mode
(require 'term)      ; term-line-mode, term-send-input
(require 'view)      ; view-mode
(require 'autorevert); auto-revert-mode
(require 'help-mode) ; help-xref button

;;
;;; Suggested
(require 'popup nil t)
(declare-function popup-menu* "ext:popup.el")

(require 'key-assist nil t)
(declare-function key-assist                 "ext:key-assist.el")
(declare-function key-assist--get-keybinding "ext:key-assist.el")


;;
;;; Keymaps:

(defun diredc--create-keymap ()
  "Internal function for `diredc'. Create a new symbol `diredc-mode' keymap.
Returns a keymap."
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map dired-mode-map)
    (define-key map (kbd "C-q")       'diredc-exit) ; defalias diredc-quit
    (define-key map (kbd "q")         'diredc-do-not-quit-window)
    (define-key map (kbd "?")         'diredc-summary)
    (define-key map (kbd "h")         'diredc-key-assist)
    (define-key map "\t"              'diredc-other-window)
    (define-key map (kbd "<backtab>") 'diredc-other-window) ; No directionality
    (define-key map [remap dired-find-file]
                                      'diredc-hist-find-file)
    (define-key map [remap dired-find-alternate-file]
                                      'diredc-hist-find-alternate-file)
    (define-key map (kbd "<RET>")     'diredc-hist-find-alternate-file)
    (define-key map (kbd "o")         'diredc-hist-find-file-other-window)
    (define-key map (kbd "/")         'diredc-hist-change-directory)
    (define-key map (kbd "^")         'diredc-hist-up-directory)
    (define-key map (kbd "C-<up>")    'diredc-hist-up-directory)
    (define-key map (kbd "C-<left>")  'diredc-hist-previous-directory)
    (define-key map (kbd "C-<right>") 'diredc-hist-next-directory)
    (define-key map (kbd "=")         'diredc-hist-duplicate)
    (define-key map (kbd "M-u")       'diredc-swap-windows)
    (define-key map (kbd "C-x q")     'diredc-browse-mode)
    (define-key map (kbd "M-t")       'diredc-display-toggle)
    (define-key map (kbd "C-c ?")     'diredc-show-more-file-info)
    (define-key map (kbd "C-c + a")   'diredc-bookmark-add)
    (define-key map (kbd "C-c + j")   'diredc-bookmark-jump)
    (define-key map (kbd "C-c + e")   'diredc-bookmark-edit)
;   (define-key map (kbd "C-c + v")   'diredc-vc-jump) ; TODO: Not certain I want this...
    (define-key map (kbd "E")         'diredc-wdired)
    (define-key map (kbd "e")         'diredc-wdired)
    (define-key map (kbd "s")         'diredc-sort-or-edit)
    (define-key map (kbd "'")         'diredc-shell)
    (define-key map (kbd "&")         'diredc-do-async-shell-command)
    (define-key map (kbd "C-c !")     'diredc-shell)
    (define-key map (kbd "C-k")       'diredc-trash-quick-delete)
    (define-key map (kbd "C-<delete> ?") 'diredc-trash-key-assist)
    (define-key map (kbd "C-<delete> SPC") 'diredc-trash-toggle)
    (define-key map (kbd "C-<delete> <insertchar>") 'diredc-trash-toggle)
    (define-key map (kbd "C-<delete> j") 'diredc-trash-view) ; jump to files-dir
    (define-key map (kbd "C-<delete> v") 'diredc-trash-view) ; jump to files-dir
    (define-key map (kbd "C-<delete> i") 'diredc-trash-info) ; report trash size
    (define-key map (kbd "C-<delete> C-<delete>") 'diredc-trash-empty)
    (define-key map (kbd "C-<delete> x") 'diredc-trash-empty)
    (define-key map (kbd "C-<delete> r") 'diredc-trash-restore)
    (define-key map [remap beginning-of-buffer] 'diredc-beginning-of-buffer)
    (define-key map [remap end-of-buffer]       'diredc-end-of-buffer)
    map))

(defvar diredc-mode-map (diredc--create-keymap))

(defun diredc-browse--create-keymap ()
  "Internal function for `diredc'.
Create a new symbol `diredc-browse-mode' keymap. Returns a
keymap."
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map view-mode-map)
    (define-key map "\t"                        'diredc-browse-tab)
    (define-key map (kbd "<backtab>")           'diredc-browse-backtab)
    (define-key map (kbd "M-u")                 'diredc-swap-windows)
    (define-key map (kbd "C-x q")               'diredc-browse-quit)
    (define-key map [remap View-quit]           'diredc-browse-quit)
    (define-key map [remap View-kill-and-leave] 'diredc-browse-quit)
    (define-key map [remap View-leave]          'diredc-browse-quit)
    (define-key map [remap View-quit-all]       'diredc-browse-quit)
    (define-key map [remap View-exit]           'diredc-browse-find)
    (define-key map [remap View-exit-and-edit]  'diredc-browse-find)
    (define-key map (kbd "C-q")                 'diredc-exit) ; defalias diredc-quit
    map))

(defvar diredc-browse-mode-map (diredc-browse--create-keymap))


;;
;;; Constants:

;; diredc--identify-trash-directory: This function is here, seemingly
;; out of place, because its only purpose is to define several
;; constants, below.
(defun diredc--identify-trash-directory (&optional subdir)
  "Return the path to the 'Trash' directory.

This is an internal `diredc' function. You should never need to
call this function. Instead, use the constants `diredc-trash-dir'
`diredc-trash-files-dir', `diredc-trash-info-dir', or
`diredc-trash-epunged-dir'.

Optional SUBDIR is a string of a subdirectory to return. Note the
behavior of this argument is subject to change as information
about more 'Trash' standards, uh, accumulate. The idea would be
to generically distinguish between 'files', 'info', and
'expunged' content subdirectories (if they exist), wherever they
may be and whatever they may be called."
  (file-name-as-directory
    (cond (trash-directory
            trash-directory)
          ((fboundp 'system-trash-directory)
            (system-trash-directory))
          (t ;; https://freedesktop.org/wiki/Specifications/trash-spec
            (expand-file-name
              (if (member subdir '("files" "info" "expunged"))
                 subdir
                "")
              (directory-file-name
                (expand-file-name "Trash"
                  (or (getenv "XDG_DATA_HOME")
                      "~/.local/share"))))))))

(defconst diredc-trash-dir (diredc--identify-trash-directory)
  "The 'Trash' root directory.")

(defconst diredc-trash-files-dir (diredc--identify-trash-directory "files")
  "The 'Trash' directory with the actual trashed files.")

(defconst diredc-trash-info-dir (diredc--identify-trash-directory "info")
  "The 'Trash' directory with the trashed files' metadata.")

(defconst diredc-trash-expunged-dir (diredc--identify-trash-directory "expunged")
  "The 'Trash' directory with the 'expunged' information.")

(defconst diredc-face-chmod-font-lock-dir   'diredc-face-chmod-font-lock-dir
  "Face definition for how we apply `font-lock' keywords.
Applicable when variable `diredc-bonus-configuration' is non-nil.")

(defconst diredc-face-chmod-font-lock-read  'diredc-face-chmod-font-lock-read
  "Face definition for how we apply `font-lock' keywords.
Applicable when variable `diredc-bonus-configuration' is non-nil.")

(defconst diredc-face-chmod-font-lock-write 'diredc-face-chmod-font-lock-write
  "Face definition for how we apply `font-lock' keywords.
Applicable when variable `diredc-bonus-configuration' is non-nil.")

(defconst diredc-face-chmod-font-lock-exec  'diredc-face-chmod-font-lock-exec
  "Face definition for how we apply `font-lock' keywords.
Applicable when variable `diredc-bonus-configuration' is non-nil.")

(defconst diredc--chmod-font-lock-regex
  " \\([dl-]\\)\\([r-]\\)\\([w-]\\)\\([xsgt-]\\)\\([r-]\\)\\([w-]\\)\\([xsgt-]\\)\\([r-]\\)\\([w-]\\)\\([xsgt-]\\)\\+? "
  "Regexp to identify alphanumeric permission mode strings.
This constant is used to colorize the string, using `font-lock',
when variable `diredc-bonus-configuration' is non-nil.")

(defconst diredc--chmod-font-lock-keyword
  (list
    (list diredc--chmod-font-lock-regex
          '(1 diredc-face-chmod-font-lock-dir)
          '(2 diredc-face-chmod-font-lock-read)
          '(3 diredc-face-chmod-font-lock-write)
          '(4 diredc-face-chmod-font-lock-exec)
          '(5 diredc-face-chmod-font-lock-read)
          '(6 diredc-face-chmod-font-lock-write)
          '(7 diredc-face-chmod-font-lock-exec)
          '(8 diredc-face-chmod-font-lock-read)
          '(9 diredc-face-chmod-font-lock-write)
          '(10 diredc-face-chmod-font-lock-exec)))
  "Diredc `font-lock' keyword definition for chmod strings.
Applicable when variable `diredc-bonus-configuration' is non-nil.")

(defconst diredc--sort-options
;;    prompt                  sort=   reverse  up  LC_COLLATE  column
  '(("none"                  "none"      nil   nil   nil       nil)
    ("name (a-z)"            nil         nil   t     nil       nil)
    ("name (z-a)"            nil         t     nil   nil       nil)
    ("name (A-Za-z)"         nil         nil   t     t         nil)
    ("name (z-aZ-A)"         nil         t     nil   t         nil)
    ("size (decreasing)"     "size"      nil   nil   nil       nil)
    ("size (increasing)"     "size"      t     t     nil       nil)
    ("time (newest first)"   "time"      nil   nil   nil       nil)
    ("time (oldest first)"   "time"      t     t     nil       nil)
    ("version (decreasing)"  "version"   nil   nil   nil       nil)
    ("version (increasing)"  "version"   t     t     nil       nil)
    ("chmod (a-z)"           "chmod"     nil   t     nil       "\\1")
    ("chmod (z-a)"           "chmod"     t     t     nil       "\\1")
    ("owner (a-z)"           "owner"     nil   t     nil       "\\3")
    ("owner (z-a)"           "owner"     t     t     nil       "\\3")
    ("group (a-z)"           "group"     nil   t     nil       "\\4")
    ("group (z-a)"           "group"     t     t     nil       "\\4")
    ("extension (a-z)"       "extension" nil   t     nil       nil)
    ("extension (z-a)"       "extension" t     nil   nil       nil)
    ("extension (A-Za-z)"    "extension" nil   t     t         nil)
    ("extension (Z-Az-a)"    "extension" t     nil   t         nil))
  "List of options for function `diredc-sort-or-edit'.
See there and your version of 'man(1) ls'.")

(defconst diredc--sort-columns-regexp
  "^  \\([-ldrwxgst]\\{10\\}\\) +\\([^ ]+\\) +\\([^ ]+\\) +\\([^ ]+\\).*$"
  "Description of `diredc' line that we will parse for sorting by
  chmod, owner, or group. See function `diredc-sort-or-edit'.")


;;
;;; Customization faces:

(defface diredc-face-chmod-font-lock-dir   '((t :foreground "cyan"))
  "Face for chmod directory bits in dired buffers.
Applicable when variable `diredc-bonus-configuration' is non-nil."
  :group 'diredc)

(defface diredc-face-chmod-font-lock-read  '((t :foreground "blue"))
  "Face for chmod readable bits in dired buffers.
Applicable when variable `diredc-bonus-configuration' is non-nil."
  :group 'diredc)

(defface diredc-face-chmod-font-lock-write '((t :foreground "yellow"))
  "Face for chmod writable bits in dired buffers.
Applicable when variable `diredc-bonus-configuration' is non-nil."
  :group 'diredc)

(defface diredc-face-chmod-font-lock-exec  '((t :foreground "red"))
  "Face for chmod executable bits in dired buffers.
Applicable when variable `diredc-bonus-configuration' is non-nil."
  :group 'diredc)

(defface diredc-hl-current-buffer '((t :inherit 'hl-line :bold t))
  "Face for current line in selected buffer.
Applicable when variable `diredc-bonus-configuration' is non-nil.
See also `hl-line-mode'."
  :group 'diredc)

(defface diredc-header-line
 '((((class color) (background light))
       (:background "white"))
   (((class color) (background dark))
       (:background "black")))
  "Face remapping for the header line."
  :group 'diredc)

(defface diredc-header-*-marks
 '((((class color) (background light))
       (:foreground "blue"))
   (((class color) (background dark))
       (:foreground "brightcyan")))
  "Face for default marks' summary in header line."
  :group 'diredc)

(defface diredc-header-D-marks
 '((((class color) (background light))
       (:foreground "darkred" :bold t))
   (((class color) (background dark))
       (:foreground "color-197")))
  "Face for deletion marks' summary in header line."
  :group 'diredc)


;;
;;; Customization variables:

(defgroup diredc nil
  "Settings for the dired-commander suite of packages."
  :group 'dired
  :prefix "diredc-")

(defcustom diredc-allow-duplicate-buffers t
  "Allow multiple `dired' buffers to visit the same directory.

This must be set NON-NIL for `diredc' to work properly, and
evaluating \\<global-keymap> \\[diredc] sets this variable
non-nil for the session."
  :type 'boolean
  :group 'diredc)

(defcustom diredc-bookmarks '()
  "List of bookmarked directories for `diredc'.
Each entry is a CONS, whose CAR is a directory, and whose CDR is
a short descriptive string.

See also functions `diredc-bookmark-add' and
`diredc-bookmark-jump'."
  :type '(repeat (cons (directory :tag "Directory to bookmark")
                       (string    :tag "Description / Annotation")))
  :group 'diredc)

(defcustom diredc-hist-select-without-popup nil
  "Function `dir-hist-select' should never use package `popup'."
  :type 'boolean
  :group 'diredc)

(defcustom diredc-shell-guess-fallback '("xdg-open")
  "Universal fallback suggested command(s).

This offers a final option if no matching regex is found in
either `dired-guess-shell-alist-default' or
`dired-guess-shell-alist-default'.

The value is a list of COMMAND where each COMMAND can either be a
string or a Lisp expression that evaluates to a string. If this
expression needs to consult the name of the file for which the
shell commands are being requested, it can access that file name
as the variable `file'. If several COMMANDs are given, the first
one will be the default and the rest will be added temporarily to
the history and can be retrieved with \\<minibuffer-local-map>
\\[previous-history-element].

IMPORTANT: This feature requires function `dired-guess-default'
be advised by `diredc--advice--shell-guess-fallback', as follows:

  (advice-add 'dired-guess-default
              :around #'diredc--advice--shell-guess-fallback)

It may have already been done for you. In order to undo it,
perform:

  (advice-remove 'dired-guess-default
                 #'diredc--advice--shell-guess-fallback)"
  :type '(repeat sexp)
  :group 'diredc)

(defcustom diredc-display-listing-switches-list
    '(("classic long" . "-aFlv --group-directories-first --time-style=long-iso")
      ("long, derefernce links, K sizes" . "-aFlv --block-size=K --group-directories-first")
      ("long, inode, uid/gid, M sizes" . "-aFinlv  --block-size=M --group-directories-first")
      ("long, sort by extension" .       "-aFlvX --group-directories-first"))
;     ("classic ls-dired" . "-D")
;     ("long, no group, K sizes" . "-oL")
;     ("long, security context" . "-alZ")

"How to display a `dired' buffer.
This is merely a list of values suitable for defcustom
`dired-listing-switches', so see there for all the gory details.
Also see the `man' page for `ls'."
  :type '(repeat (cons (string :tag "Description")
                       (string :tag "Listing switches")))
  :group 'diredc)

(defcustom diredc-show-more-file-info-list
  '(("Don't display any additional information" . "")
    ("Extended Access Control List" . "getfacl -s '%s'")
    ("Stat command details"         . "stat '%s'")
    ("Extended file attributes"     . "getfattr '%s'"))
;;  ("Image metadata"               . "exif '%s'")
;;  ("Image metadata"               . "exiftool '%s'")
  "Shell commands to be used to display additional information for a file.
Each element of the list is a CONS whose CAR is a descriptive
string, and whose CDR is the text string of a shell command with
the file's name replaced with \"%s\". See command `diredc-show-more-file-info'."
  :type '(repeat (cons (string :tag "Description")
                       (string :tag "Command")))
  :group 'diredc)

(defcustom diredc-display-select-without-popup nil
  "Function `diredc-display-select' should never use package `popup'."
  :type 'boolean
  :group 'diredc)

(defcustom diredc-shell-lines 15
  "Number of lines for a `diredc' shell window."
  :type 'integer
  :group 'diredc)

(defcustom diredc-shell-list
  '(("POSIX shell"                  diredc-shell--launch-shell "/bin/sh")
    ("bash shell"                   diredc-shell--launch-shell "/bin/bash")
    ("zsh shell"                    diredc-shell--launch-shell "/bin/zsh")
    ("eshell"                       diredc-shell--launch-eshell "")
    ("POSIX dumb terminal-emulator" diredc-shell--launch-term "/bin/sh")
    ("bash dumb terminal-emulator"  diredc-shell--launch-term "/bin/bash")
    ("zsh dumb terminal-emulator"   diredc-shell--launch-term "/bin/zsh")
    ("POSIX ansi terminal-emulator" diredc-shell--launch-term "/bin/sh")
    ("bash ansi terminal-emulator"  diredc-shell--launch-term "/bin/bash")
    ("zsh ansi terminal-emulator"   diredc-shell--launch-term "/bin/zsh"))
  "Shell options to offer to the user.
Each item of the list must have three elements: A description
string; A launch function, and; A path string to the desired shell
executable. The launch function should return the shell's buffer,
and should accept seven string arguments: A path string to the
desired shell executable; the current dired directory ('$d1'); a
possible second dired directory ('$d2'); a possible current
file ('$f1'); a possible file in the other dired
directory ('$f2'); a possible list of tagged files in the current
dired directory ('$t1'); and a possible list of tagged files in
the other dired directory ('$t2')."
  :type '(repeat (list (string :tag "Description")
                       (function  :must-match t :tag "Function")
                       (file :must-match t :tag "Shell executable")))
  :group 'diredc)

(defcustom diredc-shell-default "POSIX shell"
  "Default shell to launch from a `dired' buffer.
NIL means always prompt the user to choose. Otherwise, the value
is a string that must match an entry in `diredc-shell-list'."
  :type  (let ((result (mapcar
                         (lambda (x) (list 'const (car x)))
                         diredc-shell-list)))
           (push 'radio result)
           result)
  :group 'diredc)

(defcustom diredc-browse-exclude-file-extensions (list "^db$" "^docx$")
  "Regexps for filename extensions of files not to be browsed.

Example: For a tar file, the use form  ^tar$, not .tar

This is useful to avoid displaying unnecessary garbage buffers
when using `diredc-browse-mode'. See also the related
customization variables `diredc-browse-exclude-coding-systems'
and `diredc-browse-exclude-helper'.

Setting this variable isn't expected to be necessary, as all
cases ought to be caught by the settings for
`diredc-browse-exclude-coding-systems'."
  :type '(repeat string)
  :group 'diredc)

(defcustom diredc-browse-exclude-coding-systems
  '(binary no-conversion no-conversion-multibyte)
  "Coding systems of files not to be browsed.
This is useful to avoid displaying unnecessary garbage buffers
when using `diredc-browse-mode'. See also the related
customization variables `diredc-browse-exclude-coding-systems'
and `diredc-browse-exclude-helper'."
  :type '(repeat coding-system)
  :group 'diredc)

(defcustom diredc-browse-exclude-helper
  ;; FIXME: Only tested for (eq system-type 'gnu/linux). Please submit
  ;;        corrections or additions.
  (list
    (list 'gnu          "/usr/bin/file" "-bi" "\\<text\\>" "/usr/bin/file" "-bi" "\\<ELF\\>\\|\\<binary\\>")
    (list 'gnu/linux    "/usr/bin/file" "-bi" "\\<text\\>" "/usr/bin/file" "-bi" "\\<ELF\\>\\|\\<binary\\>")
    (list 'gnu/kfreebsd "/usr/bin/file" "-bi" "\\<text\\>" "/usr/bin/file" "-bi" "\\<ELF\\>\\|\\<binary\\>")
    (list 'darwin       "/usr/bin/file" "-bi" "\\<text\\>" "/usr/bin/file" "-bi" "\\<ELF\\>\\|\\<binary\\>")
    (list 'cygwin       "/usr/bin/file" "-bi" "\\<text\\>" "/usr/bin/file" "-bi" "\\<ELF\\>\\|\\<binary\\>")
    (list 'ms-dos       "" "" "" "" "" "")
    (list 'windows-nt   "" "" "" "" "" ""))
  "External helper programs to determine files not to be browsed.
This is useful to avoid displaying unnecessary garbage buffers
when using `diredc-browse-mode'. See also the related
customization variables `diredc-browse-exclude-file-extensions'
and `diredc-browse-exclude-coding-systems.'

Each element of this list is itself a list of one symbol and six
strings: 1) The emacs variable `system-type' for this element; 2)
The inclusion helper command; 3) Any parameters for the command;
4) The regex of the command's desired output; 5) The exclusion
helper command; 6) Any parameters for the command; 7) The regex
of the command's desired output.

Mode `diredc-browse-mode' applies the inclusion test, and only if
that fails applies the exclusion test.

The default value includes all files recognized by the system
command as \"text\" and excludes all recognized as
\"ELF\" (executable and linkable)."
  :type '(repeat (list (sexp   :tag "Emacs system type")
                 (file :must-match t :tag "Inclusion helper command")
                 (string :tag "Inclusion command's parameters") ;
                 (string :tag "Inclusion command's desired output")
                 (file :must-match t :tag "Exclusion helper command")
                 (string :tag "Exclusion command's parameters")
                 (string :tag "Exclusion command's desried output")))
  :group 'diredc)

(defcustom diredc-async-processes-are-persistent t
  "Whether spawned asynchronous processes out-live Emacs.
When non-NIL, asynchronous processes spawned via
`dired-do-async-shell-command' will survive even after exiting
Emacs. However, because *Async Shell Command* buffers will not be
spawned, STDOUT and STDERR for the process will be lost.

Even when this variable is non-NIL, the non-persistent behavior
can be chosen at run-time by prefixing the process command with a
SPACE, thus spawning an *Async Shell Command* buffer and logging
there STDOUT and STDERR for the process. See
`diredc-do-async-shell-command'."
  :type 'boolean
  :group 'diredc)

(defcustom diredc-bonus-configuration t
  "Supplemental configuration for `diredc' buffers.

Dired was developed more than 25 years ago. Around it have
developed very many configuration options and also very many
opinions about those options. Setting this variable non-nil
enables those options that the `diredc' developer feels are sane
and desirable for a newcomer to `dired'. For exactly what it
does, see function `diredc-bonus-configuration'."
  :type 'boolean
  :group 'diredc)


(defcustom diredc-sort-prefix-ascending  ""
  "Mode line indicator for sort direction.
This is one of a set of four related customizable variables:
`diredc-sort-prefix-ascending', `diredc-sort-suffix-ascending',
`diredc-sort-prefix-descending', and
`diredc-sort-suffix-descending'."
  :type 'string
  :group 'diredc)

(defcustom diredc-sort-suffix-ascending  "↑"
  "Mode line indicator for sort direction.
This is one of a set of four related customizable variables:
`diredc-sort-prefix-ascending', `diredc-sort-suffix-ascending',
`diredc-sort-prefix-descending', and
`diredc-sort-suffix-descending'."
  :type 'string
  :group 'diredc)

(defcustom diredc-sort-prefix-descending ""
  "Mode line indicator for sort direction.
This is one of a set of four related customizable variables:
`diredc-sort-prefix-ascending', `diredc-sort-suffix-ascending',
`diredc-sort-prefix-descending', and
`diredc-sort-suffix-descending'."
  :type 'string
  :group 'diredc)

(defcustom diredc-sort-suffix-descending "↓"
  "Mode line indicator for sort direction.
This is one of a set of four related customizable variables:
`diredc-sort-prefix-ascending', `diredc-sort-suffix-ascending',
`diredc-sort-prefix-descending', and
`diredc-sort-suffix-descending'."
  :type 'string
  :group 'diredc)

(defcustom diredc-header-line t
  "Whether to display a header line.
This will summarize the number and size of marked items."
  :type 'boolean
  :group 'diredc)

(defcustom diredc-thousands-separator ","
  "How to divide long numbers for readability.
This is in lieu of getting the information from environment
variable LC_NUMERIC."
  ;; ref: https://lists.gnu.org/archive/html/emacs-devel/2021-06/msg00139.html
  :type 'string
  :group 'diredc)


;;
;;; Buffer-local variables:

(defvar-local diredc-hist--history-list (list (list (expand-file-name default-directory)
                                                    (point)
                                                    dired-omit-mode))
  "Internal variable for `diredc-history-mode' minor mode.

A buffer-local list of directories visited. Each element of the
list contains three elements: 1) a directory name; 2) a return
POINT within that buffer, and; 3) a state for mode
`dired-omit-mode'.")
;; TODO: Storing a POINT for a return position isn't perfect; it will
;; yield 'wrong' results if the buffer's contents change, eg. the `ls'
;; display switches change, or entries are added / deleted.

(defvar-local diredc-hist--history-position 0
  "Internal variable for `diredc-history-mode' minor mode.

A buffer-local index of current position within `diredc-hist--history-list'.")

(defvar-local diredc-browse--buffer nil
  "Internal variable for buffers created by `diredc-browse-mode'.

Set to NON-NIL to indicate that the buffer was created by
`diredc-browse-mode'. This variable was created for use by
functions `diredc-frame-exit' and `diredc-frame-recover', but
might also be used by others.

The value is the `diredc' WINDOW from which the buffer was
created.")

(defvar-local diredc-browse-mode nil
  "Whether a `diredc-mode' buffer is browsing files at POINT.
This is an internal variable for `diredc-mode' buffers. Do not
manipulate it directly. See function `diredc-browse-mode'.")

(defvar-local diredc-shell--bufwin nil
  "Internal variable for `diredc-shell'.
Window from which the current `diredc-shell' buffer was created.")

(defvar-local diredc--hl-cookie nil
  "Internal variable for `diredc-bonus-configuration'.
When non-nil, contains a face-remapping cookie for the current
buffer's `hl-line' face. See function
`face-remap-add-relative'.")

(defvar-local dired-aux-files nil
  "Variable requiring definition for package `dired-aux'.
It is used by function `dired-read-shell-command' which `diredc'
advises with function `diredc--advice--dired-read-shell-command'.")

(defvar-local diredc--sort-option-special nil
  "Whether the sort option uses 'ls' switches or a `diredc' method.
If the sort option uses a `diredc' method, then the value is the
method entry in variable `diredc--sort-options'. Otherwise, it
should be NIL.")


;;
;;; Global variables:

(defvar diredc-mode nil
  "Whether `diredc' extensions to `dired' are globally enabled.

Don't ever set this variable directly! Instead, evaluate function
`diredc-mode'.")

(defvar diredc-history-mode nil
  "Whether to globally enable dired buffer navigation histories.

Don't ever set this variable directly! Instead, evaluate function
`diredc-history-mode'. Note that when option `diredc-mode' is
installed, that this mode will always be updated to follow its
change of state.")

(defvar diredc-recover-schemes
  '((0 ; no `dired' buffers found
     ("create-two" .
      (lambda (buffer-list)
       (dired "~")
       (other-window 1)
       (dired "~"))))
    (1 ; one `dired' buffer found
     ("create-one-display-both" .
      (lambda (buffer-list)
       (switch-to-buffer (pop buffer-list))
       (other-window 1)
       (dired "~"))))
    (2 ; two `dired' buffers found
     ("display-both" .
      (lambda (buffer-list)
        (cond
         ((memq (current-buffer) buffer-list)
           (setq buffer-list (remq (current-buffer) buffer-list))
           (other-window 1)
           (when (not (memq (current-buffer) buffer-list))
             (switch-to-buffer (pop buffer-list))))
         (t
           (other-window 1)
           (if (memq (current-buffer) buffer-list)
             (setq buffer-list (remq (current-buffer) buffer-list))
            (switch-to-buffer (pop buffer-list)))
           (other-window -1)
           (switch-to-buffer (pop buffer-list)))))))
    (3 ; three or more `dired' buffers found
     ("keep-all" .
      (lambda (buffer-list)
        (switch-to-buffer (nth 0 buffer-list))
        (switch-to-buffer-other-window (nth 1 buffer-list))))
     ("kill-all-and-start-anew" .
      (lambda (buffer-list)
        (switch-to-buffer (nth 0 buffer-list))
        (switch-to-buffer-other-window (nth 1 buffer-list))
        (while buffer-list
          (kill-buffer (pop buffer-list)))
         (dired "~")
         (other-window 1)
         (dired "~")))
     ("select-two" .
      (lambda (buffer-list)
        (setq buffer-list
          (mapcar
            (lambda (x)
              (cons (with-current-buffer x dired-directory) x))
            buffer-list))
        (dolist (num '("first" "second"))
          (setq decision nil)
          (while (or (not decision)
                     (zerop (length decision)))
            (setq minibuffer-history '(""))
            (setq decision
              (completing-read
                (format "select %s buffer to keep: " num)
                (mapcar 'car buffer-list) nil t)))
          (setq decision (assoc decision buffer-list))
          (switch-to-buffer (cdr decision))
          (setq buffer-list (remq decision buffer-list))
          (other-window 1))
        (while buffer-list
          (kill-buffer (cdr (pop buffer-list))))))))
  "Strategies for recovering `dired' environments.

A list of sub-lists. The CAR of each sub-list is a number
corresponding to number of existing `dired' buffers their
contents are applicable, and this number should correspond to the
element's position in the list, beginning with zero.

The remainder of each sub-list is a collection of CONS, where
each CAR is a string description / strategy name, and each CDR is
a function to perform. The function should accept a single
variable, which is a list of existing `dired' buffers.

If a sub-list contains no CONS elements, no action is performed
for that scenario; if only a single CONS exists, that action is
performed without prompting the user. The strategies of the final
sub-list will be used for scenarios of that many or greater
number of existing `dired' buffers.")

(defvar diredc-browse--tracker '(nil . nil)
  "Internal variable for option `diredc-browse-mode' minor mode.

A CONS whose CAR is the most recent file browsed, and whose CDR
is that file's buffer.")

(defvar diredc--show-more-file-info-index 0
  "Current position in `diredc-show-more-file-info-list'.
Internal variable for `diredc'. An integer, beginning at zero.")

(defvar diredc--show-more-file-info-cmd ""
  "Current command string to be used to show additional file info.
Internal variable for `diredc'.")

(defvar diredc--lc-collate-original-value nil
  "The original value of environment variable `LC_COLLATE'.
As found by `diredc' when started.")


;;
;;; Functions - inline functions:

(defsubst diredc--match-command (cmd)
  "Match a command from  a `shell-command' string.
This is mainly here to ensure uniformity of the regexp."
  ;; NOTE: The atom \\\\? is to account for a leading '\' used to
  ;;       over-ride shell-aliases.
  (string-match "^ *\\\\?\\([^ ]+\\)" cmd))

(defsubst diredc--set-omit-mode (yes)
  "Set mode `dired-omit-mode' based upon value of YES."
  (dired-omit-mode (if yes 1 -1)))

(defsubst diredc--swap-browse-buffer (w1 w2)
  "Swap browse-buffer window IDs.
This is an internal function for `diredc', meant to be called by
function `diredc-swap-windows'."
  (when diredc-browse--buffer
    (setq diredc-browse--buffer
      (cond ((eq diredc-browse--buffer w2) w1)
            ((eq diredc-browse--buffer w1) w2)
            (t (error "Diredc browse buffer window mis-match"))))))


;;
;;; Functions - advice functions:

(defun diredc--advice--wdired-exit ()
  "Ensure correct keymap when returning from wdired."
  (when diredc-mode
    (diredc-bonus-configuration 'dired-mode-hook)
    (when diredc-history-mode
      (diredc--set-omit-mode
        (nth 2 (nth diredc-hist--history-position diredc-hist--history-list))))
    (use-local-map diredc-mode-map)))

(defun diredc--advice--shell-guess-fallback (_oldfun files)
  "Offer universal fallback suggested command(s) for `dired-do-shell-command'.

OLDFUN is function `dired-guess-default', which is never called by this advice.
FILES are defined there.

Usage: (advice-add 'dired-guess-default
                   :around #'diredc--advice--shell-guess-fallback)

This advice addresses the issues in Emacs bug report and patch #48071
(http://debbugs.gnu.org/cgi/bugreport.cgi?bug=48071) and also
implements diredc feature `diredc-shell-guess-fallback'."
  (let* ((case-fold-search dired-guess-shell-case-fold-search)
         ;; Prepend the user's alist to the default alist.
         (alist (append dired-guess-shell-alist-user
                        dired-guess-shell-alist-default
                        (list (list ".*" (car diredc-shell-guess-fallback)))))
         regexp cmds)
    (cl-loop
      for elt in alist
      do (setq regexp (car elt))
         (cl-loop
           for file in files
           always (string-match-p regexp file)
           finally
             (cl-loop
               for cmd in (cdr elt) do
               (unless (stringp cmd)
                 (setq cmd (condition-case nil
                             (funcall cmd `((file . ,file)))
                             (error nil))))
               (and (stringp cmd)
                    (executable-find
                      (if (diredc--match-command cmd)
                        (match-string 1 cmd)
                       cmd))
                    (push cmd cmds)))))
    (nreverse (delete-dups cmds))))

(defun diredc--advice--dired-internal-noselect (_oldfun dir-or-list &optional switches mode)
  "Diredc advice to function `dired-internal-noselect'.
_OLDFUN is function `dired-internal-noselect'. Args DIR-OR-LIST,
SWITCHES, and MODE are as defined there.

This function replaces the Emacs standard function in order to
change a single line in order to allow multiple `dired' buffers
to be visiting the same directory.

See also: Emacs bug report #44023:
          https://debbugs.gnu.org/cgi/bugreport.cgi?bug=44023"
;; IMPORTANT: This is good for emacs 26.1, 27.1, 28.0(snapshot 2020-09)
;; TODO: emacs 25.1, emacs 27.1
  (let* ((old-buf (current-buffer))
	 (dirname (if (consp dir-or-list) (car dir-or-list) dir-or-list))
       ;; BEGIN modification
       ;;(buffer (dired-find-buffer-nocreate dirname mode))
         (buffer (when (not (bound-and-true-p diredc-allow-duplicate-buffers))
                   (dired-find-buffer-nocreate dirname mode)))
       ;; END modification
	 (new-buffer-p (null buffer)))
    (or buffer
        (setq buffer (create-file-buffer (directory-file-name dirname))))
    (set-buffer buffer)
    (if (not new-buffer-p)		; existing buffer ...
	(cond (switches			; ... but new switches
	       ;; file list may have changed
	       (setq dired-directory dir-or-list)
	       ;; this calls dired-revert
	       (dired-sort-other switches))
	      ;; Always revert when `dir-or-list' is a cons.  Also revert
	      ;; if `dired-directory' is a cons but `dir-or-list' is not.
	      ((or (consp dir-or-list) (consp dired-directory))
	       (setq dired-directory dir-or-list)
	       (revert-buffer))
	      ;; Always revert regardless of whether it has changed or not.
	      ((eq dired-auto-revert-buffer t)
	       (revert-buffer))
	      ;; Revert when predicate function returns non-nil.
	      ((functionp dired-auto-revert-buffer)
	       (when (funcall dired-auto-revert-buffer dirname)
		 (revert-buffer)
		 (message "Changed directory automatically updated")))
	      ;; If directory has changed on disk, offer to revert.
	      ((when (dired-directory-changed-p dirname)
		 (message "%s"
			  (substitute-command-keys
			   "Directory has changed on disk; type \\[revert-buffer] to update Dired")))))
      ;; Else a new buffer
      (setq default-directory
            (or (car-safe (insert-directory-wildcard-in-dir-p dirname))
	        ;; We can do this unconditionally
	        ;; because dired-noselect ensures that the name
	        ;; is passed in directory name syntax
	        ;; if it was the name of a directory at all.
	        (file-name-directory dirname)))
      (or switches (setq switches dired-listing-switches))
      (if mode (funcall mode)
        (dired-mode dir-or-list switches))
      ;; default-directory and dired-actual-switches are set now
      ;; (buffer-local), so we can call dired-readin:
      (let ((failed t))
	(unwind-protect
	    (progn (dired-readin)
		   (setq failed nil))
	  ;; dired-readin can fail if parent directories are inaccessible.
	  ;; Don't leave an empty buffer around in that case.
	  (if failed (kill-buffer buffer))))
      (goto-char (point-min))
      (dired-initial-position dirname))
    (when (consp dired-directory)
      (dired--align-all-files))
    (set-buffer old-buf)
    buffer))

(defun diredc--advice--dired-run-shell-command (_oldfun command)
  "Optionally allow spawned asynchronous processes to out-live Emacs.
See variable `diredc-async-processes-are-persistent' and function
`diredc-do-async-shell-command'.

OLDFUN is function `dired-run-shell-command' and is never called
by this advice. COMMAND is an entire shell command string. For
asynchronous commands, `dired' prepares COMMAND to end with
\"&wait&\" without a space prior.

Usage: (advice-add 'dired-run-shell-command
                   :around #'diredc--advice--dired-run-shell-command)"
;; NOTE: The advised function is reached via `dired-do-shell-command'
;; which calls it indirectly via `dired-bunch-files' if `on-each' (ie.
;; apply the function separately for each of a list of files).
;; Regardless, the command and file-list are passed through
;; `dired-shell-stuff-it' prior.
  (cond
   ((or (not diredc-async-processes-are-persistent)
        (string-match "^ " command)
        (not (string-match "&wait&$" command)))
   ;; NOTE: This condition is itself a rewrite of the advised function, to
   ;;       use function `start-process-shell-command' instead of `shell-command'.
   ;;       (defun dired-run-shell-command (command)
     (let ((command (list (replace-regexp-in-string "&wait&$" " " command)))
           (handler (find-file-name-handler
                      (directory-file-name default-directory)
                      'shell-command)) ; <- May need to be start-process?
           (proc-name "*Async Shell Command*")
           (proc-buf  (get-buffer-create "*Async Shell Command*")))
       (if handler
         (apply handler 'start-process-shell-command proc-name proc-buf command)
        (apply 'start-process-shell-command proc-name proc-buf command))))
   (t ; Using diredc's home-made persistent async process feature
     (setq command (replace-regexp-in-string "&wait&$" " " command))
     (let* ((win (selected-window))
            (buf (shell))
            (kill-buffer-query-functions nil)
            (cmd (when (diredc--match-command command)
                   (match-string 1 command)))
            (separator (when cmd (concat " & " cmd)))
            (cmds (when separator (split-string command separator)))
            (suffix " & disown"))
       (if (eq win (selected-window))
         (bury-buffer)
        (delete-window)
        (select-window win 'no-record))
       (with-current-buffer buf
         (when cmds
           (setq command (pop cmds)))
         (insert command suffix)
         (comint-send-input)
         (while (setq command (pop cmds))
           (insert cmd command suffix)
           (comint-send-input))
         (sit-for 0.3 'nodisp)
         (kill-buffer)))))
   ;; Return nil for sake of `nconc' in `dired-bunch-files'.
   nil)

(defun diredc--advice--dired-read-shell-command (_oldfun prompt arg files)
  "Validate input to `dired-read-shell-command'.
OLDFUN is function `dired-read-shell-command', which is never
called by this advice. PROMPT, ARG, and FILES are described
there.

Inputs must be non-empty and valid commands on the host system.
These two validation checks address the issues in Emacs bug
report and patch #48072
\(http://debbugs.gnu.org/cgi/bugreport.cgi?bug=48072).

Note that function `diredc-do-async-shell-command' still needs to
locally define `dired-read-shell-command'. See there."
  (minibuffer-with-setup-hook
      (lambda ()
        (setq-local dired-aux-files files)
        (setq-local minibuffer-default-add-function
                    #'minibuffer-default-add-dired-shell-commands))
    (setq prompt (format prompt (dired-mark-prompt arg files)))
    (let (command)
      (setq command
        (if (functionp 'dired-guess-shell-command)
          (dired-mark-pop-up nil 'shell files
                             'dired-guess-shell-command prompt files)
         (dired-mark-pop-up nil 'shell files
                            'read-shell-command prompt nil nil)))
      ;; Validation checks of #48072:
      (when (string= "" command)
        (user-error "No command entered. Nothing to do!"))
      (unless (executable-find
                (if (diredc--match-command command)
                  (match-string 1 command)
                 command))
        (user-error "Not a valid command!"))
      command)))

(defun diredc--advice--repeat-over-lines (_oldfun arg function)
  "Fix Emacs bug #48883 (2021-06-06: improper marking of lines).

_OLDFUN is function `dired-repeat-over-lines', which is never
called by this advice. ARG is a positive or negative integer
number of lines on which to operate, and FUNCTION is the
operation to perform.

Ref: http://debbugs.gnu.org/cgi/bugreport.cgi?bug=48883

The advised function was: 1) operating on directory heading
lines; 2) operating on the lines for the \"not-real\" files '.'
and ',,', and; 3) advancing POINT undesirablly. I submitted two
solutions there. Here in `diredc', in order to limit advising the
underlying Emacs package, I'm using the version that alters just
function `dired-repeat-over-lines'. A second version submitted
there applies the fix by changing also function
`dired-between-two-lines'."
  (let ((pos (make-marker)))
    (beginning-of-line)
    (cond
     ((> arg 0)
       (while (and (> arg 0) (not (eobp)))
         (setq arg (1- arg))
         (beginning-of-line)
       ;;(while (and (not (eobp)) (dired-between-files)) (forward-line 1))
         (while (and (not (eobp))
                     (condition-case nil
                       (not (dired-get-filename))
                       (error t)))
           (forward-line 1))
         (save-excursion
           (forward-line 1)
           (move-marker pos (1+ (point))))
         (unless (eobp)
           (save-excursion (funcall function))
           ;; Advance to the next line--actually, to the line that *was* next.
           ;; (If FUNCTION inserted some new lines in between, skip them.)
           (goto-char pos)))
       (when (eobp)
         (forward-line -1)
         (dired-move-to-filename)))
     ((< arg 0)
       (while (and (< arg 0) (not (bobp)))
         (setq arg (1+ arg))
         (forward-line -1)
       ;;(while (and (not (bobp)) (dired-between-files)) (forward-line -1))
         (while (and (not (bobp))
                     (condition-case nil
                       (not (dired-get-filename))
                       (error t)))
           (forward-line -1))
         (beginning-of-line)
         (when (condition-case nil
                 (dired-get-filename)
                 (error nil))
           (save-excursion (funcall function))))
       (move-marker pos nil)
       (dired-move-to-filename)))))


;;
;;; Functions - hook functions:

(defun diredc--hook-function ()
  "Hook function for `dired-mode-hook'."
  (cond
   (diredc-mode
     (use-local-map diredc-mode-map)
     (setq header-line-format (if diredc-header-line "  Diredc:" ""))
     (when diredc-header-line
       (make-local-variable 'face-remapping-alist)
       (push (cons 'header-line 'diredc-header-line)
             face-remapping-alist))
     (diredc-bonus-configuration 'dired-mode-hook)
     (advice-add 'wdired-finish-edit   :after #'diredc--advice--wdired-exit)
     (advice-add 'wdired-abort-changes :after #'diredc--advice--wdired-exit)
     (advice-add 'wdired-exit          :after #'diredc--advice--wdired-exit)
     (add-hook 'post-command-hook
               #'diredc--hook-function--post-command))
   (t ; not diredc-mode
     (advice-remove 'wdired-finish-edit   #'diredc--advice--wdired-exit)
     (advice-remove 'wdired-abort-changes #'diredc--advice--wdired-exit)
     (advice-remove 'wdired-exit          #'diredc--advice--wdired-exit)
     (remove-hook 'post-command-hook
                  #'diredc--hook-function--post-command))))

(defun diredc-hist--hook-function ()
  "Hook function for `dired-mode-hook'."
  (setq diredc-hist--history-position 0
        diredc-hist--history-list
          (list (list (expand-file-name dired-directory)
                      (point)
                      dired-omit-mode))))

(defun diredc--hook-function--post-command ()
  "Internal hook function for `diredc-mode' file buffers.

A hook function for `post-command-hook', to display additional
file information in the minibuffer area for the current file at
POINT."
  (cond
   ((or (minibuffer-window-active-p (selected-window))
        (not (eq major-mode 'dired-mode))))
   (t
     (if diredc-header-line
       (diredc--report-counts-and-sizes)
      (setq header-line-format nil))
     (cond
      ((equal (expand-file-name dired-directory)
              diredc-trash-files-dir)
        (diredc-trash--show-more-file-info--freedesktop))
      ((diredc--file-name-at-point)
        (diredc--show-more-file-info))))))

(defun diredc-browse--hook-function ()
  "Internal function for `diredc-browse-mode' minor mode.

A hook function for `post-command-hook'. It creates and kills
`view-mode' buffers for `diredc-browse-mode'."
  (unless (or diredc-browse--buffer
              (minibuffer-window-active-p (selected-window))
              (not (string-match "#<frame diredc " (format "%s" (selected-frame))))
              (eq this-command 'push-button))
    (let ((original-win (selected-window))
          (new-file (condition-case nil
                      (dired-get-filename nil t)
                      (error nil)))
          (browse-buf (cdr diredc-browse--tracker)))
      (unless (and new-file
                   (equal new-file (car diredc-browse--tracker)))
        (unless (buffer-live-p browse-buf)
          (setq browse-buf (get-buffer-create "diredc browse"))
          (let ((w-list (window-list))
                w done)
            (while (and (not done)
                        (setq w (pop w-list)))
              (when (not (eq w original-win))
                (select-window w 'norecord)
                (when (eq major-mode 'dired-mode)
                  (setq done t))))
            (when (not done)
              (split-window-right)
              (other-window 1))
            (set-window-dedicated-p nil nil)
            (switch-to-buffer browse-buf 'norecord 'force-same-window)
            (set-window-dedicated-p nil t)
            (setq diredc-browse--buffer original-win)))
        (setq diredc-browse--tracker (cons new-file browse-buf))
        (set-buffer browse-buf)
        (setq header-line-format
          (format "Diredc browse buffer%s"
                  (if new-file (concat ": " (file-name-nondirectory new-file)) "")))
        (let ((inhibit-read-only t))
          (cond
           ((and new-file
                 (file-regular-p new-file)
                 (file-readable-p new-file)
                 (not (file-symlink-p new-file)))
             (unless (diredc-browse--exclude new-file)
               (condition-case err
                 (insert-file-contents new-file nil nil nil 'replace)
                 (error
                   (erase-buffer)
                   (insert (concat "diredc browse buffer\n\n Error looking at file: "
                                   (format "%s\n\n %s: %s" new-file (car err) (cdr err))))
                   (dolist (w (window-list))
                     (when (not (eq w original-win))
                       (select-window w 'norecord)
                       (unless (or  (eq major-mode 'dired-mode)
                                    (equal "diredc browse" (buffer-name))
                                    (string-match "^*diredc-shell " (buffer-name)))
                         (delete-window))))))))
           (t
             (erase-buffer)
             (let ((type (car (file-attributes new-file))))
               (insert   (cond
                          ((stringp type)
                            (format "Looking at a symbolic link to:\n\n   %s" type))
                          (type
                            (format "Looking at a directory"))
                          (t ;; ie. (eq type nil)
                            (if (not new-file)
                              "Looking at nothing"
                             (format "Looking at an unreadable file")))))))))
        (buffer-disable-undo)
        (view-mode)
        (use-local-map diredc-browse-mode-map)
        (select-window original-win 'norecord)))))

(defun diredc--window-state-change-hook-function (fram)
  "Internal function for mode `diredc-mode'.
When variable `diredc-bonus-configuration' is non-nil, this
function allows the current line of the selected `diredc' buffer
to be highlighted in a face independent of face `hl-line'. See
face `diredc-hl-current-buffer'."
   (when (and diredc-mode diredc-bonus-configuration
            (string-match "^#<frame diredc "
                          (format "%s" (window-frame))))
     (let* ((win-list (window-list fram)))
       (with-selected-window (pop win-list)
         (unless diredc--hl-cookie
           (setq-local diredc--hl-cookie
             (face-remap-add-relative 'hl-line 'diredc-hl-current-buffer)))
         (dolist (win win-list)
           (select-window win 'no-record)
           (when diredc--hl-cookie
             (face-remap-remove-relative diredc--hl-cookie)
             (setq diredc--hl-cookie nil)))))))


;;
;;; Functions:

(defun diredc--thousands (num)
  "Return a readable string for integer NUM.
Delimits the number by variable `diredc-thousands-separator'.
Used by function `diredc--report-counts-and-sizes'."
  ;; ref: https://lists.gnu.org/archive/html/emacs-devel/2021-06/msg00139.html
  (setq num (number-to-string num))
  (while (string-match "\\(.*[0-9]\\)\\([0-9][0-9][0-9].*\\)" num)
  (setq num
    (concat
      (match-string 1 num)
      diredc-thousands-separator
      (match-string 2 num))))
    num)

(defun diredc--mark-msg (label file-count dir-count link-count size units1 units2)
  "Returns summary of mark count and size.
For use of function `diredc--report-counts-and-sizes' in setting
variable `header-line-format'."
  (unless (and (zerop file-count)
               (zerop dir-count)
               (zerop link-count))
    (format " [%s: %s%s%s] "
      label
      (if (zerop file-count) ""
        (format "%s file%s (%s %s%sytes)"
                (diredc--thousands file-count)
                (if (= 1 file-count) "" "s")
                (diredc--thousands size)
                units1 units2))
      (if (zerop dir-count)  ""
        (format "%s%s dir%s"
                (if (zerop file-count) "" ", ")
                (diredc--thousands dir-count)
                (if (= 1 dir-count) "" "s")))
      (if (zerop link-count) ""
        (format "%s%s link%s"
                (if (and (zerop file-count)
                         (zerop dir-count)) "" ", ")
                (diredc--thousands link-count)
                (if (= 1 link-count) "" "s"))))))

(defun diredc--report-counts-and-sizes ()
  "Get total size of marked files.
This differs from `dired-number-of-marked-files' in that: 1) the
count of files, directories, and links are itemized; 2) the sizes
of links and directories are not reported; 3) the units of size
respects that of the dired listing, and; 4) the result is posted
to the header line.

This function is fragile in the sense that it expects the
`diredc' buffer to be presenting its first five fields in classic
'ls -l' format.

This function does not attempt to calculate the actual size of
directories (eg. by using shell command `du') because that can
many seconds for large subdirectory trees, and this function is
meant to be called as part of a `post-command-hook'. For that
feature, see interactive function `diredc-du'."
  ;; TODO: This can be performed as a summary for a directory, listing
  ;;       number of files (and sizes) by extension
  (let ((atoms ;; compare: diredc--sort-columns-regexp
         "^\\([*D]\\) \\([-ld]\\)\\([-rwxgst]\\{9\\}\\) +\\([^ ]+\\) +\\([^ ]+\\) +\\([^ ]+\\) +\\([0-9]+\\)\\([KMGTPEZY]\\)?\\(B\\)?.*$")
        (m-file-count 0) (m-link-count 0) (m-dir-count 0) (m-size 0)
        (d-file-count 0) (d-link-count 0) (d-dir-count 0) (d-size 0)
        (units1 "") (units2 "b")
        m-msg d-msg)
    (save-mark-and-excursion
      (goto-char (point-min))
      (while (re-search-forward atoms nil t)
        (when (match-string 8)
          (setq units1 (match-string 8))
          (when (match-string 9)
            (setq units2 (match-string 9))))
        (cond
         ((equal "*" (match-string 1))
           (cond
            ((equal "-" (match-string 2))
              (setq m-file-count (1+ m-file-count))
              (setq m-size  (+ m-size (string-to-number (or (match-string 7) 0)))))
            ((equal "d" (match-string 2))
              (setq m-dir-count (1+ m-dir-count)))
            ((equal "l" (match-string 2))
              (setq m-link-count (1+ m-link-count)))))
         (t ; (equal "D" (match-string 1))
           (cond
            ((equal "-" (match-string 2))
              (setq d-file-count (1+ d-file-count))
              (setq d-size  (+ d-size (string-to-number (or (match-string 7) 0)))))
            ((equal "d" (match-string 2))
              (setq d-dir-count (1+ d-dir-count)))
            ((equal "l" (match-string 2))
              (setq d-link-count (1+ d-link-count))))))))
    (setq m-msg
      (diredc--mark-msg "*" m-file-count m-dir-count m-link-count m-size units1 units2))
    (setq d-msg
      (diredc--mark-msg "D" d-file-count d-dir-count d-link-count d-size units1 units2))
    (setq header-line-format
      (concat "  Diredc: "
      ;;      (if (or m-msg d-msg) "Marks: " "")
              (propertize (or m-msg "") 'face 'diredc-header-*-marks)
              (propertize (or d-msg "") 'face 'diredc-header-D-marks)))))

(defun diredc--decode-hexlated-string (str)
  "Convert hexlated string STR to human-readable, with charset coding support.
This function improves upon `url-unhex-string' by handled
hexlated multi-byte and unicode characters."
  (decode-coding-string (url-unhex-string str)
                        (or file-name-coding-system
                            default-file-name-coding-system)))

(defun diredc--file-name-at-point ()
  "Wrapper for `dired-file-name-at-point' to suppress errors.

The wrapped function lacks a NOERROR arg, as is common in many
other Emacs functions."
  ;; WARNING: Do not confuse function `dired-file-name-at-point' with
  ;; function `dired-filename-at-point'. The latter truncates file
  ;; names at spaces, and possibly has other deficiencies.
  (condition-case nil
    (dired-file-name-at-point)
    (error nil)))

(defun diredc--sort-special (method)
  "Perform a sort on a `diredc' buffer.
This function handles sort methods that `dired' can't off-load to
the shell's `ls'. METHOD is an entry in variable
`diredc--sort-options' whose `column' value is non-NIL."
  (when (< 1 (length dired-subdir-alist))
    (user-error "Not supported for Dired buffers with sub-dirs"))
  (save-mark-and-excursion
    (save-match-data
      (goto-char (point-min))
      (unless (re-search-forward diredc--sort-columns-regexp nil t)
        (user-error "Incompatible Dired listing format"))
      (goto-char (point-min))
      (read-only-mode -1)
      (sort-regexp-fields
        (nth 2 method)
        diredc--sort-columns-regexp
        (nth 5 method)
        (line-beginning-position 3)
        (point-max))
      (read-only-mode)))
  (setq diredc--sort-option-special method))

(defun diredc-shell--array-variable (program val)
  "Internal function for use with variable `diredc-shell-list'.
PROGRAM is the shell executable to run, and VAL is the list of
tagged files in a `dired' buffer. Returns a string suitable for
function `diredc-shell--launch-shell' to pass possible array
variables to a shell."
  (if (member (file-name-nondirectory program) '("bash" "zsh"))
    (cond
     ((zerop (length val)) "")
     ((= 1 (length val)) (format "\"%s\"" (car val)))
     (t val))
   (format "\"%s\"" val)))

(defun diredc-shell--launch-shell (program d1 d2 f1 f2 t1 t2)
  "Internal function for use with variable `diredc-shell-list'.
PROGRAM is the shell executable to run. D1, D2, F1, F2, T1, and
T2 are shell variables to be set based upon their dired values.
If optional ANSI is NON-NIL, then the program is run in Emacs
`ansi-term'; Otherwise, the simple Emacs `term-mode' is used."
  (let ((explicit-shell-file-name program)
        (buf (get-buffer-create (format "*diredc-shell <%s>*" d1))))
    ;; `shell' performs its window selection differently than
    ;; `eshell', `term', or `ansi-term'
    (display-buffer-same-window
      buf (list nil)) ;; not sure what this last ARG is about (not documented).
    (shell buf)
    (insert (format "export d1=\"%s\" d2=\"%s\" f1=\"%s\" f2=\"%s\" t1=%s t2=%s\n"
                    d1 (or d2 "") (or f1 "") (or f2 "")
                    (diredc-shell--array-variable program t1)
                    (diredc-shell--array-variable program t2)))
    (comint-send-input)
    buf))

(defun diredc-shell--launch-eshell (_program d1 d2 f1 f2 t1 t2)
  "Internal function for use with variable `diredc-shell-list'.
_PROGRAM is an ignored placeholder for consistency with similar
functions. D1, D2, F1, F2, T1, and T2 are shell variables to be
set based upon their dired values."
  (let ((buf (eshell)))
    (setq-local d1 d1)
    (setq-local f1 f1)
    (setq-local t1 t1)
    (setq-local d2 d2)
    (setq-local f2 f2)
    (setq-local t2 t2)
    buf))

(defun diredc-shell--launch-term (program d1 d2 f1 f2 t1 t2)
  "Internal function for use with variable `diredc-shell-list'.
PROGRAM is the shell executable to run. D1, D2, F1, F2, T1, and
T2 are shell variables to be set based upon their dired values."
  (diredc-shell--launch-emulator program nil d1 d2 f1 f2 t1 t2))

(defun diredc-shell--launch-ansi-term (program d1 d2 f1 f2 t1 t2)
  "Internal function for use with variable `diredc-shell-list'.
PROGRAM is the shell executable to run. D1, D2, F1, F2, T1, and
T2 are shell variables to be set based upon their dired values."
  (diredc-shell--launch-emulator program t d1 d2 f1 f2 t1 t2))

(defun diredc-shell--launch-emulator (program ansi d1 d2 f1 f2 t1 t2)
  "Internal `dired-shell' function to launch a terminal emulator.
PROGRAM is what the terminal-emulator should run. D1, D2, F1, F2,
T1, and T2 are shell variables to be set based upon their dired
values. If optional ANSI is NON-NIL, then the program is run in
Emacs `ansi-term'; Otherwise, the simple Emacs `term-mode' is
used."
  (let ((buf (if ansi (ansi-term program) (term program))))
    (term-line-mode)
    (insert (format "export d1=\"%s\" d2=\"%s\" f1=\"%s\" f2=\"%s\" t1=%s t2=%s\n"
                    d1 (or d2 "") (or f1 "") (or f2 "")
                    (diredc-shell--array-variable program t1)
                    (diredc-shell--array-variable program t2)))
    (term-send-input)
    buf))

(defun diredc-shell--find-existing-shell ()
  "Internal function for `diredc-shell'.
If a shell window already exists, select it and return non-nil."
  (let ((original-window (selected-window))
        (w-list (window-list))
        (d1 dired-directory)
        w done)
    (while (and (not done)
                (setq w (pop w-list)))
      (select-window w 'norecord)
      (when (and (derived-mode-p 'comint-mode)
                 (equal (bound-and-true-p dired-directory) d1))
        (select-window w)
        (setq done t)))
    (when (not done)
      (select-window original-window 'norecord))
    done))

(defun diredc--guess-decoding (filename)
  "Guess the encoding system to be used to find FILENAME.
Returns a coding-system symbol. See variables
`auto-coding-alist', `file-coding-system-alist' and function
`find-operation-coding-system'."
  ;; NOTE: See also `mailcap-extension-to-mime' and related features
  ;; in `mailcap.el'
  (or (cl-loop
        for elem in auto-coding-alist
        when (string-match (car elem) filename)
        return (cdr elem))
      (cl-loop for elem in file-coding-system-alist
        when (string-match (car elem) filename)
        return
          (let ((val (cdr elem)))
            (cond
             ((consp val) (cdr val))
             ((functionp val)
               (if (consp (setq val
                            (funcall val (list 'insert-file-contents filename))))
                 (car val)
                val))
             (t val))))))

(defun diredc-browse--button-describe-action (button)
  "Perform `describe-variable' for the variable at BUTTON."
  (describe-variable (button-get button 'var)))

(defun diredc-browse--button-return-action (_button)
  "Navigate away from the diredc-browse window of BUTTON."
  (diredc-other-window))

(defun diredc-browse--exclude (filename)
  "Decide whether to browse readable file FILENAME.
Reports in the 'diredc browse' buffer any reason not to browse.
The file is checked against the values of variables
`diredc-browse-exclude-file-extensions' and
`diredc-browse-exclude-coding-systems'. If those checks pass,
variable `diredc-browse-exclude-helper' is used (see there)."
  (let ((ext (or (file-name-extension filename)
                 (file-name-nondirectory filename)))
        ext-match coding-match helper-match browse-binary)
    (when (or
            ;; check file extensions to exclude
            (setq ext-match
              (cl-loop for elem in diredc-browse-exclude-file-extensions
                       when (string-match elem ext)
                       return elem))
            ;; check coding systems to exclude
            (setq coding-match (memq (diredc--guess-decoding filename)
                                     diredc-browse-exclude-coding-systems))
            ;; check exclusion-helpers
            (setq helper-match
              (let*
                ((helper (assq system-type diredc-browse-exclude-helper))
                 (output (when helper
                           (shell-command-to-string
                             (format "%s %s \"%s\"" (nth 1 helper) (nth 2 helper) filename)))))
               (when output
                 (if (string-match (nth 3 helper) output)
                   ;; the inclusion test passes
                   nil
                  ;; return the result of the exclusion test
                  (and (string-match
                         (nth 6 helper)
                         (setq output (condition-case nil
                           (shell-command-to-string
                             (format "%s %s \"%s\"" (nth 4 helper) (nth 5 helper) filename))
                           (error ""))))
                       (match-string 0 output)))))))
      (erase-buffer)
      (insert
        (concat "\nThis file is excluded from being browsed because it has\n"
          (cond
           (ext-match
             (setq var 'diredc-browse-exclude-file-extensions)
             (format "filename extension \"%s\".\n\nSee variable %s"
                     ext-match var))
           (coding-match
             (setq var 'diredc-browse-exclude-coding-systems)
             (format "coding system \"%s\".\n\nSee variable %s"
                     (car coding-match) var))
           (helper-match
             (setq var 'diredc-browse-exclude-helper)
             (format "property \"%s\".\n\nSee variable %s"
                     helper-match var))
           (browse-binary
             (setq var 'diredc-browse-binary)
             (format "property \"binary-file\".\n\nSee variable %s"
                     var))
           (t "")) ; WARNING: This condition should never be reached
          "\n\nYou can customize this variable."))
      (goto-char (point-min))
      (when (re-search-forward (symbol-name var) nil t)
        (make-text-button (match-beginning 0) (match-end 0)
                          :type 'help-xref
                          'action 'diredc-browse--button-describe-action 'var var))
      (when (re-search-forward "\\<customize\\>" nil t)
        (help-xref-button 0 'help-customize-variable var))
      (let ((p1 (+ 2 (goto-char (point-max)))))
        (insert "\n\nReturn to diredc.")
        (make-text-button p1 (1- (point-max))
                          :type 'help-xref
                          'action 'diredc-browse--button-return-action))
      t) ; Return t when exclusion is true
    ))

(defun diredc-trash--show-more-file-info--freedesktop ()
  "Internal function for `diredc-mode' 'Trash' file buffers.

A hook function for `post-command-hook', when the user
environment utilizes the freedesktop method of trash
management."
  (let (trash-file info-file)
    (cond
     ((minibuffer-window-active-p (selected-window))
       t)
     ((or (not (eq major-mode 'dired-mode))
          (not (equal (expand-file-name dired-directory)
                      diredc-trash-files-dir))))
     ((and (setq trash-file (diredc--file-name-at-point))
           diredc-trash-info-dir
           (setq info-file
             (expand-file-name
               (concat (file-name-nondirectory trash-file) ".trashinfo")
               diredc-trash-info-dir))
           (file-readable-p info-file))
       (save-mark-and-excursion
         (with-temp-buffer
           (insert-file-contents info-file)
           (let (message-log-max) ; suppress output to *Messages* buffer
             (message "%s"
               (buffer-substring-no-properties (point-min) (1- (point-max)))))))))))

(defun diredc--show-more-file-info ()
  "Update the additional file information displayed in the minibuffer."
  (let (message-log-max ; suppress output to *Messages* buffer
        (info-file (expand-file-name (diredc--file-name-at-point)))
        (cmd diredc--show-more-file-info-cmd)
        output)
    (when (and info-file (not (zerop (length cmd))))
      (setq output (condition-case nil
                     (shell-command-to-string (format cmd info-file))
                     (error ""))) ; TODO: Report error encountered
      (if (zerop (length output))
        (message "%s: No output." (substring cmd 0 (string-match " "cmd)))
       (message "%s" output)))))

(defun diredc--hist-guess-restore-point (hist pos)
  "Fetch POINT of an adjoining matching history entry.
This function is called in cases of 'direct' navigation, because
the user may have asked to directly navigate to a directory that
could have been done by either `diredc-hist-next-directory' or
`diredc-hist-previous-directory' for which the history stack has
a restore POINT.

HIST is a copy of the buffer's history stack, variable
`diredc-hist--history-list', and POS is a copy the current position
within it, variable `diredc-hist--history-position'."
  ;; NOTE: The structure of the `cond' in this function is based upon
  ;; that of function `diredc-hist--update-directory-history'. The two
  ;; functions (currently) check the same places, but for different
  ;; purpose and result.
  ;; TODO: Consider being more lenient, and checking any entry in
  ;; HIST, even if it's not adjoining. The issue then would be is two
  ;; matches exist, which to choose.
  (let ((dir (expand-file-name dired-directory))
        pos2)
    (cond
     ((= 1 (length hist))
       (when (equal dir (caar hist))
         (nth 1 (car hist))))
     ((equal dir (car (nth pos hist)))
       (nth 1 (nth pos hist)))
     ((and (< 0 pos)
           (equal dir (car (nth (setq pos2 (1- pos)) hist))))
       (nth 1 (nth pos2 hist)))
     ((and (> (length hist) (setq pos2 (1+ pos)))
           (equal dir (car (nth pos2 hist))))
       (nth 1 (nth pos2 hist))))))

(defun diredc-hist--update-directory-history (hist pos)
  "Internal function to update a `dired' buffer's history record.

HIST should be a buffer's `diredc-hist--history-list' value. POS
should be a buffer's `diredc-hist--history-position' value.
Returns a CONS whose CAR is the new list and whose CDR is the new
position."
  ;; TODO: consider standardizing retval. Compare function
  ;; `diredc-hist--prune-deleted-directories'
  ;; NOTE: See note for function `diredc--hist-guess-restore-point'.
  (let* ((new-dir (substring-no-properties
                    (expand-file-name dired-directory)))
         (new (list new-dir (point) dired-omit-mode))
         pos2)
    (cons
      ; diredc-hist--history-list
      (cond
       ((= 1 (length hist))
         (when (not (equal new-dir (caar hist)))
           (push new hist))
         hist)
       ((equal new-dir (car (nth pos hist)))
         hist)
       ((and (< 0 pos)
             (equal new-dir (car (nth (setq pos2 (1- pos)) hist))))
             (setq pos pos2)
             hist)
       ((and (> (length hist) (setq pos2 (1+ pos)))
             (equal new-dir (car (nth pos2 hist))))
             (setq pos pos2)
             hist)
       (t (setq hist (last hist (- (length hist) pos)))
          (setq pos 0)
          (push new hist)
          hist))
      ; diredc-hist--history-position
      pos)))

(defun diredc-display--update (new)
  "Internal function to update all `dired' buffers.
NEW is the new listing switch entry to use."
  (setq dired-listing-switches (cdr new))
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (eq major-mode 'dired-mode)
        (setq dired-actual-switches dired-listing-switches)
        (revert-buffer))))
  (message "Dired using 'ls' switches: \"%s\"" (car new)))

(defun diredc-hist--prune-deleted-directories ()
  "Prune non-existing directories from a diredc buffer's history."
  ;; TODO: consider standardiing retval. Compare function
  ;; `diredc-hist--update-directory-history'
  (let ((pos diredc-hist--history-position)
        hist)
    (mapc
      (lambda (elem)
        (if (file-directory-p (car elem))
          (push elem hist)
         (unless (zerop pos) (cl-decf pos))))
      diredc-hist--history-list)
    (setq diredc-hist--history-list
      (cond
       (hist (reverse hist))
       ((file-directory-p default-directory)
         (list (list default-directory 1 dired-omit-mode)))
       (t (list (list "/" 1 nil)))))
    (setq diredc-hist--history-position pos)))

(defun diredc--find-another-diredc-buffer (buf)
  "Find a live dired buffer other than BUF.
BUF is expected to be a live dired buffer."
  (if (= 1 (length dired-buffers))
    ;; This is an error condition; let's be nice and recover from it.
    (dired "~")
   (let ((result (cdr (nth 0 dired-buffers))))
     (when (eq buf result)
       (setq result (cdr (nth 1 dired-buffers))))
      result)))
  ;; NOTE: The above might not return expected / desired results when
  ;; there exist many dired buffers, possibly spread across many
  ;; non-diredc frames. The following may end up being more robust for
  ;; those cases.
  ;; (let ((bufs (buffer-list (window-frame (selected-window))))
  ;;       found result)
  ;;   (while (and (not found) (setq result (pop bufs)))
  ;;     (with-current-buffer result
  ;;       (when (and (eq major-mode 'dired-mode)
  ;;                  (not (eq result buf)))
  ;;         (setq found t
  ;;               bufs nil))))
  ;;   (when found result)))

(defun diredc--abort-on-directory-deleted (dir)
  "Report a user error for a deleted directory."
  (unless (file-directory-p dir)
    (user-error "This diredc buffer %s describes a directory that has been deleted!" dir)))

(defun diredc--ask-on-directory-deleted (dir)
  "Prompt when attempting to operate on a deleted directory."
  (unless (file-directory-p dir)
    (unless (yes-or-no-p
	      (format "This diredc buffer %s describes a directory that has been deleted!
Continue anyway? " dir))
      (user-error "Operation aborted"))))


;;
;;; Interactive functions:

(defun diredc-restore-collation ()
  "Restore environment variable LC_COLLATE to its original setting.
This could possibly come in handy if you regret that you used
function `diredc-sort-or-edit' in a way that modified that environment
variable. You could also manually use function `setenv' to your
preference."
  (interactive)
  (setenv "LC_COLLATE" diredc--lc-collate-original-value))

(defun diredc-sort-or-edit (&optional method)
  "Sort a `diredc' buffer by METHOD.
Interactively, prompts the user for METHOD, offering the choices
of the CARs of variable `diredc--sort-options' (see there).
Programmatically, if arguments are not provided, defaults to sort
by name, ascending.

Note that the sorting options for chmod, owner, and group are
fragile in the sense that they expect the `diredc' buffer to be
presenting its first four fields in classic 'ls -l' format.

With a prefix argument, allows the user to manually edit the
current listing switches instead. See variable
`dired-listing-switches', and compare with function
`dired-sort-toggle-or-edit'.

Some of the available sort methods change the environment
variable `LC_COLLATE', which you might want set differently for
your Emacs use outside of `diredc'. If you find yourself in such
a situation, evaluating function `diredc-reset-collation' will
restore the variable to how it was found. This will be performed
automatically for you upon exiting `diredc', and you can of
course at any time manually play with function `setenv'.

This function modifies the mode line to reflect the sort order.
You can customize the sort-direction indications. See variables
`diredc-sort-prefix-ascending', `diredc-sort-suffix-ascending',
`diredc-sort-prefix-descending', and
`diredc-sort-suffix-descending'."
  (interactive
    (let (minibuffer-history method)
      (unless (eq major-mode 'dired-mode)
        (user-error "Not a Dired buffer"))
      (unless diredc-mode
        (user-error "Diredc not enabled"))
      (when dired-sort-inhibit
        (error "Cannot sort this Dired buffer"))
      (unless current-prefix-arg
        (while (or (not method)
                   (zerop (length method)))
          (setq method
            (completing-read "Sort method: "
                             (mapcar 'car diredc--sort-options)
                             nil t))))
      (list method)))
  (cond
   (current-prefix-arg
     (dired-sort-other
       (read-string "ls switches (must contain -l): " dired-actual-switches))
     (setq mode-name "Dired")
     (revert-buffer))
   (t
     (setq method (or (assoc (or method "name (a-z)") diredc--sort-options)
                      (error "Improper diredc sort method requested: %s" method)))
     (cond
      ((nth 5 method) ; ie. chmod/owner/group
        (diredc--sort-special method))
      (t ; ie. using ls switches for sorting buffer
        (setq dired-listing-switches
          (concat
            (replace-regexp-in-string "\\( --reverse\\)?\\( --sort=[^ ]+\\)?$"
                                      "" dired-listing-switches)
            (when (nth 2 method) " --reverse")
            (when (nth 1 method) (format " --sort=%s" (nth 1 method)))))
        (setq dired-actual-switches dired-listing-switches)
        (setenv "LC_COLLATE" (when (nth 4 method) "C"))
        (revert-buffer)))
     (setq mode-name
       (if (equal (nth 1 method) "none")
         "Dired"
        (format "Dired by %s%s%s"
                (if (nth 3 method)
                  diredc-sort-prefix-ascending
                 diredc-sort-prefix-descending)
                (or (nth 1 method) "name")
                (if (nth 3 method)
                  diredc-sort-suffix-ascending
                 diredc-sort-suffix-descending))))))
  (force-mode-line-update))

(defun diredc-wdired ()
  "Modify directory contents by editing the `dired' buffer.
This is a simple wrapper for `wdired-mode'. See there for
details."
  (interactive)
  (diredc--abort-on-directory-deleted dired-directory)
  (when diredc-history-mode
    (setf (nth 2 (nth diredc-hist--history-position diredc-hist--history-list))
          dired-omit-mode))
  (wdired-change-to-wdired-mode)
  (setq header-line-format
    (if diredc-header-line
      (concat "  Diredc: "
              (propertize " EDITING!" 'face 'bold)
              "  C-c C-k to abort;  C-c C-c to accept")
     "")))

(defun diredc-shell-kill ()
  "Kill the current shell window, buffer, and process."
  (interactive)
  ;; TODO preform sanity check here (only use in diredc shell buffers)
  (let ((return-window diredc-shell--bufwin)
        proc)
    (while (and (setq proc (get-buffer-process (current-buffer)))
                (process-live-p proc))
      (set-process-query-on-exit-flag proc nil)
      (kill-process proc))
    (kill-buffer-and-window)
    (when (window-live-p return-window)
      (select-window return-window))))

(defun diredc-shell ()
  "Create a `diredc' shell window and buffer.

The chosen shell option is set in variable
`diredc-shell-default', but you can call this function with a
PREFIX-ARG to over-ride it.

If a shell-window already exists for the current `dired'
directory, select it instead of creating an additional one."
  (interactive)
  (when (not (eq major-mode 'dired-mode))
    (error "Not a dired-buffer"))
  (let ((d1-window (selected-window))
        window-list minibuffer-history len d2 f2 t2 make-new
        (shell-choice (when (not current-prefix-arg)
                        (car (assoc diredc-shell-default diredc-shell-list))))
        (d1 dired-directory)
        (f1 (or (dired-file-name-at-point) ""))
        (t1 (or (dired-get-marked-files) "")))
   (while (or (not shell-choice)
              (zerop (length shell-choice)))
     (setq minibuffer-history '("")
           shell-choice (completing-read "Choose a program: "
                                   (mapcar 'car diredc-shell-list) nil t)))
   (cond
    ;; Programmer's note: The sneaky part here is that when only part
    ;;   one of the 'and' is true the function exits with focus
    ;;   selected to the discovered pre-existing shell window.
    ((diredc-shell--find-existing-shell)
      (when (not (equal diredc-shell-default shell-choice))
        (diredc-shell-kill)
        (setq make-new t)))
    (t
      (setq make-new t)))
   (when make-new
     (setq diredc-shell-default shell-choice)
     (dolist (x (window-list))
       (select-window x 'norecord)
       (when (eq major-mode 'dired-mode)
         (push x window-list)))
     (setq window-list (remq d1-window window-list))
     (when (= 1 (setq len (length window-list)))
       (select-window (car window-list) 'norecord)
       (setq d2        dired-directory
             f2        (or (dired-file-name-at-point) "")
             t2        (or (dired-get-marked-files) "")))
     (select-window d1-window 'norecord)
     (select-window (split-window-below (- 0 diredc-shell-lines)))
     (funcall (nth 1 (assoc shell-choice diredc-shell-list))
              (nth 2 (assoc shell-choice diredc-shell-list))
              d1 d2 f1 f2 t1 t2)
     (setq-local dired-directory d1)
     (setq  diredc-shell--bufwin d1-window)
     (use-local-map (copy-keymap (current-local-map)))
     (local-set-key (kbd "C-c C-k") 'diredc-shell-kill)
     (local-set-key [remap kill-buffer] 'diredc-shell-kill)
     (set-window-dedicated-p nil t)
     (when (< 1 len)
       (message "Variables d2,f2,t2 not set. (More than two dired buffers visible).")))))

(defun diredc-browse-tab ()
  "Tab-navigate to the next button or other window.
This function navigates to the other window only if no buttons
exist in the current one."
  (interactive)
  (condition-case nil
    (forward-button 1)
    (user-error
      (goto-char (point-min))
      (condition-case nil
        (forward-button 1)
        (user-error
          (diredc-other-window))))))

(defun diredc-browse-backtab ()
  "Tab-navigate to the previous button or other window.
This function navigates to the other window only if no buttons
exist in the current one."
  (interactive)
  (condition-case ()
    (forward-button -1)
    (user-error
      (goto-char (point-max))
      (condition-case nil
        (forward-button -1)
        (user-error
          (diredc-other-window))))))

(defun diredc-browse-find ()
  "Quit `diredc-browse-mode', and find the current file."
  (interactive)
  (cond
   ((window-live-p diredc-browse--buffer)
     (select-window diredc-browse--buffer 'norecord))
   ((diredc-other-window) t)
   ((other-window -1) t))
  (diredc-hist-find-file))

(defun diredc-browse-quit ()
  "Exit a `diredc-browse' `view-mode' buffer.

Kills the buffer, returns focus to the calling `diredc' buffer
window, and exits `diredc-browse-mode'."
  (interactive)
  (cond
   ((window-live-p diredc-browse--buffer)
     (select-window diredc-browse--buffer 'norecord))
   ((diredc-other-window) t)
   ((other-window -1) t))
  (diredc-browse-mode -1))

(defun diredc-browse-mode (&optional arg)
  "Preview file at POINT in another window of current dired frame.

The file's buffer is not selected, and is killed when POINT in
the dired buffer moves to another file. This is meant to emulate
the behavior of 'C-x q' in midnight commander.

The browsed file's buffer is put in `view-mode' with the
additional feature of having the TAB key set to switch the
selected window back to the calling Dired window.

When called non-interactively, turns the mode on if ARG is
positive or nil. Otherwise, turns the mode off.

There are several ways to suppress this option for certain files.
The mode checks each file against variables
`diredc-browse-exclude-file-extensions' and
`diredc-browse-exclude-coding-systems'. If those checks pass,
variable `diredc-browse-exclude-helper' is used (see there)."
  (interactive)
  (when (not diredc-mode)
    (user-error "Not in Diredc mode"))
  (unless (or (equal arg -1)
              (eq major-mode 'dired-mode)
              (eq (current-buffer) (cdr diredc-browse--tracker)))
    (user-error "Not a Diredc buffer"))
  (cond
   ((called-interactively-p 'interactive)
     (setq diredc-browse-mode (not diredc-browse-mode)))
   (arg
    (setq diredc-browse-mode (if (< 0 arg) t nil)))
   (t
    (setq diredc-browse-mode t)))
  (cond
   (diredc-browse-mode
    (add-hook 'post-command-hook #'diredc-browse--hook-function)
    (diredc-browse--hook-function))
   (t
    (remove-hook 'post-command-hook #'diredc-browse--hook-function)
    (let ((orig-win (selected-window))
          (browse-buf (cdr diredc-browse--tracker)) ; TODO buffer-live-p
          (target-buf ; The dired buffer to replace the browse buffer
            (diredc--find-another-diredc-buffer
              (if (not diredc-browse--buffer) ; cur-buf is not the browse buffer
                (current-buffer)
               (setq diredc-browse-mode nil)
               (window-buffer diredc-browse--buffer))))
          wins target-win kill-win)
      (setq wins (get-buffer-window-list browse-buf))
      (setq target-win (pop wins))
      (while (setq kill-win (pop wins))
        (delete-window kill-win))
      (select-window target-win 'no-record)
      (set-window-dedicated-p nil nil)
      (when (buffer-live-p browse-buf)
        (kill-buffer browse-buf))
      (when (buffer-live-p target-buf)
        (switch-to-buffer target-buf 'no-record 'force-same-window))
      (set-window-dedicated-p nil t)
      (setq diredc-browse--tracker '(nil . nil))
      (select-window orig-win 'norecord)))))

(defun diredc-swap-windows ()
  "Swap `diredc' buffers.
This feature is only supported when the `diredc' frame is
displaying only two buffers. It performs a true and complete
swap, including buffer histories."
  (interactive)
  (unless (string-match "^#<frame diredc " (format "%s" (window-frame)))
    (user-error "Not in a diredc frame"))
  (unless (= 2 (length (window-list)))
    (user-error "Not swapping. Too many windows open on frame"))
  (let (switch-to-buffer-preserve-window-point
        w1 w2 b1 b2)
    (setq w1 (selected-window)
          w2 (next-window)
          b1 (current-buffer))
    (select-window w2 'no-record)
    (setq b2 (current-buffer))
    (set-window-dedicated-p nil nil)
    (switch-to-buffer b1 nil 'force-same-window)
    (set-window-dedicated-p nil t)
    (diredc--swap-browse-buffer w1 w2)
    (select-window w1 'no-record)
    (set-window-dedicated-p nil nil)
    (switch-to-buffer b2 nil 'force-same-window)
    (set-window-dedicated-p nil t)
    (diredc--swap-browse-buffer w1 w2)))

(defun diredc-summary ()
  "Modified dired keybinding cheat message, to include diredc.
Compare with `dired-summary'."
  (interactive)
  (message
    "d-elete, u-ndelete, x-punge, f-ind, o-ther window, R-ename, C-opy, h-diredc help"))

(defun diredc-key-assist ()
  "Minibuffer cheatsheet and launcher for diredc functions.
There also exist `diredc-trash-key-assist' for trash-specific
functions (\\[diredc-trash-key-assist])."
  (interactive)
  (unless (require 'key-assist nil t)
    (user-error "Requires package 'key-assist'"))
  (key-assist "diredc"))

(defun diredc-trash-assistant ()
  "Minibuffer cheatsheet and launcher for diredc-trash functions."
  ;; This was the inspiration for package `key-assist.el'
  (interactive)
  (let ((zz (lambda (x)
              (let (shortest)
                (dolist (key (mapcar
                               'key-description
                               (where-is-internal
                                 x
                                 diredc-mode-map nil t)))
                  (when (or (not shortest)
                            (> (length shortest) (length key)))
                    (setq shortest key)))
                shortest)))
        (options
                   (list (list (if delete-by-moving-to-trash
                                 "Switch to using deletion"
                                "Switch to using trash")
                               'diredc-trash-toggle)
                     '("Jump to trash files dir" diredc-trash-view)
                     '("Report trash size"       diredc-trash-info)
                     '("Empty the trash"         diredc-trash-empty)
                     '("Restore file at point"   diredc-trash-restore)))
        (prompt (concat (diredc-trash-info) "\nSelect: "))
        choices choice)
    (setq choices (mapcar (lambda(x) (format "%-23s %s" (car x) (funcall zz (cadr x))))
                          options))
    (while (not (setq choice
                  (cl-position
                    (completing-read prompt choices nil t nil 'choices)
                    choices :test 'equal))))
    (funcall (cadr (nth choice options)))))

(defun diredc-trash-key-assist ()
  "Minibuffer cheatsheet and launcher for diredc-trash functions."
  ;; This can deprecate function `diredc-trash-assistant'. However,
  ;; when using package `ivy', only the final line of the prompt is
  ;; visible.
  (interactive)
  (if (not (require 'key-assist nil t))
    (diredc-trash-assistant)
   (let* ((zz (lambda (x) (list (car x)
                                (concat (key-assist--get-keybinding (car x))
                                        "\t"
                                        (cadr x)))))
          (prompt (concat (diredc-trash-info) "\nSelect: "))
          (spec (mapcar
                  zz
                  (list
                    (list 'diredc-trash-toggle   (if delete-by-moving-to-trash
                                                   "Switch to using deletion"
                                                  "Switch to using trash"))
                    (list 'diredc-trash-view     "Jump to trash files dir")
                    (list 'diredc-trash-info     "Report trash size")
                    (list 'diredc-trash-empty    "Empty the trash")
                    (list 'diredc-trash-restore  "Restore file at point")))))
     (key-assist spec prompt t))))

(defun diredc-trash-toggle ()
  "Toggle between using 'trash' or 'delete'."
  (interactive)
  (setq delete-by-moving-to-trash (not delete-by-moving-to-trash))
  (message (if delete-by-moving-to-trash
             "Now trashing, not deleting"
            "Now deleting, not trashing")))

(defun diredc-trash-empty ()
  "Empty the 'Trash'."
  (interactive)
  (when (yes-or-no-p (concat (diredc-trash-info)
                             "\nEmpty the trash?: "))
    (cond
     (trash-directory
       (dired-delete-file trash-directory 'always)
       (dired-create-directory trash-directory))
     ((fboundp 'system-trash-empty) ; placeholder for future possible trash schemes
       (system-trash-empty))
     (t ;; http://freedesktop.org/wiki/Specifications/trash-spec
       ;; (shell-command-to-string
       ;;   (format "rm -r -- %s* %s* %s*" diredc-trash-files-dir
       ;;                                  diredc-trash-info-dir
       ;;                                  diredc-trash-expunged-dir))
       (dolist (dir (list diredc-trash-files-dir
                          diredc-trash-info-dir
                          diredc-trash-expunged-dir))
         (when (file-writable-p dir)
           (dired-delete-file dir 'always)
           (dired-create-directory dir))))))
  (message ""))

(defun diredc-trash-info ()
  "Report size of trash and number of files.

Only reports data for the files themselves, not any
administrative .info or .expunged files needed for restoring
files to their original location."
  (interactive)
  (cond
   (trash-directory
     (user-error "Not supported for `trash-directory'=%s" trash-directory))
   ((fboundp 'system-trash-info) ; placeholder for future possible trash schemes
     (system-trash-info))
   (t ;; http://freedesktop.org/wiki/Specifications/trash-spec
     (let (size num)
       (if (not (file-exists-p diredc-trash-files-dir))
         (message "Trash empty.")
        (setq size
          (replace-regexp-in-string "[\t\n]" " "
            (shell-command-to-string
              (format "du -sh \"%s\""
                      diredc-trash-files-dir))))
        (setq num
          (replace-regexp-in-string "\n" ""
            (shell-command-to-string
              (format "find \"%s\" -type f | wc -l"
                      diredc-trash-files-dir))))
        (message "Now %s\nTrash summary: %s file%s, size %s"
                 (if delete-by-moving-to-trash
                   "trashing, not deleting"
                  "deleting, not trashing")
                 num (if (equal num "1") "" "s") size))))))

(defun diredc-trash-restore ()
  "Attempts to move 'Trash' file at point to its original location.

If a REGION is selected, all files within are restored."
  (interactive)
  (when (not (eq major-mode 'dired-mode))
    (user-error "Not in a Dired buffer"))
  (cond
   (trash-directory
     (user-error "Not supported for `trash-directory'=%s" trash-directory))
   ((fboundp 'system-trash-restore)
     (system-trash-restore))
   ;; http://freedesktop.org/wiki/Specifications/trash-spec
   ((not (file-readable-p diredc-trash-info-dir))
     (error "Trash restore data unavailable. (%s)" diredc-trash-info-dir))
   (t
     (let (file info-file dest end files)
       (when (not (equal (expand-file-name dired-directory)
                         diredc-trash-files-dir))
         (when (not (yes-or-no-p "Not in the 'Trash' files directory. Go there? "))
           (user-error "Not in the 'Trash' files directory"))
         (diredc-hist-change-directory diredc-trash-files-dir)
         (user-error "Now in 'Trash' files directory. Try again"))
      ;; This next code idiom repeats elsewhere (eg.
      ;; `diredc-trash-quick-delete'), so consider making it a function.
       (if (not (region-active-p))
         (setq files (list (diredc--file-name-at-point)))
        (save-excursion
          (setq end (region-end))
          (goto-char (region-beginning))
          (dired-next-line 0)
          (setq files (list (diredc--file-name-at-point)))
          (while (and (dired-next-line 1)
                      (>= end (point)))
            (push (diredc--file-name-at-point) files))))
       (while (setq file (pop files))
         (with-temp-buffer
           (insert-file-contents
             (setq info-file
               (expand-file-name
                 (concat (file-name-nondirectory file) ".trashinfo")
                 diredc-trash-info-dir)))
           (re-search-forward "Path=\\([^\n]+\\)")
           (setq dest
             (if (not (stringp (setq dest (match-string-no-properties 1))))
               (error "Missing restore path for trash entry \"%s\"" file)
              (diredc--decode-hexlated-string dest))))
     ;;  (shell-command (format "mv \"%s\" \"%s\"" file dest))
         (when (or (not (file-exists-p dest))
                   (yes-or-no-p
                     (format "File \"%s\" already exists.\nOverwrite? " dest)))
           (dired-rename-file file dest t)
           (delete-file info-file)))
       (when end
         (goto-char (region-beginning))
         (deactivate-mark))
       (when file
         (let (auto-revert-verbose)
           (auto-revert-mode)))))))

(defun diredc-trash-view ()
  "Jump to the user's 'Trash' files directory."
  (interactive)
  (cond
   (trash-directory
     (diredc-hist-change-directory trash-directory)) ;; seems safe...
   ((fboundp 'system-trash-view)
     (system-trash-view))
   (t ;; http://freedesktop.org/wiki/Specifications/trash-spec
     (diredc-hist-change-directory diredc-trash-files-dir))))

(defun diredc-trash-quick-delete (&optional toggle-trash-option)
  "In `dired-mode', delete a file without needing to mark it first.

If a REGION is selected, delete all files in that region.

Use the prefix argument TOGGLE-TRASH-OPTION to change your
setting of variable `delete-by-moving-to-trash'."
  (interactive)
  (when (or current-prefix-arg toggle-trash-option)
    (setq delete-by-moving-to-trash (not delete-by-moving-to-trash)))
  (let (end files)
    ;; This next code idiom repeats elsewhere (eg.
    ;; `diredc-trash-restore'), so consider making it a function.
    (if (not (region-active-p))
      (setq files (list (cons (diredc--file-name-at-point) 0)))
     (save-excursion
       (setq end (region-end))
       (goto-char (region-beginning))
       (dired-next-line 0)
       (setq files (list (cons (diredc--file-name-at-point) 0)))
       (while (and (dired-next-line 1)
                   (>= end (point)))
         (push (cons (diredc--file-name-at-point) 0) files))))
      (dired-internal-do-deletions files nil delete-by-moving-to-trash)))

(defun diredc-bookmark-add (&optional dir doc)
  "Add the current directory to the list of `diredc' bookmarks.

If the directory is already bookmarked, a second entry is not
created. The user will be prompted for a short description, which
will be what is displayed when running `diredc-bookmark-jump'.

When called non-interactively, the optional args DIR and DOC can
specify the default directory and bookmark description.

See the defcustom variable `diredc-bookmarks'."
  (interactive)
  (if noninteractive
    (when (setq dir (or dir dired-directory))
      (push (cons dir (or doc dir)) diredc-bookmarks)
      (customize-save-variable 'diredc-bookmarks diredc-bookmarks))
   ;; TODO: Consider making these next two `if' statements a preamble
   ;; function to many diredc functions. OTOH, it's probably just a
   ;; waste of electricity as these functions should only ever be
   ;; defined once already in `diredc-mode', ie. already in a
   ;; `dired-mode' buffer.
   (if (not (eq major-mode 'dired-mode))
     (if (yes-or-no-p "Not a Diredc buffer. Navigate to one? ")
       (diredc)
      (user-error "")))
   (if (not diredc-mode)
     (if (yes-or-no-p "Not in Diredc mode. Activate it? ")
       (diredc-mode 1)
      (user-error "")))
   (when dired-directory
     (let (minibuffer-history desc)
       (setq desc
         (read-from-minibuffer
           (format "Adding bookmark for: %s\n Enter a description (return for pathname): "
                   dired-directory)))
       ;; TODO: Consider checking for duplicates?
       (push (cons dired-directory
                   (if (zerop (length desc)) dired-directory desc))
             diredc-bookmarks)
       (customize-save-variable 'diredc-bookmarks diredc-bookmarks)))))

(defun diredc-bookmark-jump ()
  "Navigate a `dired' buffer to a `diredc' bookmarked directory.

See the defcustom variable `diredc-bookmarks'."
  ;; NOTE: Consider using the same popup technique as for
  ;; `diredc-hist-select'.
  (interactive)
  (let ((choices (mapcar 'cdr diredc-bookmarks))
        choice minibuffer-history)
    (while (not (setq choice
                  (cl-position
                    (completing-read "Select: " choices nil t nil 'choices)
                    choices :test 'equal))))
    (diredc-hist-change-directory (car (nth choice diredc-bookmarks)))))

(defun diredc-bookmark-edit ()
  "Edit the `diredc' bookmarks."
  (interactive)
  (customize-variable 'diredc-bookmarks))

(defun diredc-beginning-of-buffer ()
  "Move POINT (relative to) beginning of a `diredc' buffer.
Navigates to the first filename entry in a `diredc' buffer. With
a PREFIX-ARG, behaves as function `beginning-of-buffer'."
  (interactive)
  (if current-prefix-arg
    (beginning-of-buffer current-prefix-arg)
   (goto-char (point-min))
   (forward-line 2))
  (dired-move-to-filename))

(defun diredc-end-of-buffer ()
  "Move POINT (relative to) end of a `diredc' buffer.
Navigates to the final filename entry in a `diredc' buffer. With
a PREFIX-ARG, behaves as function `end-of-buffer'."
  (interactive)
  (if current-prefix-arg
    (end-of-buffer current-prefix-arg)
   (goto-char (point-max))
   (forward-line -1))
  (dired-move-to-filename))

(defun diredc-display-select ()
  "Change the data presented in the `diredc' buffer.

Prompts the user to select an element of
`diredc-display-listing-switches-list', based upon the element's
description string.

If you have package `popup' installed, but don't want to use it
for this purpose, see `diredc-display-select-without-popup'."
  (interactive)
  (let* ((opts diredc-display-listing-switches-list)
         (selects (mapcar 'car opts))
         (len (length opts))
         pos new)
    (when (not (zerop len))
      (setq pos (or (cl-position
                      dired-listing-switches
                      opts
                      :test (lambda (x y) (equal x (cdr y))))
                0))
      (setq new (if (or diredc-display-select-without-popup
                        (not (require 'popup nil 'noerror)))
                  (assoc (completing-read "Display option: "
                                     selects nil t (nth pos opts) '(""))
                         opts)
                   (popup-menu* opts
                                :prompt "Display option:"
                                :point (let ((p1 (point)) p2)
                                         (move-to-window-line -2)
                                         (setq p2 (point))
                                         (goto-char p1)
                                         p2)
                                :around t
                                :initial-index pos)))
      (when new
        (diredc-display--update new)))))

(defun diredc-display-toggle ()
  "Toggle to the next data presentation format for the `diredc' buffer.

Applies the next element of `diredc-display-listing-switches-list'.

With PREFIX-ARG, runs `diredc-display-select' instead to allow
explicit selection of a specific display option."
  (interactive)
  (if current-prefix-arg
    (diredc-display-select)
   (let ((len (length diredc-display-listing-switches-list))
         (pos (cl-position
                 dired-listing-switches
                 diredc-display-listing-switches-list
                 :test (lambda (x y) (equal x (cdr y)))))
         new)
     (when (not (zerop len))
       (setq new (nth (if (not pos) 0 (mod (1+ pos) len))
                   diredc-display-listing-switches-list))
       (diredc-display--update new)))))

(defun diredc-show-more-file-info (&optional arg)
  "Change what/whether to display additional file information in minibuffer.

Interactively, with no PREFIX-ARG, advances to the next element
in variable `diredc-show-more-file-info-list'. With a PREF_ARG,
prompts for what to display, or to display nothing.

See the defcustom variable `diredc-show-more-file-info-list' for
options.

Programmatically, ARG should be a string suitable for use as a
CDR to an element of `diredc-show-more-file-info-list', which
will be applied immediately to the current and all future files
at point for the current session until next interactively or
programmatically changed, or NIL to make no change to current
operation."
  (interactive)
  (cond
   ((called-interactively-p 'any)
     (setq diredc--show-more-file-info-cmd
       (cdr (nth (setq diredc--show-more-file-info-index
                   (if current-prefix-arg
                     (let ((choices (mapcar 'car diredc-show-more-file-info-list))
                           choice minibuffer-history)
                       (while (not (setq choice
                                     (cl-position
                                       (completing-read "Select: " choices nil t nil 'choices)
                                       choices :test 'equal))))
                       choice)
                    ;; if: not current-prefix-arg
                    (mod (1+ diredc--show-more-file-info-index)
                         (length diredc-show-more-file-info-list))))
                 diredc-show-more-file-info-list)))
     (if (zerop (length diredc--show-more-file-info-cmd))
       (message "Suppressing display of additional file info.")
     (diredc--show-more-file-info)))
   (; cond: not called-interactively
    (and arg
         (stringp arg))
      (diredc--show-more-file-info))))

(defun diredc-do-async-shell-command (command &optional arg file-list)
  "Run a shell COMMAND on the marked files FILE-LIST asynchronously.

Like `dired-do-async-shell-command', but entering a 'blank' is
interpreted as (concat \" \" default-command). Doing so allows
overriding a setting of `diredc-async-processes-are-persistent'
non-NIL.

ARG is the prefix-arg."
  (interactive
   (let ((files (dired-get-marked-files t current-prefix-arg nil nil t)))
     (cl-flet
       ;; We are re-defining `dired-read-shell-command' from
       ;; `dired-aux.el' because even if/when emacs bug #48072 is
       ;; addressed, we need to allow a SPACE command to allow
       ;; overriding a `diredc-async-processes-are-persistent' value
       ;; of non-NIL.
       ;;
       ;; See elsewhere in this file for an advice function to address
       ;; the bug for a non-asynchronous command.
       ((dired-read-shell-command (prompt arg files)
          (minibuffer-with-setup-hook
              (lambda ()
                (setq-local dired-aux-files files)
                (setq-local minibuffer-default-add-function
                            #'minibuffer-default-add-dired-shell-commands))
            (setq prompt (format prompt (dired-mark-prompt arg files)))
            (let (command)
              (setq command
                (if (functionp 'dired-guess-shell-command)
                  (dired-mark-pop-up nil 'shell files
                                     'dired-guess-shell-command prompt files)
                 (dired-mark-pop-up nil 'shell files
                                    'read-shell-command prompt nil nil)))
           ;; These two validation checks address the issues in Emacs
           ;; bug report and patch #48072:
           ;; (http://debbugs.gnu.org/cgi/bugreport.cgi?bug=48072)
              (when  (string= "" command)
                (user-error "No command entered. Nothing to do!"))
           ;; For diredc, we need to allow a SPACE command to allow
           ;; overriding a `diredc-async-processes-are-persistent'
           ;; value of non-NIL.
           ;; (unless (executable-find command)
              (unless (or (string-match-p "^[ \t]+$" command)
                          (executable-find
                            (if (diredc--match-command command)
                              (match-string 1 command)
                             command)))
                (user-error "Not a valid command!"))
              command))))
     (list
      ;; Want to give feedback whether this file or marked files are used:
      (dired-read-shell-command "& on %s: " current-prefix-arg files)
      current-prefix-arg
      files))))
  (cond
   ((string-match-p "^[ \t]+$" command)
     ;; no command entered, guess fallback
     (setq command (format " %s &"
                     (car (diredc--advice--shell-guess-fallback
                          'dired-guess-default
                          file-list)))))
   ((not (string-match-p "&[ \t]*\\'" command))
     ;; command entered, but without " &" suffix
     (setq command (concat command " &"))))
  (dired-do-shell-command command arg file-list))


(defun diredc-history-mode (&optional arg)
  "Control ability to navigate directory history.

Interactively, toggle the mode. From Lisp, with ARG positive or NIL,
turn the mode on; Otherwise, turn it off.

The mode allows each Dired window to maintain its own individual
history, to be navigated backward and forward.

See functions `diredc-hist-previous-directory',
`diredc-hist-next-directory', and `diredc-hist-select'."
  (interactive)
  (cond
    ((called-interactively-p 'interactive)
      (setq diredc-history-mode (not diredc-history-mode)))
    (arg
     (setq diredc-history-mode (if (< 0 arg) t nil)))
    (t
     (setq diredc-history-mode t)))
  (cond
   (diredc-history-mode
     (setq diredc-allow-duplicate-buffers t)
     (add-hook 'dired-mode-hook  #'diredc-hist--hook-function)
     (message "Diredc-history-mode enabled in all Dired buffers."))
   (t
     (remove-hook 'dired-mode-hook #'diredc-hist--hook-function)
     ;; Do not set local variables `diredc-hist--history-list' and
     ;; `diredc-hist--history-position' to NIL, so if the mode is
     ;; toggled on again, those values will be remembered.
     ;;
     (message "Diredc-history-mode disabled in all Dired buffers."))))

(defun diredc-hist-previous-directory (&optional arg)
  "Navigate one `dired' directory back in this buffer's history list.

Optionally, navigate prefix argument ARG number of history elements."
  (interactive "p")
  (when (not diredc-history-mode)
    (user-error "Diredc-history-mode not enabled"))
  (diredc-hist--prune-deleted-directories)
  (let* ((max (1- (length diredc-hist--history-list)))
         (req (+ diredc-hist--history-position arg))
         (ovr (or (when (> req max) (setq req max))
                  (when (< req 0)   (setq req 0))))
         (hist diredc-hist--history-list)
         (pos  (min max req)) ; i don't think pos is necessary anymore, use req instead
         (hist-elem (nth pos hist))
         (special-sort diredc--sort-option-special))
    (if ovr
      (message "No more directory history!")
     (setf (nth 1 (nth diredc-hist--history-position hist)) (point))
     (setf (nth 2 (nth diredc-hist--history-position hist)) dired-omit-mode)
     (find-alternate-file (car hist-elem))
     (set-window-dedicated-p nil t)
     (diredc--set-omit-mode (nth 2 hist-elem))
     (goto-char (nth 1 hist-elem))
     (when special-sort
       (diredc--sort-special special-sort))
     (setq diredc-hist--history-list hist
           diredc-hist--history-position pos))))

(defun diredc-hist-next-directory (&optional arg)
  "Navigate one `dired' directory forward in this buffer's history list.

Optionally, navigate prefix argument ARG number of history elements."
  (interactive "p")
  (when (not diredc-history-mode)
    (user-error "Diredc-history-mode not enabled"))
  (diredc-hist-previous-directory (- arg)))

(defun diredc-hist-change-directory (&optional new-dir)
  "Prompt the user to navigate the Dired window anywhere.

When called interactively with a prefix argument and
`diredc-history-mode' active, runs `diredc-hist-select' instead
to allow explicit selection of a specific directory in the
buffer's history.

When called from Lisp, optional arg NEW-DIR suppresses the prompting
and navigates to that location."
  (interactive)
  (when (eq major-mode 'wdired-mode)
    (user-error "Please exit `wdired-mode' before attempting to change directories"))
  (and (not (eq major-mode 'dired-mode))
       (fboundp 'diredc-frame-quick-switch)
       (diredc-frame-quick-switch))
  (when diredc-history-mode
    (diredc-hist--prune-deleted-directories))
  (if (and diredc-history-mode
           current-prefix-arg)
    (diredc-hist-select)
   (let (file-to-find new-file new-hist hist pos restore-point)
     (when diredc-history-mode
       (setq hist diredc-hist--history-list
             pos  diredc-hist--history-position))
     (if new-dir
       (setq new-dir (expand-file-name new-dir))
      (setq new-dir
        (expand-file-name (read-file-name "Select directory: "
                                          dired-directory dired-directory t)))
      (unless (file-directory-p new-dir)
        (if (file-exists-p new-dir)
          (setq new-file      new-dir
                new-dir       (file-name-directory new-dir)
                file-to-find (concat "\s\\(" (file-name-nondirectory new-file) "\\)\n"))
         (when (yes-or-no-p (format "Directory %s does not exist. Create it? " new-dir))
           (dired-create-directory new-dir))
           (message "")))) ; clear echo area (emacs 26) when answer is 'no'
     (when (file-directory-p new-dir)
       (when diredc-history-mode
         (setf (nth 1 (nth pos hist)) (point))
         (setf (nth 2 (nth pos hist)) dired-omit-mode))
       (let ((omit-mode dired-omit-mode)
             (special-sort diredc--sort-option-special))
         (find-alternate-file new-dir)
         (diredc--set-omit-mode omit-mode)
         (when (setq restore-point
                 (diredc--hist-guess-restore-point hist pos))
           (goto-char restore-point))
         (when special-sort
           (diredc--sort-special special-sort)))
       (set-window-dedicated-p nil t)
       (while (and file-to-find
                   (re-search-forward file-to-find nil t))
         (backward-char 2)
         (when (string-match-p new-file
                               (expand-file-name (dired-file-name-at-point)))
           (setq file-to-find nil)
           (goto-char (match-beginning 1))))
       (when diredc-history-mode
         (setq new-hist (diredc-hist--update-directory-history hist pos)
               diredc-hist--history-list (car new-hist)
               diredc-hist--history-position (cdr new-hist)))))))

(defun diredc-hist-up-directory (&optional arg)
  "Navigate the Dired window to its parent directory.

With optional prefix argument, repeat ARG times."
  (interactive "p")
  (let ((dir dired-directory)
        (omit-mode dired-omit-mode)
        (special-sort diredc--sort-option-special))
    (cond
     ((not (file-directory-p dir))
       (diredc--ask-on-directory-deleted dir)
       ;; The current directory has been deleted, so we just navigate to
       ;; the first existing parent.
       (while (not (file-directory-p (setq dir (file-name-directory (substring dir 0 -1))))))
       (if (not diredc-history-mode)
         (find-alternate-file dir)
        (diredc-hist--prune-deleted-directories)
        (let* ((hist diredc-hist--history-list)
               (pos  diredc-hist--history-position)
               restore-point new)
          (setf (nth 1 (nth pos hist)) (point))
          (setf (nth 2 (nth pos hist)) omit-mode)
          (find-alternate-file dir)
          (when (setq restore-point
                  (diredc--hist-guess-restore-point hist pos))
            (goto-char restore-point))
          (setq new (diredc-hist--update-directory-history hist pos)
                diredc-hist--history-list (car new)
                diredc-hist--history-position (cdr new))))
       (diredc--set-omit-mode omit-mode)
       (when special-sort
         (diredc--sort-special special-sort)))
     ((zerop arg) (message "Nothing to do!"))
     ((> 0 arg)   (message "tbd"))
     (t
       (cond
        (diredc-history-mode
          (diredc-hist--prune-deleted-directories)
          (let* ((hist diredc-hist--history-list)
                 (pos  diredc-hist--history-position)
                 restore-point new)
            (setf (nth 1 (nth pos hist)) (point))
            (setf (nth 2 (nth pos hist)) omit-mode)
            (dotimes (_x (max arg 0))
              (when dir
                (setq dir (file-name-directory (substring dir 0 -1)))))
            (find-alternate-file (or dir "/"))
            (diredc--set-omit-mode omit-mode)
            (when (setq restore-point
                    (diredc--hist-guess-restore-point hist pos))
              (goto-char restore-point))
            (when special-sort
              (diredc--sort-special special-sort))
            (setq new (diredc-hist--update-directory-history hist pos)
                  diredc-hist--history-list (car new)
                  diredc-hist--history-position (cdr new))))
        (t ; (not diredc-history-mode)
          (dotimes ( _x (max arg 0))
            (when dir
              (setq dir (file-name-directory (substring dir 0 -1)))))
          (find-alternate-file (or dir "/"))))))
          (diredc--set-omit-mode omit-mode)
          (when special-sort
            (diredc--sort-special special-sort))
          (set-window-dedicated-p nil t)))

(defun diredc-hist-select ()
  "Navigate anywhere in the Dired history directly.

If you have package `popup' installed, but don't want to use it
for this purpose, see `diredc-hist-select-without-popup'."
  (interactive)
  (when (not diredc-history-mode)
    (user-error "Requires diredc-history mode"))
  (diredc-hist--prune-deleted-directories)
  (let* ((hist diredc-hist--history-list)
         (pos  diredc-hist--history-position)
         (options (mapcar 'car hist))
         (new (if (or diredc-hist-select-without-popup
                      (not (require 'popup nil 'noerror)))
                (completing-read "Select: " options nil t nil (cons 'options pos))
               (substring-no-properties
                 (popup-menu* options :point (point-min) :initial-index pos))))
         hist-elem)
    (when new
      (setf (nth 1 (nth pos hist)) (point))
      (setf (nth 2 (nth pos hist)) dired-omit-mode)
      (find-alternate-file new)
      (set-window-dedicated-p nil t)
      (setq new (diredc-hist--update-directory-history hist pos)
            diredc-hist--history-list (car new)
            diredc-hist--history-position (cdr new)
            hist-elem (nth (cdr new) (car new)))
      (diredc--set-omit-mode (nth 2 hist-elem))
      (goto-char (nth 1 hist-elem)))))

(defun diredc-hist-duplicate (&optional arg)
  "Navigate a second `dired' buffer to a duplicate location.

This function is designed to operate when the selected
window (ie. the current window) is one of two that are displaying
`dired' buffers in the current frame. The `dired' buffer in the
other window is navigated to the location of the current window.
With a non-nil prefix-arg ARG, the reverse operation is performed:
the currently selected `dired' buffer is the one navigated to the
location of the `dired' buffer in the second window.

Compare with the Midnight Commander feature bound there by
default to 'M-i'."
;; NOTE: This function twice uses (user-error "") as an 'undocumented'
;; alternative to `throw'/`catch' or `defun*'/`return-from'. If that
;; causes some unexpected side-effect or otherwise bothers you, feel
;; free to replace them with either of the official methods.
  (interactive)
  (let ((start-buf (current-buffer))
        (wins (window-list))
        (this-dir dired-directory)
        that-dir old-point win target-win new-buf new-data hist pos dup-found omit-mode)
    (cond
     ((or arg current-prefix-arg) ; Change this window/buffer
       (diredc--ask-on-directory-deleted dired-directory)
       (while (setq win (pop wins))
         (unless (equal start-buf (setq new-buf (window-buffer win)))
           (with-current-buffer new-buf
             (when (eq major-mode 'dired-mode)
               (if (equal this-dir dired-directory)
                 (setq dup-found t)
                (setq that-dir dired-directory)
                (setq wins '(nil)))
              (setq old-point (point))
              (setq omit-mode dired-omit-mode)))))
       (when (and (not that-dir) dup-found)
         (if (equal omit-mode dired-omit-mode)
           (user-error "Nothing to do!")
          (diredc--set-omit-mode omit-mode)
          (user-error ""))) ; Naughty me!
       (diredc--abort-on-directory-deleted that-dir)
       (when diredc-history-mode
         (diredc-hist--prune-deleted-directories)
         (setq hist diredc-hist--history-list)
         (setq pos  diredc-hist--history-position)
         (setf (nth 1 (nth pos hist)) (point))
         (setf (nth 2 (nth pos hist)) dired-omit-mode))
       (find-alternate-file that-dir)
       (diredc--set-omit-mode omit-mode)
       (set-window-dedicated-p nil t)
       (goto-char old-point)
       (when diredc-history-mode
         (setq new-data (diredc-hist--update-directory-history hist pos))
         (setq diredc-hist--history-list (car new-data))
         (setq diredc-hist--history-position (cdr new-data))))
     (t ; Change the other window/buffer
       (diredc--abort-on-directory-deleted dired-directory)
       (setq old-point (point))
       (while (setq win (pop wins))
         (unless (equal start-buf (setq new-buf (window-buffer win)))
           (with-current-buffer new-buf
             (when (eq major-mode 'dired-mode)
               (if (equal this-dir dired-directory)
                 (setq dup-found t)
                (setq that-dir dired-directory)
                (setq wins '(nil)))
               (setq omit-mode dired-omit-mode)
               (setq target-win win)))))
       (when (and (not that-dir) dup-found)
         (if (equal omit-mode dired-omit-mode)
           (user-error "Nothing to do!")
          ;; Abbreviated version of the remainder of the function
          (setq omit-mode dired-omit-mode)
          (select-window target-win 'norecord)
          (diredc--set-omit-mode omit-mode)
          (pop-to-buffer start-buf)
          (user-error ""))) ; Naughty me!
       (setq omit-mode dired-omit-mode)
       (select-window target-win 'norecord)
       (diredc--ask-on-directory-deleted dired-directory)
       (when diredc-history-mode
         (diredc-hist--prune-deleted-directories)
         (setq hist diredc-hist--history-list)
         (setq pos  diredc-hist--history-position)
         (setf (nth 1 (nth pos hist)) (point))
         (setf (nth 2 (nth pos hist)) dired-omit-mode))
       (find-alternate-file this-dir)
       (diredc--set-omit-mode omit-mode)
       (set-window-dedicated-p nil t)
       (goto-char old-point)
       (when diredc-history-mode
         (setq new-data (diredc-hist--update-directory-history hist pos))
         (setq diredc-hist--history-list (car new-data))
         (setq diredc-hist--history-position (cdr new-data)))
       (pop-to-buffer start-buf)))))

(defun diredc-hist-find-file ()
  "In Dired, visit this file."
  (interactive)
  (if diredc-history-mode
    (diredc-hist-find-alternate-file)
   (let ((omit-mode dired-omit-mode)
         (special-sort diredc--sort-option-special))
     (dired-find-file)
     (when (eq major-mode 'dired-mode)
       (diredc--set-omit-mode omit-mode)
       (when special-sort
         (diredc--sort-special special-sort))
       (set-window-dedicated-p nil t)))))

(defun diredc-hist-find-file-other-window ()
  "In Dired, visit this file or directory in another window."
  (interactive)
  (if diredc-history-mode
    (diredc-hist-find-alternate-file 'other-window)
   (let ((omit-mode dired-omit-mode)
         (special-sort diredc--sort-option-special))
     (dired-find-file-other-window)
     (when (eq major-mode 'dired-mode)
       (diredc--set-omit-mode omit-mode)
       (when special-sort
         (diredc--sort-special special-sort))
       (set-window-dedicated-p nil t)))))

(defun diredc-hist-find-alternate-file (&optional arg)
  "Navigate the Dired window to the selected directory or file.

If point is on a directory, if ARG is nil, visits it in the same
window, and if ARG is non-nil visits it in a second dired window
on the same frame. If point is on a non-directory file, visits
the file in another frame."
  (interactive)
  ;; TODO: Maybe this check should be done more often.
  ;; TODO: If this is really a wide dired problem, report it to emacs.
  (diredc--abort-on-directory-deleted dired-directory)
  (if (not diredc-history-mode)
    (let ((omit-mode dired-omit-mode)
          (special-sort diredc--sort-option-special))
      (dired-find-alternate-file)
      (when (eq major-mode 'dired-mode)
        (diredc--set-omit-mode omit-mode)
        (when special-sort
          (diredc--sort-special special-sort))
        (set-window-dedicated-p nil t)))
   (diredc-hist--prune-deleted-directories)
   (let ((target (substring-no-properties (dired-get-file-for-visit)))
         (omit-mode dired-omit-mode)
         (special-sort diredc--sort-option-special)
         hist pos new hist-elem)
     (cond ; whether target is a directory or a file
      ((file-directory-p target) ; a directory
        (cond ; whether to use this window or another one
         ((not arg) ; use this window
           (setq hist diredc-hist--history-list
                 pos  diredc-hist--history-position)
           (setf (nth 1 (nth pos hist)) (point))
           (setf (nth 2 (nth pos hist)) omit-mode)
           (dired-find-alternate-file))
         (t ; open directory in another window
           (let ((other-windows-on-this-frame
                   (remq (selected-window) (window-list)))
                 another-window found)
             (cond
              ((zerop (length other-windows-on-this-frame))
                ; create 2nd window / 2nd dired buffer, use current hist
                (split-window-right)
                (other-window 1)
                (dired target)
                ; maybe instead: look for and use a non-visible dired buffer?
                )
              (t ; find a window displaying a dired buffer, and use it
                (while (and (not found)
                            (setq another-window (pop other-windows-on-this-frame)))
                  (with-current-buffer (window-buffer another-window)
                    (when (eq major-mode 'dired-mode)
                      (setq found another-window))))
                (cond
                 (found
                   (select-window found)
                   (setq hist diredc-hist--history-list
                         pos  diredc-hist--history-position)
                   (setf (nth 1 (nth pos hist)) (point))
                   (setf (nth 2 (nth pos hist)) omit-mode)
                   (find-alternate-file target))
                 (t ; no window is a dired window
                   (other-window 1)
                   (dired target)
                   ; maybe instead: look for and use a non-visible dired buffer?
                  )))))))
        (diredc--set-omit-mode omit-mode)
        (when special-sort
          (diredc--sort-special special-sort))
        (set-window-dedicated-p nil t)
        (setq new (diredc-hist--update-directory-history hist pos)
              diredc-hist--history-list (car new)
              diredc-hist--history-position (cdr new)
              hist-elem (nth (cdr new) (car new)))
;;      Not certain it is necessary to goto-char here...
        (goto-char (nth 1 hist-elem)))
      (t ; target is not a directory, so visit file, in another frame
         (let* ((buf (find-buffer-visiting target))
                (win (and buf
                          (get-buffer-window buf t))))
           (cond
            ((and win (equal (window-frame win) (window-frame)))
             ; file is already viewable in current frame, so select it in
             ; another frame
              (if (> 1 (length (frame-list)))
                (select-frame (next-frame))
               (make-frame-command))
              (find-file target))
            (win ; file is already viewable in another frame, so select it
              (select-window win))
            (t
              (if (< 1 (length (frame-list)))
                (select-frame (next-frame))
               (make-frame-command))
              (find-file target)))))))))

(defun diredc-other-window ()
  "Select another `diredc' window, if one exists.
Returns NON-NIL upon success."
  (interactive)
  (let ((original-win (selected-window))
        (w-list (window-list))
        w done)
    (while (and (not done)
                (setq w (pop w-list)))
      (when (not (eq w original-win))
        (select-window w 'norecord)
        (when (or (eq major-mode 'dired-mode)
                  (bound-and-true-p diredc-browse--buffer))
          (setq done t)
          (select-window w))))
    (cond
     (done t)
     (t
       (select-window original-win 'norecord)
       nil))))

(defun diredc-bonus-configuration (caller)
  "Maybe set supplemental configuration options.
When variable `diredc-bonus-configuration' is non-nil, enables
those options that the `diredc' developer feels are sane and
desirable for a newcomer to `dired'. CALLER should be the calling
function context, either `diredc-mode' or `dired-mode-hook'."
  ;; NOTE: I do *NOT* want to make this a mode, ie. subject to
  ;;       real-time toggling. The only reason for the existence of
  ;;       defcustom variable `diredc-bonus-configuration' is to
  ;;       respect a user's desire not to have all these extra
  ;;       features imposed upon regular `dired'.
  (when diredc-bonus-configuration
    (cond
     ((eq caller 'dired-mode-hook)
       (font-lock-add-keywords 'nil diredc--chmod-font-lock-keyword t)
       (setq truncate-lines t
             directory-free-space-args "-Pm" ; show total/available space in MB
             ;; TODO: WARNING: `directory-free-space-args' becomes obsolete as
             ;; of 27.1 and is ignored, as Emacs uses `file-system-info' instead.
             ;; But, we want to support older emacsen for a while.
             dired-dwim-target t)            ; dual pane awareness
       (dired-omit-mode)
       (auto-revert-mode)
       (hl-line-mode)
       (define-key dired-mode-map (kbd "M-.") 'dired-omit-mode))
     ((eq caller 'diredc-mode)
       (setq ; variables of package dired-x
         dired-omit-files "^\\.?#\\|^\\..*"
         dired-omit-verbose nil
         dired-guess-shell-case-fold-search t)
       (add-to-list 'display-buffer-alist
         '("\\*Async Shell Command\\*.*" display-buffer-no-window nil))
       ;; variable of package dired-aux
       (add-to-list 'dired-compress-files-alist '("\\.gz\\'" . "gzip -k %i"))
       (add-to-list 'dired-compress-files-alist '("\\.xz\\'" . "xz -k %i"))))))

(defun diredc-update-keymap ()
  "Update the `diredc-mode' keymap."
  (interactive)
  (setq diredc-mode-map (diredc--create-keymap)))

(defun diredc-exit ()
  "Remove all `dired' frames, windows, and buffers.

This function does not change any `dired' settings or global
modes."
  (interactive)
  (while (condition-case nil
           (or (select-frame-by-name "diredc") t)
           (error nil))
    (condition-case nil
      (delete-frame)
      (error ; this happens when all frames were named 'dired'
        (set-frame-name "F1")))) ; emacs default first frame name
  (diredc-browse-mode -1)
  (dolist (buf (buffer-list))
    (set-buffer buf)
    (when (or (eq major-mode 'dired-mode)
              (bound-and-true-p diredc-browse--buffer))
      ;; If ALL your existing buffers (including *scratch*) are in
      ;; dired-mode, when the final one is killed, emacs v26.1
      ;; creates a *Messages* buffer.
      (kill-buffer buf))))
(defalias 'diredc-quit 'diredc-exit)

(defun diredc-do-not-quit-window ()
  "Prevent unwanted `quit-window' actions.

The default Dired keybindings make it too easy to perform a
`quit-window' operation, first by binding `q' to the command, and
second, by binding `Q' to `dired-do-find-regexp-and-replace'."
  (interactive)
  (message "Use %s for diredc-exit, or M-x quit-window for the emacs primitive."
    (key-description (where-is-internal 'diredc-exit diredc-mode-map t))))

(defun diredc-recover ()
  "Attempt to restore a `dired' dual-pane layout.

If possibly one or more `dired' frames and/or' buffers exist, but
the layout on the frame has been altered 'somehow' (\"ahem.. no
judgements...\"), try this function."
  (interactive)
  (when (zerop (length diredc-recover-schemes))
    (error "Variable 'diredc-recover-schemes' corrupt"))
  (let (minibuffer-history ; needs to be reset to prevent unwanted entries
        temp-list ; variable is re-used for several purposes!
        len       ; variable is re-used for several purposes!
        options
        decision) ; variable is re-used for several purposes!
    (dolist (fram (frame-list))
      (when (string-match "^#<frame diredc " (format "%s" fram))
        (push fram temp-list)))
    (cond
     ((zerop (length temp-list))
       (make-frame-command)
       (set-frame-name "diredc"))
     (t
      (select-frame (pop temp-list))
      (while temp-list
        (delete-frame (pop temp-list)))))
    (cond
     ((= 1 (setq len (length (setq temp-list (reverse (window-list))))))
       (split-window-right))
     ((< 2 len)
       (dotimes (_x (- len 2))
         (delete-window (pop temp-list)))))
    (setq temp-list nil)
    (dolist (buf (buffer-list))
      (with-current-buffer buf
        (if (bound-and-true-p diredc-browse--buffer)
          (kill-buffer buf)
         (when (eq major-mode 'dired-mode)
           (push buf temp-list)))))
    (setq len (min (length temp-list)
                   (1- (length diredc-recover-schemes))))
    (setq options (cdr (nth len diredc-recover-schemes)))
    (when (not (zerop (setq len (length options))))
      (if (= 1 len)
        (setq decision (cdr (nth 0 options)))
       (while (or (not decision)
                  (zerop (length decision)))
         (setq minibuffer-history '(""))
         (setq decision
           (cdr (assoc
                  (completing-read
                    (format "%d dired buffers found. Choose an action: " (length temp-list))
                    (mapcar 'car options) nil t)
                  options)))))
      (funcall decision temp-list))))

(defun diredc-mode (&optional arg)
  "Extensions to `dired' mode.

Interactively, toggle the mode. From Lisp, with ARG positive or NIL,
turn the mode on; Otherwise, turn it off."
  (interactive)
  (cond
    ((called-interactively-p 'interactive)
      (setq diredc-mode (not diredc-mode)))
    (arg
     (setq diredc-mode (if (< 0 arg) t nil)))
    (t
     (setq diredc-mode t)))
  (when (fboundp 'diredc-history-mode)
    (diredc-history-mode (if diredc-mode 1 -1)))
  (cond
   (diredc-mode
     (setq diredc-allow-duplicate-buffers t
           diredc--lc-collate-original-value (getenv "LC_COLLATE"))
     (add-hook 'dired-mode-hook  #'diredc--hook-function)
     (add-to-list 'window-state-change-functions 'diredc--window-state-change-hook-function)
     (advice-add 'dired-repeat-over-lines
                 :around #'diredc--advice--repeat-over-lines)
     (advice-add 'dired-internal-noselect
                 :around #'diredc--advice--dired-internal-noselect)
     (advice-add 'dired-guess-default
                 :around #'diredc--advice--shell-guess-fallback)
     (advice-add 'dired-run-shell-command
                 :around #'diredc--advice--dired-run-shell-command)
     (advice-add 'dired-read-shell-command
                 :around #'diredc--advice--dired-read-shell-command)
     (dolist (buf dired-buffers)
       (if (not (buffer-live-p (cdr buf)))
         (setq dired-buffers (remove buf dired-buffers))
        (with-current-buffer (cdr buf)
          (diredc--hook-function)
          (let ((win (get-buffer-window)))
            (when win (set-window-dedicated-p win t))))))
     (diredc-bonus-configuration 'diredc-mode)
     (message "Diredc-mode enabled in all Dired buffers."))
   (t
     (remove-hook 'dired-mode-hook #'diredc--hook-function)
     (setq window-state-change-functions
       (delq 'diredc--window-state-change-hook-function
             window-state-change-functions))
     ;; Do not set `diredc-allow-duplicate-buffers' to NIL, because it
     ;; may be required by other minor modes or features (eg.
     ;; dired-frame.el)
     (advice-remove 'dired-repeat-over-lines
                    #'diredc--advice--repeat-over-lines)
     (advice-remove 'dired-guess-default
                    #'diredc--advice--shell-guess-fallback)
     (advice-remove 'dired-run-shell-command
                    #'diredc--advice--dired-run-shell-command)
     (advice-remove 'dired-read-shell-command
                    #'diredc--advice--dired-read-shell-command)
     (dolist (buf dired-buffers)
       (if (not (buffer-live-p (cdr buf)))
         (setq dired-buffers (remove buf dired-buffers))
        (with-current-buffer (cdr buf)
          (diredc--hook-function)
          (let ((win (get-buffer-window)))
            (when win (set-window-dedicated-p win nil)))
          (setq header-line-format nil)
          (use-local-map dired-mode-map))))
     (diredc-restore-collation)
     (message "Diredc-mode disabled in all Dired buffers."))))

;;;###autoload
(defun diredc ()
  "Launch `diredc'. Switch back and forth between `diredc' and previous frame.

If no `diredc' frame exists, create one with a dual-window layout."
  (interactive)
  (unless diredc-mode
    (diredc-mode 1))
  (cond
   ((string-match "^#<frame diredc " (format "%s" (window-frame)))
     (other-frame 1)
     (redraw-frame))
   (t
    (condition-case nil
      (select-frame-by-name "diredc")
      (error
        (setq dired-dwim-target t)  ; dual pane awareness
        (setq diredc-allow-duplicate-buffers t)
        (select-frame (make-frame-command))
        (set-frame-name "diredc")
        (split-window-right)
        (dired default-directory)
        (set-window-dedicated-p nil t)
        (other-window 1)
        (dired "~")
        (set-window-dedicated-p nil t)
        (other-window -1)
        (put 'dired-find-alternate-file 'disabled nil))))))


;;
;;; Work I'm not sure I want to include...
;;
;; (defcustom diredc-vc-default '(git)
;;   "What version control methods `diredc-git-jump' acts on."
;;   :type '(repeat (choice (const 'git)
;;                          (const 'cvs)))
;;   :group 'diredc)
;;
;; (defcustom diredc-vc-root-dirs '("~")
;;   "From where to search for sub-directories under version control.
;;
;; See `diredc-git-jump'."
;;   :type '(repeat (directory))
;;   :group 'diredc)
;;
;; (defun diredc-vc-jump (&optional vc-type)
;;   "Jump to a directory under version control.
;;
;; Searches for directories under version control
;; `diredc-vc-default' unless optional VC-TYPE is a valid
;; alternative, presents a list of them to the user, and navigates a
;; `dired' buffer to the user's choice."
;;   ;; NOTE: The motivation for this was that version-control root
;;   ;; directories are likely to be jump destinations and places of
;;   ;; interest on a storage device, even when not bookmarked.
;;   (interactive)
;;   (user-error "Not yet coded. Vote if you want this feature!")
;;   (let ((search-dirs diredc-vc-root-dirs)
;;         search-dir result-dirs)
;;     (while (setq search-dir (pop search-dirs))
;;       (setq result-dirs
;;         (concat result-dirs
;; ;; TODO: replace shell command with platform-agnostic emacs command?
;;                 (shell-command-to-string
;;                   (format "find \"%s\" -type d -iname .git"
;;                           (file-name-as-directory search-dir))))))
;;     result-dirs))
;; (defalias 'diredc-git-jump 'diredc-vc-jump)


;;
;;; Conclusion:

(provide 'diredc)

;;; diredc.el ends here

;;
;;; Integration Notes
;;
;; Should the emacs project incorporate this code, it should consider:
;;
;; *) emacs bug report #44023:
;;    https://debbugs.gnu.org/cgi/bugreport.cgi?bug=44023
;;
;; *) Function `dired-file-name-at-point' should have an optional
;;    argument NOERROR added, to return NIL instead of signaling
;;    error conditions, and should guarantee a NON-NIL return value
;;    otherwise. Once this is done, then all occurrences of
;;    (diredc--file-name-at-point) should be removed and replaced with
;;    (dired-file-name-at-point 'noerror).
;;
;; *) Defcustoms should include  :version "28.1"
