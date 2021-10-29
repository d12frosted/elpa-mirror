;;; windwow.el --- simple workspace management

;; Copyright (C) 2017 Viju Mathew

;; Author: Viju Mathew <viju.jm@gmail.com>
;; Version: 0.1
;; Package-Version: 20170816.148
;; Package-Commit: 77bad26f651744b68d31b389389147014d250f23
;; Created: 12 May 2017
;; Package-Requires: ((dash "2.11.0") (cl-lib "0.6.1") (emacs "24"))
;; Keywords: frames
;; Homepage: github.com/vijumathew/windwow

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides a small collection of functions for saving and
;; loading window and buffer configurations.  A buffer configuration is
;; a list of buffers and a window configuration is an arrangement of windows
;; in a frame.  Right now window configurations created only with split
;; and switch commands are supported.  These functions can be called interactively
;; (via `M-x`) or from keybindings.

;; ## Functions
;; ### Buffer
;;  - `windwow-save-buffer-list` - saves current buffers and prompts for name
;;  - `windwow-load-buffer-list` - loads a previously saved buffer list
;;  - `windwow-load-buffer-from-list` - loads a buffer from a saved buffer list
;;
;; ### Window
;;  - `windwow-save-window-configuration` - saves current window configuration
;;  - `windwow-load-window-configuration` - loads a previously saved window configuration
;;
;; ### Buffer and window
;;  - `windwow-load-window-configuration-and-buffer-list` - loads a window configuration and a buffer list

