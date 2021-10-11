;;; symbol-navigation-hydra.el --- A symbol-aware, range-aware hydra -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Brett Wines

;; Author: Brett Wines <bgwines@cs.stanford.edu>
;; Keywords: highlight face match convenience hydra symbol
;; Package-Version: 20211010.2353
;; Package-Commit: b3b1257e676514d93cd2d71a10a485bf00b5375f
;; Package-Requires: ((auto-highlight-symbol "1.61") (hydra "0.15.0") (emacs "24.4") (multiple-cursors "1.4.0"))
;; URL: https://github.com/bgwines/symbol-navigation-hydra
;; Version: 0.0.7

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This is a hydra that augments existing Emacs navigation/editing functionality
;; by adding awareness of symbols and configuration of the range of focus for
;; these operations. Its functionality can be partitioned into three categories:
;;
;;   1. navigation
;;   2. multiple cursors / swooping
;;   3. searching in a directory/project
;;
;; See the README for more details. Credit is due to the Spacemacs AHS Transient
;; State for inspiring this package.
;;
;; Happy coding! ^_^

;;; Code:

(require 'hydra)
(require 'auto-highlight-symbol)
(require 'multiple-cursors)
(require 'grep)

(defgroup symbol-navigation-hydra nil
  "The Symbol Navigation Hydra"
  :group 'convenience
  :link `(url-link :tag "Download latest version"
                   ,(eval-when-compile
                      (concat "https://github.com/bgwines/"
                              "symbol-navigation-hydra/"
                              "blob/master/symbol-navigation-hydra.el")))
  :link `(url-link :tag "Information"
                   ,(eval-when-compile
                      (concat "https://github.com/bgwines/"
                              "symbol-navigation-hydra"))))

(defcustom symbol-navigation-hydra-display-legend nil
  "Non-nil means suppress the KEY legend."
  :group 'symbol-navigation-hydra
  :type 'boolean)

(defcustom symbol-navigation-hydra-project-search-fn nil
  "An override for the `g` head."
  :group 'symbol-navigation-hydra
  :type 'function)

(defcustom symbol-navigation-hydra-directory-search-fn nil
  "An override for the `d` head."
  :group 'symbol-navigation-hydra
  :type 'function)

(defface symbol-navigation-hydra-ahs-plugin-display-face-dim
  '((t (:foreground "#eeeeee" :background "#3a2303")))
  "Dimmer version of the Display face."
  :group 'symbol-navigation-hydra)
(defvar symbol-navigation-hydra-ahs-plugin-display-face-dim
  'symbol-navigation-hydra-ahs-plugin-display-face-dim)

(defface symbol-navigation-hydra-ahs-plugin-whole-buffer-face-dim
  '((t (:foreground "#eeeeee" :background "#182906")))
  "Dimmer version of the Buffer face."
  :group 'symbol-navigation-hydra)
(defvar symbol-navigation-hydra-ahs-plugin-whole-buffer-face-dim 'symbol-navigation-hydra-ahs-plugin-whole-buffer-face-dim)

(defface symbol-navigation-hydra-ahs-plugin-beginning-of-defun-face-dim
  '((t (:foreground "#eeeeee" :background "#0b2d5c")))
  "Dimmer version of the Function face."
  :group 'symbol-navigation-hydra)
(defvar symbol-navigation-hydra-ahs-plugin-beginning-of-defun-face-dim 'symbol-navigation-hydra-ahs-plugin-beginning-of-defun-face-dim)

;; Buffer-local variables
(defvar helm-ag-base-command)  ;; following the pattern from helm-projectile.el
(defvar symbol-navigation-hydra-point-at-invocation nil)
(defvar symbol-navigation-hydra-window-start-at-invocation nil)
(defvar symbol-navigation-hydra-allow-edit-all-head-execution nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; displaying the hydra ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;###autoload (autoload 'sn-hydra/body "symbol-navigation-hydra.el" nil nil)
(defhydra sn-hydra (:hint nil :color amaranth)
  ;;         Column 0
  (concat "%s(symbol-navigation-hydra-header)          *accepts C-u\n"

          (concat "%s(symbol-navigation-hydra-A0)"
                  " | %s(symbol-navigation-hydra-B0)"
                  " | %s(symbol-navigation-hydra-C0)\n")

          ;; Column 1
          (concat (concat "_n_^^^^: next*    "
                          "_z_/_l_: recenter | ")
                  (concat "_f_: mark & next*  "
                          "_u_: %s(symbol-navigation-hydra-unmark-header)     | ")
                  "_d_: %s(symbol-navigation-hydra-folder-header)\n")

          ;; Column 2
          (concat (concat "_N_/_p_: prev*  "
                          "_r_: range      | ")
                  (concat "_b_: mark & prev*  "
                          "_e_: %s(symbol-navigation-hydra-edit-marks-header) | ")
                  "_g_: %s(symbol-navigation-hydra-project-header)\n")

          ;; Column 3
          (concat (concat "_R_: %s(symbol-navigation-hydra-reset-header)    "
                          "_i_,_1_: ith,1st  | ")
                  (concat "_a_: mark all      "
                          "_s_: %s(symbol-navigation-hydra-swoop-header)  | ")
                  "_q_/C-g: quit")

          "%s(symbol-navigation-hydra-footer)")
  ("n" symbol-navigation-hydra-move-point-one-symbol-forward)
  ("N" symbol-navigation-hydra-move-point-one-symbol-backward)
  ("p" symbol-navigation-hydra-move-point-one-symbol-backward)
  ("i" symbol-navigation-hydra-move-point-to-ith)
  ("1" symbol-navigation-hydra-move-point-to-first)
  ("r" symbol-navigation-hydra-change-range)
  ("R" symbol-navigation-hydra-back-to-start)
  ("z" (progn (recenter-top-bottom) (symbol-navigation-hydra-highlight-current-window) (sn-hydra/body)))
  ("l" (progn (recenter-top-bottom) (symbol-navigation-hydra-highlight-current-window) (sn-hydra/body)))
  ("b" symbol-navigation-hydra-mark-and-move-to-prev)
  ("f" symbol-navigation-hydra-mark-and-move-to-next)
  ("a" symbol-navigation-hydra-mark-all)
  ("u" symbol-navigation-hydra-remove-fake-cursors-at-point)
  ("e" symbol-navigation-hydra-mc-edit :exit t)
  ("s" symbol-navigation-hydra-swoop :exit t)
  ("d" (symbol-navigation-hydra-search-directory (thing-at-point 'symbol))
   :exit t)
  ("g" (symbol-navigation-hydra-search-project (thing-at-point 'symbol))
   :exit t)
  ("q" symbol-navigation-hydra-exit :exit t)
  ("^g" symbol-navigation-hydra-exit :exit t))

(defun symbol-navigation-hydra-search-directory (symbol)
  "Search the current directory for `SYMBOL'."
  (if (eq nil symbol-navigation-hydra-directory-search-fn)
      (symbol-navigation-hydra-projectile-helm-ag t symbol)
    (funcall symbol-navigation-hydra-directory-search-fn symbol)))

(defun symbol-navigation-hydra-search-project (symbol)
  "Search the current project for `SYMBOL'."
  (ahs-unhighlight-all)
  (if (eq nil symbol-navigation-hydra-project-search-fn)
      (symbol-navigation-hydra-projectile-helm-ag nil symbol)
    (funcall symbol-navigation-hydra-project-search-fn symbol)))

(defface symbol-navigation-hydra-disabled-head-face
  '((t (:foreground "#777777")))
  "Face for disabled hydra heads."
  :group 'symbol-navigation-hydra)
(defvar symbol-navigation-hydra-disabled-head-face
  'symbol-navigation-hydra-disabled-head-face)

(defun symbol-navigation-hydra-edit-marks-header ()
  "The header for the hydra head for exiting into MC editing."
  (symbol-navigation-hydra-head-header
   (symbol-navigation-hydra-are-multiple-cursors-active) "edit marks" ""))

(defun symbol-navigation-hydra-unmark-header ()
  "The header for the \"unmark\" hydra head."
  (symbol-navigation-hydra-head-header
   (<= 1 (symbol-navigation-hydra-get-n-fake-cursors-at-point)) "unmark" ""))

(defun symbol-navigation-hydra-reset-header ()
  "The header for the \"reset\" hydra head."
  (symbol-navigation-hydra-head-header
   (not (eq (point) symbol-navigation-hydra-point-at-invocation)) "reset" ""))

(defun symbol-navigation-hydra-swoop-header ()
  "The header for the \"swoop\" hydra head."
  (symbol-navigation-hydra-head-header
   (symbol-navigation-hydra-is-swoop-enabled) "swoop"
   (symbol-navigation-hydra-swoop-suffix)))

(defun symbol-navigation-hydra-folder-header ()
  "The header for the \"directory\" hydra head."
  (symbol-navigation-hydra-head-header
   (or symbol-navigation-hydra-directory-search-fn
    (and (symbol-navigation-hydra-is-helm-ag-enabled)
        (symbol-navigation-hydra-is-projectile-enabled)))
   "directory" (symbol-navigation-hydra-directory-suffix)))

(defun symbol-navigation-hydra-project-header ()
  "The header for the \"project\" hydra head."
  (symbol-navigation-hydra-head-header
   (or symbol-navigation-hydra-project-search-fn
       (and (symbol-navigation-hydra-is-helm-ag-enabled)
        (symbol-navigation-hydra-is-projectile-enabled)))
   "project" (symbol-navigation-hydra-project-suffix)))

(defun symbol-navigation-hydra-head-header (is-enabled name suffix)
  "Get the string for the head.

`IS-ENABLED' should be a boolean. `NAME' should be the name of the head.
`SUFFIX' should be the string to append to the header, either the empty
string or a string indicating that `NAME' is disabled."
  (if is-enabled
      (format "%s%s" name suffix)
    (format "%s%s"
            (propertize name 'face symbol-navigation-hydra-disabled-head-face)
            suffix)))

(defun symbol-navigation-hydra-A0 ()
  "In the hydra display, the first column."
  (propertize "       Navigation        " 'face `(:weight bold :underline t)))

(defun symbol-navigation-hydra-B0 ()
  "In the hydra display, the second column."
  (concat
   (propertize "             Multi " 'face `(:weight bold :underline t))
   (symbol-navigation-hydra-get-formatted-mc-count)
   (propertize (symbol-navigation-hydra-get-col-2-spaces) 'face `(:weight bold :underline t))))

(defun symbol-navigation-hydra-C0 ()
  "In the hydra display, the third column."
  (propertize (concat "    Search  "
                      (make-string
                       (length (symbol-navigation-hydra-directory-suffix)) ? ))
              'face `(:weight bold :underline t)))

(defun symbol-navigation-hydra-swoop ()
  "Perform `helm-swoop' on the current symbol."
  (interactive)
  ;; These are the same thing, but we need the inlined `fboundp' to satisfy
  ;; flycheck
  (mc/keyboard-quit)
  (ahs-unhighlight-all)
  (if (and (symbol-navigation-hydra-is-swoop-enabled) (fboundp 'helm-swoop))
      (call-interactively #'helm-swoop)
    (symbol-navigation-hydra-error-not-installed "helm-swoop")))

(defun symbol-navigation-hydra-swoop-suffix ()
   "Indicate disabledness if necessary."
   (symbol-navigation-hydra-head-suffix
    (symbol-navigation-hydra-is-swoop-enabled) t))

(defun symbol-navigation-hydra-project-suffix ()
  "Indicate disabledness if necessary.

This function is an aggregation of two checks because they both guard the same
behavior in the UI."
  (symbol-navigation-hydra-head-suffix
   (or symbol-navigation-hydra-project-search-fn
       (and (symbol-navigation-hydra-is-projectile-enabled)
        (symbol-navigation-hydra-is-helm-ag-enabled)))))


(defun symbol-navigation-hydra-directory-suffix ()
  "Indicate disabledness if necessary.

This function is an aggregation of two checks because they both guard the same
behavior in the UI."
  (symbol-navigation-hydra-head-suffix
   (or symbol-navigation-hydra-directory-search-fn
       (and (symbol-navigation-hydra-is-projectile-enabled)
            (symbol-navigation-hydra-is-helm-ag-enabled)))))


(defun symbol-navigation-hydra-head-suffix (is-enabled &optional include-spaces)
  "Indicate disabledness if necessary.

`IS-ENABLED' and `INCLUDE-SPACES' should be a booleans."
  (if is-enabled (if include-spaces "    " "") " (?)"))

(defun symbol-navigation-hydra-is-swoop-enabled ()
  "Determine whether the package is loaded."
  (fboundp 'helm-swoop))

(defun symbol-navigation-hydra-is-projectile-enabled ()
  "Determine whether the package is loaded."
  (fboundp 'projectile-mode))

(defun symbol-navigation-hydra-is-helm-ag-enabled ()
  "Determine whether the package is loaded."
  (fboundp 'helm-do-ag))

(defun symbol-navigation-hydra-is-active (plugin)
  "Determine whether `PLUGIN' is the current user-selected range."
  (string= (ahs-get-plugin-prop 'lighter plugin)
           (ahs-current-plugin-prop 'lighter)))

(defun symbol-navigation-hydra-darken-plugin-face (face)
  "Retrieve the corresponding face for an inactive plugin.

`FACE' should be one of the three defined AHS plugin faces."
  (cond ((eq face ahs-plugin-default-face)
         'symbol-navigation-hydra-ahs-plugin-display-face-dim)
        ((eq face ahs-plugin-whole-buffer-face)
         'symbol-navigation-hydra-ahs-plugin-whole-buffer-face-dim)
        ((eq face ahs-plugin-bod-face)
         'symbol-navigation-hydra-ahs-plugin-beginning-of-defun-face-dim)
        (t (error (format "Unknown face: %s" face)))))

(defun symbol-navigation-hydra-plugin-color (plugin)
  "Retrieve the face for `PLUGIN', factoring in whether it is enabled or not."
  (let ((face (ahs-get-plugin-prop 'face plugin t)))
    (if (symbol-navigation-hydra-is-active plugin) face
      (symbol-navigation-hydra-darken-plugin-face face))))

(defun symbol-navigation-hydra-get-active-xy (current-overlay overlay-count)
  "Compute the overlay counts for the currently active plugin.

`CURRENT-OVERLAY' should be `(ahs-current-overlay-window)', as a string.
`OVERLAY-COUNT' should be the number of matches for the current symbol
for the current plugin."
  (let ((overlay (format "%s" (nth 0 ahs-overlay-list)))
        (i 0))
    (while (and (< i (length ahs-overlay-list))
                (not (string= overlay current-overlay)))
      (setq i (1+ i))
      (setq overlay (format "%s" (nth i ahs-overlay-list))))
    (format "[%s/%s]" (- overlay-count i) overlay-count)))

(defun symbol-navigation-hydra-plugin-component (plugin)
  "Piece together the string to display in the UI for `PLUGIN'."
  (let* ((name (propertize (symbol-navigation-hydra-get-plugin-display-name
                            plugin)
                           'face (symbol-navigation-hydra-plugin-color plugin)))
         (overlay-count (length ahs-overlay-list))
         (current-overlay (format "%s" (ahs-current-overlay-window)))
         (xy (if (symbol-navigation-hydra-is-active plugin)
                 (symbol-navigation-hydra-get-active-xy current-overlay
                                                        overlay-count)
               (symbol-navigation-hydra-get-plugin-xy plugin))))
    (concat name xy)))

(defun symbol-navigation-hydra-get-col-2-spaces ()
  "Compute the spaces to go after the \"Multi\" string."
  (make-string (- 11 (length (symbol-navigation-hydra-get-formatted-mc-count))) ? ))

(defun symbol-navigation-hydra-are-multiple-cursors-active ()
  "Fewer than 2 cursors is not \"multiple\" cursors."
  (<= 2 (symbol-navigation-hydra-count-cursors)))

(defun symbol-navigation-hydra-count-cursors ()
  "Count the active cursors, subtracting any that overlap with `POINT'."
  ;; + 1 to add the cursor at `POINT'
  (- (+ 1 (length (mc/all-fake-cursors)))
     (symbol-navigation-hydra-get-n-fake-cursors-at-point)))

(defun symbol-navigation-hydra-get-formatted-mc-count ()
  "Format the number of active cursors."
  (let ((n-cursors (symbol-navigation-hydra-count-cursors)))
    (if (symbol-navigation-hydra-are-multiple-cursors-active)
        (format "(%s)"
                (propertize (format "%s" n-cursors)
                            'face `(:foreground "#FAAD41")))
      "")))

(defun symbol-navigation-hydra-header ()
  "This is the user-visible header at the top of the hydra.

It is comprised of
    * The title of the hydra
    * The three plugins, with the inactive ones dimmed, all with overlay counts"
  (concat
   (propertize "SN Hydra" 'face `(:box t :weight bold)) "   "
   (symbol-navigation-hydra-plugin-component 'ahs-range-beginning-of-defun) "  "
   (symbol-navigation-hydra-plugin-component 'ahs-range-whole-buffer) "  "
   (symbol-navigation-hydra-plugin-component 'ahs-range-display)))

(defun symbol-navigation-hydra-get-plugin-display-name (plugin)
  "Get the user-visible name for `PLUGIN'."
  (cond
   ((eq plugin 'ahs-range-beginning-of-defun) "Function")
   ((eq plugin 'ahs-range-whole-buffer) "Buffer")
   ((eq plugin 'ahs-range-display) "Display")))

(defun symbol-navigation-hydra-get-plugin-search-range (symbol plugin)
  "Compute the pair of integers within which to search for `SYMBOL'.

The range is dependent on the user-selected range, which is `PLUGIN'.

`PLUGIN' should be one of
  'ahs-range-beginning-of-defun
  'ahs-range-whole-buffer
  'ahs-range-display"
  (let ((before (ahs-get-plugin-prop 'before-search plugin symbol))
        (beg (ahs-get-plugin-prop 'start plugin))
        (end (ahs-get-plugin-prop 'end plugin)))
    (cond ((equal before 'abort) nil)
          ((not (numberp beg)) nil)
          ((not (numberp end)) nil)
          ((> beg end) nil)
          (t (cons beg end)))))

(defun symbol-navigation-hydra-get-occurrences-within-range (symbol search-range)
  "Search for `SYMBOL' in `SEARCH-RANGE'.

`SEARCH-RANGE' should be a pair of integers representing indexes of characters."
  (save-excursion
    (let ((case-fold-search ahs-case-fold-search)
          (regexp (concat "\\_<\\(" (regexp-quote symbol) "\\)\\_>" ))
          (beg (car search-range))
          (end (cdr search-range))
          (occurrences 'nil))
      (goto-char end)
      (while (re-search-backward regexp beg t)
        (let* ((symbol-beg (match-beginning 1))
               (symbol-end (match-end 1))
               (tprop (text-properties-at symbol-beg))
               (face (cadr (memq 'face tprop))))
          (unless (ahs-face-p face 'ahs-inhibit-face-list)
            (push (list symbol-beg symbol-end) occurrences))))
      occurrences)))

(defun symbol-navigation-hydra-get-occurrences (plugin)
  "Look up all instances of the currently focused symbol.

These will be instances only within the range specified by
`PLUGIN'. Instances of the symbol in comments or as substrings
are ignored. There are a number of other parameters to this
search (e.g. case-sensitivity); see the auto-highlight-symbol
package.

`PLUGIN' should be one of
    'ahs-range-beginning-of-defun
    'ahs-range-whole-buffer
    'ahs-range-display

The returnvalue is a list of pairs of integers. The integers are indexes
of characters, as in
https://www.gnu.org/software/emacs/manual/html_node/elisp/Regexp-Search.html"
  (let* ((symbol (thing-at-point 'symbol))
         (search-range (if symbol
                           (symbol-navigation-hydra-get-plugin-search-range
                            symbol plugin)
                         nil)))
    (if symbol
        (if (consp search-range)
            (symbol-navigation-hydra-get-occurrences-within-range
             symbol search-range)
          nil) ;; couldn't determine the number of occurrences in the range
      nil))) ;; cursor is not on a symbol, so there are 0 occurrences

(defun symbol-navigation-hydra-get-occurrence-index (occurrences)
  "Compute the index of the occurrence of the currently focused symbol.

For example, for the code in this function, the string
\"occurrences\" appears a few (three) times. If the cursor is
on the first of these, this function returns 0, (not 1, since
it is an index).

`PLUGIN' should be one of
    'ahs-range-beginning-of-defun
    'ahs-range-whole-buffer
    'ahs-range-display

`OCCURRENCES' should be the list of all occurrences of the currently focused
symbol. It should be a list of pairs of integers. The integers should be
indexes of characters, as in
https://www.gnu.org/software/emacs/manual/html_node/elisp/Regexp-Search.html"
  (let* ((i 0)
         (current-overlay (if (ahs-current-overlay-window)
                              (format "%s"
                                      (list
                                       (overlay-start (ahs-current-overlay-window))
                                       (overlay-end (ahs-current-overlay-window))))
                            nil))
         (overlay (format "%s" (nth i occurrences))))
    (while (and (< i (length occurrences))
                (not (string= overlay current-overlay)))
      (setq i (1+ i))
      (setq overlay (format "%s" (nth i occurrences))))
    i))

(defun symbol-navigation-hydra-get-plugin-xy (plugin)
  "For plugin `PLUGIN', computes the overlay counts.

  The first number represents which occurrence of the currently focused symbol
  is selected. The second number represents the total number of occurrences of
  that symbol.

  `PLUGIN' should be one of
      'ahs-range-beginning-of-defun
      'ahs-range-whole-buffer
      'ahs-range-display"
  (let* ((occurrences (symbol-navigation-hydra-get-occurrences plugin))
         (n-occurrences (length occurrences))
         (occurrence-index
          (if occurrences
              (+ 1 (symbol-navigation-hydra-get-occurrence-index occurrences))
            0))) ;; if 0 occurrences, don't increment 0
    (format "[%s/%s]"
            ;; e.g. this can happen when processing `ahs-range-display' after
            ;; using the 'n' / 'p' / 'f' / 'b' hydra heads. The window has not
            ;; redrawn yet, so `occurrences' is still a function of the "old"
            ;; window boundaries, even though `thing-at-point' has moved to an
            ;; entirely different section of the buffer. In these cases, we're
            ;; not able to find the symbol at Point in `occurrences', so we
            ;; reach the end of the list.
            (if (<= occurrence-index n-occurrences) occurrence-index "?")
            n-occurrences)))

(defun symbol-navigation-hydra-footer ()
  "This is the string to be (optionally) displayed at the bottom of the hydra."
  (if symbol-navigation-hydra-display-legend
      (let ((guide
             (concat
              "[" (propertize "KEY" 'face 'hydra-face-blue) "] exits state "
              "[" (propertize "KEY" 'face 'hydra-face-red) "] will not exit")))
        (add-face-text-property 0 (length guide) 'italic t guide)
        guide)
    ""))

(defun symbol-navigation-hydra-highlight-current-window ()
  "Invoke `ahs-highlight-now' for the current window only."
  (ahs--do-hl))

;;;###autoload
(defun symbol-navigation-hydra-engage-hydra ()
  "Trigger the hydra."
  (interactive)
  (setq symbol-navigation-hydra-point-at-invocation (point))
  (setq symbol-navigation-hydra-window-start-at-invocation (window-start))
  (setq symbol-navigation-hydra-allow-edit-all-head-execution t)
  (unless (bound-and-true-p ahs-mode-line)
    (auto-highlight-symbol-mode))
  (symbol-navigation-hydra-highlight-current-window)
  (sn-hydra/body))

;;;;;;;;;;;
;; heads ;;
;;;;;;;;;;;

(defun symbol-navigation-hydra-exit ()
  "Clean up any state that needs to be cleaned up."
  (interactive)
  ;; maybe should this use `(multiple-cursors-mode 0)' directly?
  (mc/keyboard-quit)
  (ahs-unhighlight-all))

(defun symbol-navigation-hydra-mc-edit ()
  "Exit the hydra, so the user can start using the multiple cursors."
  (interactive)
  ;; variable to prevent duplicate execution via
  ;; `mc/execute-this-command-for-all-cursors', since MC seems to listen to all
  ;; `interactive' function executions or something
  (when symbol-navigation-hydra-allow-edit-all-head-execution
    ;; the current cursor may be on top of a previously dropped fake cursor.
    ;; Remove that fake one if it exists so the user doesn't double-enter the
    ;; inputs at `point'
    (symbol-navigation-hydra-remove-fake-cursors-at-point t)
    (mc/maybe-multiple-cursors-mode)
    (ahs-unhighlight-all)
    (setq symbol-navigation-hydra-allow-edit-all-head-execution nil)))

(defun symbol-navigation-hydra-get-n-fake-cursors-at-point ()
  "Determine whether there exist any fake cursors at `POINT'."
  (let ((n-found 0))
    (mc/for-each-fake-cursor
     (let* ((cursor-beg (mc/cursor-beg cursor))
            (is-point-min (eq (point) (min (point) cursor-beg)))
            (is-point-max (eq (point) (max (point) cursor-beg))))
       (when (and is-point-min is-point-max)
         (setq n-found (+ 1 n-found)))))
    n-found))

(defun symbol-navigation-hydra-remove-fake-cursors-at-point (&optional skip-reload-hydra)
  "Remove fake cursors if any exist.

Pass t for `SKIP-RELOAD-HYDRA' if you are calling this function not from the
hydra definition."
  (interactive)
  (mc/for-each-fake-cursor
     (let* ((cursor-beg (mc/cursor-beg cursor))
            (is-point-min (eq (point) (min (point) cursor-beg)))
            (is-point-max (eq (point) (max (point) cursor-beg))))
       (when (and is-point-min is-point-max)
         (mc/remove-fake-cursor cursor))))
  (unless skip-reload-hydra
    (symbol-navigation-hydra-highlight-current-window)
    (sn-hydra/body)))

(defun symbol-navigation-hydra-mark-and-move-to-prev (&optional n)
  "Drop a cursor at `point', and move to the previous occurrence of the symbol.

`N' defaults to 1."
  (interactive "P")
  (dotimes (_ (if n n 1))
    (unless (mc/fake-cursor-at-point)
      (mc/create-fake-cursor-at-point))
    (symbol-navigation-hydra-move-point-one-symbol-backward)))

(defun symbol-navigation-hydra-mark-and-move-to-next (&optional n)
  "Drop a cursor at `point', and move to the next occurrence of the symbol.

`N' defaults to 1."
  (interactive "P")
  (dotimes (_ (if n n 1))
    (unless (mc/fake-cursor-at-point)
      (mc/create-fake-cursor-at-point))
    (symbol-navigation-hydra-move-point-one-symbol-forward)))

(defun symbol-navigation-hydra-mark-all ()
  "Drop cursors every occurrence of the symbol within the range."
  (interactive)
  (save-excursion
    (let ((original-point (point))
          (original-window-start (window-start)))
      (symbol-navigation-hydra-move-point-one-symbol-forward)
      (while (not (eq original-point (point)))
        (symbol-navigation-hydra-mark-and-move-to-next))
      (set-window-start (selected-window) original-window-start))))

(defun symbol-navigation-hydra-change-range ()
  "Switch between BUFFER, DISPLAY, and FUNCTION."
  (interactive)
  (ahs-change-range)
  (symbol-navigation-hydra-highlight-current-window))

(defun symbol-navigation-hydra-back-to-start ()
  "Move `point' to the location it was upon user-initiated hydra invocation."
  (interactive)
  (goto-char symbol-navigation-hydra-point-at-invocation)
  (set-window-start (selected-window) symbol-navigation-hydra-window-start-at-invocation)
  (symbol-navigation-hydra-highlight-current-window)
  (sn-hydra/body))

(defun symbol-navigation-hydra-move-point-one-symbol-forward (&optional n)
  "Move to the next occurrence of symbol under point. N is the (optional)

prefix argument."
  (interactive "P")
  (dotimes (_ (if n n 1))
    (symbol-navigation-hydra-move-point-one-symbol t)))

(defun symbol-navigation-hydra-move-point-to-first ()
  "Move to the first occurrence of symbol under point.
1-indexed because that's consistent with the overlay counts."
  (interactive)
  (symbol-navigation-hydra-move-point-to-ith 1)
  (recenter-top-bottom))

(defun symbol-navigation-hydra-move-point-to-ith (&optional default-i)
  "Move to the ith occurrence of symbol under point.
i is 1-indexed because that's consistent with the overlay counts.

If present, `DEFAULT-I' is used. Otherwise, we the user is prompted."
  (interactive)
  (symbol-navigation-hydra-highlight-current-window)
  (let* ((overlay-count (length ahs-overlay-list))
         (current-overlay (format "%s" (ahs-current-overlay-window)))
         (xy (symbol-navigation-hydra-get-active-xy current-overlay
                                                    overlay-count))
         (x (string-to-number (car (split-string (substring xy 1) "/"))))
         (i (or default-i (read-number "i: ")))
         (n-moves-back (- x i)))
    (if (>= n-moves-back 0)
        (symbol-navigation-hydra-move-point-one-symbol-backward n-moves-back)
        (symbol-navigation-hydra-move-point-one-symbol-forward (- 0 n-moves-back)))))

(defun symbol-navigation-hydra-move-point-one-symbol-backward (&optional n)
  "Move to the previous occurrence of symbol under point. N is the (optional)
prefix argument."
  (interactive "P")
  (dotimes (_ (if n n 1))
    (symbol-navigation-hydra-move-point-one-symbol nil)))

(defun symbol-navigation-hydra-move-point-one-symbol (forward)
  "Move to the previous or next occurrence of the symbol under point.

If `FORWARD' is non-nil, move forwards, otherwise, move backwards.

Could be optimized for the move-N case, but performance is good enough for now"
    (if forward (ahs-forward) (ahs-backward))
    (symbol-navigation-hydra-highlight-current-window)
    (sn-hydra/body))

(defun symbol-navigation-hydra-projectile-helm-ag (arg query)
  "Run `helm-do-ag' relative to the project root, searching for `QUERY'.

Or, with prefix arg `ARG', search relative to the current directory."
  (interactive "P")
  (mc/keyboard-quit)  ;; TODO: share exit-prep code
  (ahs-unhighlight-all)
  (if (symbol-navigation-hydra-is-helm-ag-enabled)
      (if arg
          (progn
            ;; Have to kill the prefix arg so it doesn't get forwarded
            ;; and screw up helm-do-ag
            (set-variable 'current-prefix-arg nil)
            (if dired-directory
                (symbol-navigation-hydra-helm-projectile-ag query dired-directory)
              (symbol-navigation-hydra-helm-projectile-ag query nil)))
        (symbol-navigation-hydra-helm-projectile-ag query nil))
    (symbol-navigation-hydra-error-not-installed "helm-ag")))

(defun symbol-navigation-hydra-helm-projectile-ag (query directory &optional options)
  "SN Hydra version of Helm version of `projectile-ag'.

This is almost a copy of `helm-projectile-ag' from helm-projectile.el,
but it takes a `QUERY' parameter and an optional `DIRECTORY' parameter.
`OPTIONS' is a string to be appended to the `ag' shell command, such
as `--no-color'."
  (interactive)
  (if (and (require 'projectile nil t)
           (fboundp 'projectile-project-p)
           (fboundp 'projectile-ignored-files-rel)
           (fboundp 'projectile-ignored-directories-rel)
           (fboundp 'projectile-parse-dirconfig-file)
           (boundp 'grep-find-ignored-files)
           (boundp 'grep-find-ignored-directories))
      (if (and (projectile-project-p) (fboundp 'projectile-project-root))
          (if (and (require 'helm-ag nil t)
                   (boundp 'helm-ag-base-command)
                   (fboundp 'helm-do-ag))
              (let* ((grep-find-ignored-files
                      (cl-union (projectile-ignored-files-rel) grep-find-ignored-files))
                     (grep-find-ignored-directories
                      (cl-union (projectile-ignored-directories-rel) grep-find-ignored-directories))
                     (ignored (mapconcat (lambda (i)
                                           (concat "--ignore " i))
                                         (append grep-find-ignored-files
                                                 grep-find-ignored-directories
                                                 (cadr (projectile-parse-dirconfig-file)))
                                         " "))
                     (helm-ag-base-command (concat helm-ag-base-command " " ignored " " options))
                     (current-prefix-arg nil)
                     (ag-directory (if directory directory (projectile-project-root))))
                (helm-do-ag ag-directory (car (projectile-parse-dirconfig-file)) query))
            (symbol-navigation-hydra-error-not-installed "helm-ag"))
        (error "You're not in a project"))
    (symbol-navigation-hydra-error-not-installed "projectile")))

(defun symbol-navigation-hydra-error-not-installed (package-name)
  "Raise an error.

`PACKAGE-NAME' should be the name of the package that isn't installed."
  (error (format "%s not installed. See the Symbol Navigation Hydra README.md"
                 package-name)))

(provide 'symbol-navigation-hydra)

;;; symbol-navigation-hydra.el ends here