;;; Code:
(require 'dash)
(require 'cl-lib)

(defvar windwow-list-of-buffer-lists '())
(defvar windwow-list-of-window-commands '())
(defvar windwow-buffer-persistence-file-name)
(defvar windwow-window-persistence-file-name)

(setq windwow-buffer-persistence-file-name
      (expand-file-name "windwow-persist-buffer.eld"
                        user-emacs-directory))

(setq windwow-window-persistence-file-name
      (expand-file-name "windwow-persist-window.eld"
                        user-emacs-directory))

;; persisting the data structures -> based on projectile.el
(defun windwow-save-to-file (data filename)
  "Save DATA to FILENAME."
  (when (file-writable-p filename)
    (with-temp-file filename
      (insert (let (print-length) (prin1-to-string data))))))

(defun windwow-read-from-file (filename)
  "Return content from FILENAME."
  (when (file-exists-p filename)
    (with-temp-buffer
      (insert-file-contents filename)
      (read (buffer-string)))))

(defun windwow-init-vars ()
  "Initialize buffer and window lists."
  (setq windwow-list-of-buffer-lists
        (windwow-read-from-file windwow-buffer-persistence-file-name))
  (setq windwow-list-of-window-commands
        (windwow-read-from-file windwow-window-persistence-file-name)))

(defun windwow-persist-vars-function ()
  "Save buffer and window lists to files."
  (windwow-save-to-file windwow-list-of-buffer-lists
                        windwow-buffer-persistence-file-name)
  (windwow-save-to-file windwow-list-of-window-commands
                        windwow-window-persistence-file-name))

(windwow-init-vars)
(add-hook 'kill-emacs-hook 'windwow-persist-vars-function)

(defun windwow-unload-function ()
  "Remove persist hook.  Called when windwow is unloaded."
  (remove-hook 'kill-emacs-hook 'windwow-persist-vars-function))

;; buffer stuff
(defun windwow-get-buffer-list ()
  "Get names of buffers in current frame."
  (cl-mapcar (lambda (window)
               (buffer-name (window-buffer window)))
             (window-list nil nil (frame-first-window))))

(defun windwow-load-buffer-list-buffers (buffers)
  "Switch to buffers from BUFFERS.  Ignore extra buffers."
  (cl-mapcar (lambda (buffer window)
               (window--display-buffer (get-buffer buffer)
                                       window 'window))
             buffers (window-list nil nil (frame-first-window))))

(defun windwow-get-buffer-list-name (buffers)
  "Make display name for a list of BUFFERS."
  (mapconcat 'identity buffers " "))

;; buffer functions to bind
;;;###autoload
(defun windwow-save-buffer-list (name)
  "Save current buffers as NAME.
Switch to this list of buffers by calling 'windwow-load-buffer-list."
  (interactive
   (list (completing-read "Enter buffer list name: "
                          windwow-list-of-buffer-lists)))
  (let ((buffer-list (windwow-get-buffer-list)))
    (windwow-save-buffer-list-args name buffer-list)))

;;;###autoload
(defun windwow-save-buffer-list-no-name ()
  "Save current buffers as concatenated buffer names.
Switch to this list of buffers by calling 'windwow-load-buffer-list."
  (interactive)
  (let ((buffer-list (windwow-get-buffer-list)))
    (windwow-save-buffer-list-args (windwow-get-buffer-list-name buffer-list)
                                   buffer-list)))

(defun windwow-save-buffer-list-args (name buffers)
  "Store (NAME . BUFFERS) into state.
BUFFERS is a list of buffers.  Used internally by autoloaded functions."
  (setf windwow-list-of-buffer-lists
        (cons (cons name buffers) windwow-list-of-buffer-lists)))

;;;###autoload
(defun windwow-load-buffer-list (buffer-list)
  "Switch to buffers from a BUFFER-LIST that was previously saved."
  (interactive
   (list (completing-read "Load buffer list: "
                          windwow-list-of-buffer-lists
                          nil t "")))
  (windwow-load-buffer-list-buffers (cdr (assoc buffer-list windwow-list-of-buffer-lists))))

;;;###autoload
(defun windwow-load-buffer-from-list (buffer-list buffer)
  "Load BUFFER-LIST and switch to a BUFFER from that list."
  (interactive
   (let* ((list-name (completing-read "Choose buffer-list: " windwow-list-of-buffer-lists))
          (b-cur (completing-read "Choose buffer: " (cdr (assoc list-name
                                                                windwow-list-of-buffer-lists)))))
     (list list-name b-cur)))
  (switch-to-buffer buffer))

;; window stuff
(defun windwow-current-frame-data ()
  "Get dimensions of windows in current frame.
Saved as '(FRAME-WIDTH FRAME-HEIGHT WINDOW-WIDTHS WINDOW-HEIGHTS)
where WINDOW-WIDTHS is a list of window widths and WINDOW-HEIGHTS
is a list of window heights.  This is also referred to as a window-config."
  (let ((parent (frame-root-window)))
    (let ((horiz-frame (window-total-width parent))
          (vert-frame (window-total-height parent))
          (horiz-dimens (-map 'window-total-width (window-list nil nil (frame-first-window))))
          (vert-dimens (-map 'window-total-height (window-list nil nil (frame-first-window)))))
      (list horiz-frame vert-frame horiz-dimens vert-dimens))))

(defun windwow-get-split-window-commands (window-config)
  "Generate split window commands to recreate a WINDOW-CONFIG."
  (windwow-get-split-window-commands-recur window-config nil nil))

(defun windwow-get-split-window-commands-recur (window-config matches commands)
  "Recursive call for generating split window commands of WINDOW-CONFIG.
MATCHES tracks the possible matched split windows at this step of recursion
and COMMANDS tracks current split-window-commands at this step."
  ;; more than one window
  (if (cdar (cddr window-config))
      (let ((matches (windwow-get-possible-splits window-config)))
        (cl-loop for match in matches do
                 (let ((new-set (windwow-remove-from-list match matches))
                       (direction (car match))
                       (new-window-config (windwow-add-to-config (windwow-create-new-window match)
                                                                 (windwow-remove-from-config
                                                                  match window-config))))
                   ;; check for valid window-config here?
                   (let ((result (windwow-get-split-window-commands-recur
                                  new-window-config
                                  new-set
                                  (cons match commands))))
                     (when result
                       (cl-return result))))))
    commands))

(defun windwow-add-to-config (window-pair config)
  "Add a WINDOW-PAIR to a window CONFIG.
The height and width of WINDOW-PAIR are appended by ‘cons’ to
the list of window heights and widths, respectively."
  (let ((first-list (cl-caddr config))
        (second-list (cl-cadddr config)))
    (list (car config) (cadr config)
          (cons (car window-pair) first-list)
          (cons (cdr window-pair) second-list))))

(defun windwow-unzip-cons-cells (cells)
  "Splits CELLS, a list of lists, into list of its ‘car’s and ‘cadr’s."
  (let ((temp (-reduce-from (lambda (memo item)
                              (list (cons (car item) (car memo))
                                    (cons (cdr item) (cadr memo)))) '(nil nil) cells)))
    (list (reverse (car temp)) (reverse (cadr temp)))))

(defun windwow-remove-from-config (split-bundle config)
  "Remove SPLIT-BUNDLE, a split-command and pair of windows, from a window CONFIG."
  (let ((first-list (cl-caddr config))
        (second-list (cl-cadddr config))
        (h-vals (cadr split-bundle))
        (v-vals (cl-caddr split-bundle)))
    (let ((merged-config (-zip first-list second-list))
          (merged (list (cons (car h-vals) (car v-vals))
                        (cons (cdr h-vals) (cdr v-vals)))))
      (let ((removed (windwow-unzip-cons-cells
                      (windwow-remove-from-list (cadr merged)
                                                (windwow-remove-from-list (car merged) merged-config)))))
        (cons (car config) (cons (cadr config) removed))))))

(defun windwow-create-new-window (split-bundle)
  "Create a window from SPLIT-BUNDLE, using the split-command from SPLIT-BUNDLE."
  (if (eql 'vertical (car split-bundle))
      (let ((sum-cell (cadr split-bundle)))
        (cons (+ (car sum-cell) (cdr sum-cell))
              (cl-caaddr split-bundle)))
    (let ((sum-cell (cl-caddr split-bundle)))
      (cons (cl-caadr split-bundle)
            (+ (car sum-cell) (cdr sum-cell))))))

;; add in max value filtering (don't use it if it's impossibly tall)
(defun windwow-get-possible-splits (window-config)
  "Get list of SPLIT-BUNDLES that exist in WINDOW-CONFIG.
These are possible window pairs that can be merged together."
  (let ((windows (cddr window-config))
        (h-max (car window-config))
        (v-max (cadr window-config)))
    (let ((horiz (car windows))
          (vert (cadr windows)))
      (windwow-get-possible-splits-recur horiz vert h-max v-max nil))))

(defun windwow-get-possible-splits-recur (horiz vert h-max v-max directions-and-windows)
  "Recursive call for getting split-bundles.
HORIZ is current horizontal dimension, VERT is current vertical dimension.
H-MAX is horiz of frame, the maximum width, V-MAX is vert of frame,
the maximum height.
DIRECTIONS-AND-WINDOWS is current list of split bundles, which is a list
of split commands and window pairs."
  (if horiz
      (let ((h-matches (windwow-get-match-indices (car horiz) (cdr horiz) vert v-max))
            (v-matches (windwow-get-match-indices (car vert) (cdr vert) horiz h-max)))
        (let ((h-set (windwow-build-sets h-matches horiz vert 'horizontal))
              (v-set (windwow-build-sets v-matches horiz vert 'vertical)))
          (windwow-get-possible-splits-recur (cdr horiz) (cdr vert) h-max v-max
                                             (append directions-and-windows h-set v-set))))
    directions-and-windows))

(defun windwow-get-match-indices (elem coll compare-coll compare-max)
  "Get indices of split window match.
Checks matches of ELEM in COLL while making sure sum of matching
elements (same index) of COMPARE-COLL is less than COMPARE-MAX."
  (windwow-get-match-indices-recur elem coll 0 '() compare-coll compare-max))

(defun windwow-get-match-indices-recur (elem coll index indices compare-coll compare-max)
  "Recursive call for getting matching indices.
Checks if ELEM matches the element in COLL at INDEX, using INDICES to
track matches, while making sure sum of elements in COMPARE-COLL is less
than COMPARE-MAX and they are the result of an exact split window command."
  (if coll
      (windwow-get-match-indices-recur elem (cdr coll) (+ 1 index)
                                       (if (let ((compare-elem-1 (car compare-coll))
                                                 (compare-elem-2 (nth (+ 1 index) compare-coll)))
                                             (and (equal elem (car coll))
                                                  (<= (+ compare-elem-1 compare-elem-2) compare-max)
                                                  (<= (abs (- compare-elem-1 compare-elem-2))
                                                      2))) ;; split window only
                                           (cons index indices)
                                         indices)
                                       compare-coll compare-max)
    indices))

(defun windwow-ordered-cons-cell (v1 v2)
  "Return a cons cell of max and min of elements V1 and V2."
  (cons (max v1 v2)
        (min v1 v2)))

;; return value '((split-direction '(h1 h2) (v1 v2)) ... )
(defun windwow-build-sets (indices h-set v-set direction)
  "Create list of split-bundles.
The split-bundles are window pairs from elements at INDICES and the
first element of H-SET and V-SET and DIRECTION, a split-command."
  (-map (lambda (index)
          (let ((h-val (nth (+ 1 index) h-set))
                (v-val (nth (+ 1 index) v-set)))
            (list direction (windwow-ordered-cons-cell (car h-set) h-val)
                  (windwow-ordered-cons-cell (car v-set) v-val))))
        indices))

(defun windwow-remove-from-list (my-val list)
  "Remove first appearance of MY-VAL from LIST."
  (-remove-first (lambda (x) (equal my-val x)) list))

;; recreate window commands with splits
(defun windwow-get-usable-commands (window-config)
  "Get split and switch commands from WINDOW-CONFIG."
  (let ((commands (windwow-get-split-window-commands window-config)))
    (windwow-get-switch-and-split-commands commands window-config)))

(defun windwow-get-switch-and-split-commands (matches window-config)
  "Get split and switch commands a list of split-bundles and window config.
MATCHES a list of split-bundles - '(SPLIT-COMMAND (H1 . H2) (V1 . V2))
and a WINDOW-CONFIG.  A SPLIT-COMMAND is the symbol ‘horizontal’
or the symbol ‘vertical’.
H1 and H2 are the horizontal dimensions of the window pair, and V1 and
V2 are the vertical dimensions.
This wraps 'windwow-parse-matches which returns commands in reverse order.
The split and switch commands are used to preserve the correct nesting of windows."
  (reverse (windwow-parse-matches matches window-config)))

(defun windwow-parse-matches (split-bundles window-config)
  "Get split and switch commands from SPLIT-BUNDLES and a WINDOW-CONFIG.
The split-bundles are '(split-command (h . h) (v . v)).
This is named 'parse because the split-bundles are used to generate
the switch commands."
  (windwow-parse-matches-recur split-bundles nil 0 (list (cons (car window-config)
                                                               (cadr window-config)))
                               (apply '-zip (cddr window-config))))

(defun windwow-parse-matches-recur (matches commands index window-list final-list)
  "Recursive call for getting split and switch commands.
MATCHES are the unused split-commands, COMMANDS are a list of split and switch
commands.  INDEX is used to track the step of recursion and WINDOW-LIST is a
list of windows."
  (if (windwow-is-empty matches)
      (if (windwow-window-lists-equal window-list final-list)
          commands
        nil)
    (let* ((current (nth index window-list))
           (match (car matches))
           (command (car match))
           (pair (windwow-split-window-pair-in-direction command current)))
      (if (equal pair (windwow-merge-pair (cdr match)))
          (let ((answer
                 (windwow-parse-matches-recur (cdr matches)
                                              (cons command commands)
                                              index
                                              (windwow-insert-split-window-at-index index pair window-list)
                                              final-list)))
            (if answer answer
              (windwow-parse-matches-recur matches
                                           (cons 'switch commands)
                                           (windwow-increment-window-index index window-list)
                                           window-list
                                           final-list)))
        (windwow-parse-matches-recur matches
                                     (cons 'switch commands)
                                     (windwow-increment-window-index index window-list)
                                     window-list
                                     final-list)))))

(defun windwow-window-lists-equal (list-1 list-2)
  (when (eq (length list-1) (length list-2))
    (windwow-window-lists-equal-recur list-1 list-2 t)))

(defun windwow-window-lists-equal-recur (list-1 list-2 val)
  (if (or list-1 list-2)
      (let ((item-1 (car list-1))
            (item-2 (car list-2)))
        (if (equal item-1 item-2)
            (windwow-window-lists-equal-recur (cdr list-1) (cdr list-2) val)
          (let ((next-item-1 (cadr list-1))
                (next-item-2 (cadr list-2)))
            (if (and (equal next-item-1 item-2)
                     (equal next-item-2 item-1))
                (windwow-window-lists-equal-recur (cddr list-1) (cddr list-2) val)
              (windwow-window-lists-equal-recur nil nil nil)))))
    val))

(defun windwow-merge-pair (cells)
  "Change '((A . B) (C . D)) to '((A . C) (B . D)) of CELLS."
  (let ((cell-1 (car cells))
        (cell-2 (cadr cells)))
    (list (cons (car cell-1)
                (car cell-2))
          (cons (cdr cell-1)
                (cdr cell-2)))))

(defun windwow-increment-window-index (index window-list)
  "Increment INDEX by one while modding by length of WINDOW-LIST."
  (mod (+ 1 index) (length window-list)))

(defun windwow-insert-split-window-at-index (index window-pair window-list)
  "Insert at INDEX a WINDOW-PAIR into WINDOW-LIST."
  (-insert-at index (car window-pair)
              (-replace-at index (cadr window-pair) window-list)))

(defun windwow-split-window-pair-in-direction (direction window)
  "Split in DIRECTION a WINDOW, (H . V).
H is the horizontal dimension (width) and V is the
vertical dimension (height) of the window."
  (if (eq direction 'vertical)
      (let ((splitted (windwow-split-dimension (car window))))
        (list (cons (car splitted) (cdr window))
              (cons (cdr splitted) (cdr window))))
    (let ((splitted (windwow-split-dimension (cdr window))))
      (list (cons (car window) (car splitted))
            (cons (car window) (cdr splitted))))))

(defun windwow-split-dimension (dimension)
  "Return DIMENSION split in 2 as a cons cell.
If even it is halved, if not the CAR is greater than the CDR by 1."
  (if (windwow-is-even dimension)
      (let ((half (/ dimension 2)))
        (cons half half))
    (let ((bigger-half (/ (+ dimension 1) 2)))
      (cons bigger-half
            (- bigger-half 1)))))

(defun windwow-is-even (number)
  "Return t if NUMBER is even."
  (= (% number 2) 0))

(defun windwow-is-empty (dis-list)
  "Return t if DIS-LIST is empty."
  (if (and (listp dis-list)
           (car dis-list))
      nil
    t))

;; execute functions
(defun windwow-load-window-configuration-commands (commands)
  "Load and execute a list of split and switch COMMANDS.
Preserves buffers."
  (let ((buffers (windwow-get-buffer-list)))
    (delete-other-windows)
    (windwow-execute-split-window-commands commands)
    (windwow-load-buffer-list-buffers buffers)))

(defun windwow-execute-split-window-commands (commands)
  "Execute a list of split and switch COMMANDS."
  (-each commands (lambda (command)
                    (cond ((eql command 'vertical)
                           (split-window nil nil 'right))
                          ((eql command 'horizontal)
                           (split-window nil nil 'below))
                          ((eql command 'switch)
                           (other-window 1))))))

;; window functions to bind
;;;###autoload
(defun windwow-save-window-arrangement (name)
  "Save current window arrangement as NAME.
Load window arrangement with 'window-load-window-arrangement."
  (interactive
   (list (completing-read "Enter window arrangement name: "
                          windwow-list-of-window-commands)))
  (let ((window-commands (windwow-get-usable-commands (windwow-current-frame-data))))
    (windwow-save-window-configuration-commands name window-commands)))

(defun windwow-save-window-configuration-commands (name window-commands)
  "Internal function for saving current window configuration.
Saves (NAME . WINDOW-COMMANDS) pair."
  (setf windwow-list-of-window-commands
        (cons (cons name window-commands) windwow-list-of-window-commands)))

;;;###autoload
(defun windwow-load-window-arrangement (name)
  "Load NAME, a previously saved window arrangement."
  (interactive
   (list (completing-read "Load window arrangement: "
                          windwow-list-of-window-commands
                          nil t "")))
  (windwow-load-window-configuration-commands (cdr (assoc name windwow-list-of-window-commands))))

;; buffer and window functions
;;;###autoload
(defun windwow-load-window-arrangement-and-buffer-list (commands buffers)
  "Load a window arrangement, COMMANDS,  and a buffer list, BUFFERS."
  (interactive
   (let* ((split-commands-name (completing-read "Choose window arrangement: "
                                                windwow-list-of-window-commands nil t ""))
          (list-name (completing-read "Choose buffer-list: " windwow-list-of-buffer-lists nil t "")))
     (list (assoc split-commands-name
                  windwow-list-of-window-commands)
           (assoc list-name
                  windwow-list-of-buffer-lists))))
  (windwow-load-window-configuration-commands commands)
  (windwow-load-buffer-list-buffers buffers))

(provide 'windwow)
;;; windwow.el ends here
