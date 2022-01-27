;;; bookmark-in-project.el --- Bookmark access within a project -*- lexical-binding: t -*-

;; Copyright (C) 2022  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://gitlab.com/ideasman42/emacs-bookmark-in-project
;; Package-Version: 20220127.449
;; Package-Commit: 0ecafa919d9250668410c050a575d4f2188c48d5
;; Keywords: convenience
;; Version: 0.1
;; Package-Requires: ((emacs "27.1"))

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

;; This package adds functionality for quickly accessing bookmarks within the current projects.
;;

;;; Usage

;; To use this package, bind keys to: \\[bookmark-in-project-toggle]
;; \\[bookmark-in-project-jump-next] \\[bookmark-in-project-jump-previous] and
;; \\[bookmark-in-project-jump].

;;; Code:

;; ---------------------------------------------------------------------------
;; Require Dependencies

(require 'bookmark)
;; Use for creating text for the context at the current point.
(require 'imenu)


;; ---------------------------------------------------------------------------
;; Custom Variables

(defgroup bookmark-in-project nil
  "Bookmarking commands that operate on the current project."
  :group 'bookmark)

(defcustom bookmark-in-project-project-root 'bookmark-in-project-project-root-default
  "Function to call that returns the root path of the current buffer.
A nil return value will fall back to the `default-directory'."
  :type 'function)

(defcustom bookmark-in-project-name 'bookmark-in-project-name-default-with-context
  "Function to call that returns the bookmark name to use.
A nil return value will fall back to the `path:line'."
  :type 'function)

(defcustom bookmark-in-project-name-fontify 'bookmark-in-project-name-default-fontify
  "Function to call that sets font properties for bookmark display.

This takes and returns a string, optionally setting font properties,
set to `identity' to use plain text."
  :type 'function)

(defcustom bookmark-in-project-cycle-order 'sorted
  "Function to call that returns the root path of the current buffer.
A nil return value will fall back to the `default-directory'."
  :type 'symbol)

(defcustom bookmark-in-project-verbose-toggle t
  "Show messages when toggling bookmarks on/off."

  :type 'boolean)
(defcustom bookmark-in-project-verbose-cycle t
  "Show messages when cycling between bookmarks."
  :type 'boolean)


;; ---------------------------------------------------------------------------
;; Generic Macros

(defun bookmark-in-project--canonicalize-path (path)
  "Return the canonical PATH.

This is done without adjusting trailing slashes or following links."
  ;; Some pre-processing on `path' since it may contain the user path
  ;; or be relative to the default directory.
  ;;
  ;; Notes:
  ;; - This is loosely based on `f-same?'` from the `f' library.
  ;;   However it's important this only runs on the user directory and NOT trusted directories
  ;;   since there should never be any ambiguity (which could be caused by expansion)
  ;;   regarding which path is trusted.
  ;; - Avoid `file-truename' since this follows symbolic-links,
  ;;   `expand-file-name' handles `~` and removing `/../' from paths.
  (let ((file-name-handler-alist nil))
    ;; Expand user `~' and default directory.
    (expand-file-name path)))


;; ---------------------------------------------------------------------------
;; Internal Functions/Macros

(defun bookmark-in-project--has-file-name-or-error ()
  "Early exit when there is no buffer."
  (unless buffer-file-name
    (error "Buffer not visiting a file or directory")))

(defun bookmark-in-project--repr-precent (value-fraction value-total)
  "Return a percentage string from VALUE-FRACTION in VALUE-TOTAL."
  (concat
    (number-to-string
      ;; Avoid divide by zero for empty files.
      (cond
        ((zerop value-total)
          0)
        (t
          (/ (* 100 value-fraction) value-total))))
    "%"))

(defmacro bookmark-in-project--without-messages (&rest body)
  "Run BODY with messages suppressed."
  `
  (let
    (
      (inhibit-message t)
      (message-log-max nil))
    ,@body))

(defmacro bookmark-in-project--with-save-deferred (&rest body)
  "Execute BODY with WHERE advice on FN-ORIG temporarily enabled."
  `
  (prog1
    (let ((bookmark-save-flag nil))
      (progn
        ,@body))
    (when (bookmark-time-to-save-p)
      (bookmark-save))))

(defun bookmark-in-project--message (fmt &rest args)
  "Message wrapper, forwards FMT, ARGS to message."
  (let ((message-log-max nil))
    (apply #'message (concat "Bookmark " fmt) args)))

(defun bookmark-in-project-project-root-default ()
  "Function to find the project root from the current buffer.
This checks `ffip', `projectile' & `vc' root,
using `default-directory' as a fallback."
  (cond
    ((fboundp 'ffip-project-root)
      (funcall #'ffip-project-root))
    ((fboundp 'projectile-project-root)
      (funcall #'projectile-project-root))
    (t
      (or
        (when buffer-file-name
          (let ((vc-backend (ignore-errors (vc-responsible-backend buffer-file-name))))
            (when vc-backend
              (vc-call-backend vc-backend 'root buffer-file-name))))))))

(defun bookmark-in-project--project-root-impl ()
  "Return the project directory (or default)."
  ;; Ensure trailing slash, may not be the case for user-defined callbacks,
  ;; needed so it can be used as a prefix of a file without possibly
  ;; matching against other, longer directory names.
  (file-name-as-directory (or (funcall bookmark-in-project-project-root) default-directory)))

(defun bookmark-in-project--context-id-at-point (pos)
  "Return context text at POS (used for automatic bookmark names)."
  ;; Ensure `imenu--index-alist' is populated.
  (condition-case-unless-debug err
    ;; Note that in some cases a file will fail to parse,
    ;; typically when the file is intended for another platform (for example).
    (imenu--make-index-alist)
    (error (message "imenu failed: %s" (error-message-string err))))

  ;; As this function searches backwards to get the closest point before `pos',
  ;; account for the current `imenu' position being on the same line as the point.
  (setq pos
    (save-excursion
      (goto-char pos)
      (line-end-position)))

  (let
    (
      (alist imenu--index-alist)
      (pair nil)
      (mark nil)
      (imstack nil)
      (result nil)
      (result-stack (list))
      (pos-best -1)
      (pos-best-depth nil)
      (pos-depth 0)
      (pos-next (point-max)))
    ;; Elements of alist are either ("name" . marker), or
    ;; ("submenu" ("name" . marker) ... ). The list can be
    ;; Arbitrarily nested.
    (while (or alist imstack)
      (cond
        (alist
          (setq pair (car-safe alist))
          (setq alist (cdr-safe alist))
          (cond
            ((atom pair)) ;; Skip anything not a cons.
            ((imenu--subalist-p pair)
              (setq imstack (cons alist imstack))
              (setq alist (cdr pair))
              (setq pos-depth (1+ pos-depth))
              (push (car pair) result-stack))
            ((number-or-marker-p (setq mark (cdr pair)))
              (let ((pos-test (marker-position mark)))
                (when (and (> pos-test pos-best) (> pos pos-test))
                  ;; Store result and it's parents.
                  (setq result (cons (car pair) result-stack))
                  (setq pos-best pos-test)
                  (setq pos-best-depth pos-depth))))))
        (t
          (setq alist (car imstack))
          (setq imstack (cdr imstack))
          (setq pos-depth (1- pos-depth))
          (pop result-stack))))

    ;; Loop again to calculate 'pos-next',
    ;; do this in a separate loop since we need to be sure the nested depth
    ;; is not greater than the item directly before the cursor since it doesn't
    ;; make sense to calculate the percentage - limiting it by child nodes of the current scope.
    (when pos-best-depth
      (setq alist imenu--index-alist)
      (setq imstack nil)
      (while (or alist imstack)
        (cond
          (alist
            (setq pair (car-safe alist))
            (setq alist (cdr-safe alist))
            (setq pos-depth (1+ pos-depth))
            (cond
              ((atom pair)) ;; Skip anything not a cons.
              ((imenu--subalist-p pair)
                (setq imstack (cons alist imstack))
                (setq alist (cdr pair)))
              ((number-or-marker-p (setq mark (cdr pair)))
                ;; Ensure the next item isn't nested.
                (when (<= pos-depth pos-best-depth)
                  (let ((pos-test (marker-position mark)))
                    (when (and (> pos-next pos-test) (> pos-test pos))
                      (setq pos-next pos-test)))))))
          (t
            (setq alist (car imstack))
            (setq imstack (cdr imstack))
            (setq pos-depth (1- pos-depth))))))

    (cond
      (result
        (let
          ( ;; Join the list of
            (text
              (string-join
                (mapcar
                  (lambda (text)
                    ;; Some `imenu' back-ends (lsp for example),
                    ;; add additional type info with properties.
                    ;; In our case the identifier is enough, so clip off any additional info.
                    (substring-no-properties text 0 (next-property-change 0 text)))
                  (reverse result))
                ", ")))

          (let ((lines-rel (count-lines pos-best pos)))
            ;; No need to show the percentage if the point is exactly at the definition.
            (when (< 1 lines-rel)
              (let ((lines-all (count-lines pos-best pos-next)))
                (setq text
                  (concat
                    text " [" (bookmark-in-project--repr-precent lines-rel lines-all) "]")))))

          text))
      (t ;; No context, show the percent in the file.
        ;; NOTE: always show the percentage even when '0%'.
        ;; Otherwise there is no context given which seems strange.
        (let ((lines-rel (count-lines (point-min) pos)))
          (let ((lines-all (count-lines (point-min) (point-max))))
            (concat "[" (bookmark-in-project--repr-precent lines-rel lines-all) "]")))))))

(defun bookmark-in-project-name-default-with-line ()
  "Return the name used to create ."
  (let ((filepath (bookmark-in-project--canonicalize-path (buffer-file-name))))
    (format "%s: %d" filepath (line-number-at-pos (point) t))))

(defun bookmark-in-project-name-default-with-context ()
  "Return the name used to create ."
  (let ((filepath (bookmark-in-project--canonicalize-path (buffer-file-name))))
    (format "%s: %s" filepath (bookmark-in-project--context-id-at-point (point)))))

(defun bookmark-in-project-name-default-fontify (name)
  "Apply face property to the bookmark NAME (for display only)."
  (save-match-data
    (let
      ( ;; Expect format as follows:
        ;;   file/path.ext: <some content> [12%]
        (content-beg 0)
        (content-end (length name)))
      ;; Match: "/file/path: "
      (when (string-match "\\(.+\\)\\(: \\)" name)
        (add-face-text-property (match-beginning 1) (match-end 1) 'font-lock-constant-face t name)
        (setq content-beg (match-end 2)))
      ;; Match: " [12%]"
      (when (string-match "\\(\\[[[:digit:]]+%\\]\\)" name content-beg)
        (setq content-end (match-beginning 1)))
      ;; Set the face property for any content between the path and the percentage.
      (add-face-text-property content-beg content-end 'font-lock-doc-face t name)

      ;; Syntax highlight delimiters/punctuation: [],
      (let ((delimit-iter content-beg))
        (while (string-match "[[:punct:]]+" name delimit-iter)
          (add-face-text-property
            (match-beginning 0)
            (setq delimit-iter (match-end 0))
            'font-lock-delimit-face
            t
            name)))))
  name)

(defun bookmark-in-project--name-ensure-unique (name bm-list)
  "Ensure NAME is unique in BM-LIST, returning the unique name."
  ;; Remove the number suffix (so there is no chance we add multiple).
  (setq name (replace-regexp-in-string "~[[:digit:]]+'" "" name))

  (let ((name-ls-exists (list)))
    (while bm-list
      (let ((item (car bm-list)))
        (setq bm-list (cdr bm-list))
        (let ((name-test (car item)))
          (when (string-prefix-p name name-test)
            (push name-test name-ls-exists)))))
    (let ((name-unique name))
      (let ((index 1))
        (while (member name-unique name-ls-exists)
          (setq name-unique (format "%s~%d" name index))
          (setq index (1+ index))))
      name-unique)))

(defun bookmark-in-project--name-impl (bm-list)
  "Return a new name (unique in BM-LIST)."
  (bookmark-in-project--name-ensure-unique
    (or (funcall bookmark-in-project-name) (bookmark-in-project-name-default-with-line))
    bm-list))


(defun bookmark-in-project--name-abbrev (proj-dir name)
  "Abbreviate NAME (in this case, strip PROJ-DIR)."
  (cond
    ((string-prefix-p proj-dir name)
      (substring name (length proj-dir) nil))
    (t
      name)))

(defun bookmark-in-project--name-abbrev-or-nil (proj-dir name)
  "A version of `bookmark-in-project--name-abbrev' that accepts NAME as NIL.
See `bookmark-in-project--name-abbrev' for PROJ-DIR docs."
  (cond
    (name
      (bookmark-in-project--name-abbrev proj-dir name))
    (t
      nil)))

(defun bookmark-in-project--name-abbrev-and-fontify (proj-dir name)
  "Return a copy of NAME, abbreviated & optionally with the face property set.
Argument PROJ-DIR may be used for abbreviation."

  ;; Strip the project prefix (for brief/convenient display).
  (setq name (bookmark-in-project--name-abbrev proj-dir name))

  (cond
    (bookmark-in-project-name-fontify
      ;; While this should never fail, since it's a user-defined callback, fail gracefully.
      (condition-case-unless-debug err
        (funcall bookmark-in-project-name-fontify (substring-no-properties name))
        (error (message "Setting faces failed: %s" (error-message-string err)) name)))
    (t
      name)))

(defun bookmark-in-project--filter-by-project (proj-dir bm-list)
  "Filter BM-LIST by PROJ-DIR."
  (let ((bm-list-filter (list)))
    (while bm-list
      (let ((item (car bm-list)))
        (setq bm-list (cdr bm-list))
        (when (string-prefix-p proj-dir (bookmark-in-project--item-get-filename item))
          (push item bm-list-filter))))
    bm-list-filter))

;; TODO, the buffer narrowing checks should be generalized.
(defun bookmark-in-project--item-is-visible (item)
  "Return t if ITEM is visible (not narrowed).
Note that if the file is not opened, it's assumed not to be narrowed."
  (let
    (
      (filename (abbreviate-file-name (bookmark-in-project--item-get-filename item)))
      (visible t))
    (let ((buf (get-file-buffer filename)))
      (when buf
        (with-current-buffer buf
          (when (buffer-narrowed-p)
            (save-excursion
              (let
                (
                  (point-narrow-min (point-min))
                  (point-narrow-max (point-max)))
                (save-restriction
                  (widen)
                  (bookmark-jump (car item))
                  (unless (and (<= point-narrow-min (point)) (<= (point) point-narrow-max))
                    (setq visible nil)))))))))
    visible))

(defun bookmark-in-project--filter-by-narrowing (bm-list)
  "Filter BM-LIST, removing any items that are narrowed."
  (let ((bm-list-filter (list)))
    (while bm-list
      (let ((item (car bm-list)))
        (setq bm-list (cdr bm-list))
        (when (bookmark-in-project--item-is-visible item)
          (push item bm-list-filter))))
    bm-list-filter))

(defun bookmark-in-project--name-abbrev-and-fontify-list (proj-dir bm-list)
  "Apply faces to all items in BM-LIST.
Argument PROJ-DIR may be used for abbreviation."
  (mapcar
    (lambda (item)
      (cons (bookmark-in-project--name-abbrev-and-fontify proj-dir (car item)) (cdr item)))
    bm-list))


;; ---------------------------------------------------------------------------
;; Bookmark Function Implementation

(defun bookmark-in-project--placeholder-item (direction)
  "Create a fake bookmark item for the purpose of comparison.
Argument DIRECTION represents the stepping direction (in -1 1)."
  (cons
    "<fake-bookmark>"
    (list
      (cons 'filename buffer-file-name)
      (cons
        'position
        (pcase direction
          (+1 (max (1+ (point)) (line-end-position)))
          (-1 (min (1- (point)) (line-beginning-position)))
          (_ (error "Invalid direction")))))))

(defun bookmark-in-project--item-handle-or-nil (item)
  "Jump to ITEM, returning non-nil on success."
  (let ((bookmark-name-or-record (car item)))
    (condition-case _err
      (progn
        (funcall
          (or (bookmark-get-handler bookmark-name-or-record) 'bookmark-default-handler)
          (bookmark-get-bookmark bookmark-name-or-record))
        t)
      (error nil))))


(defun bookmark-in-project--item-get-filename (item)
  "Return the filename from a bookmark (ITEM)."
  (let
    (
      (filepath
        (or
          (alist-get 'filename item)
          ;; Filename from the buffer.
          (let ((buf (alist-get 'buf item)))
            (when (stringp buf)
              (setq buf (get-buffer buf)))
            (when buf
              (buffer-file-name buf))))))
    (cond
      (filepath
        (bookmark-in-project--canonicalize-path filepath))
      (t
        ""))))

(defun bookmark-in-project--item-get-position (item)
  "Return the position of bookmark ITEM.
Note that this must only run on the for bookmarks in the current buffer,
otherwise it will switch the buffer."
  ;; Note that edits to the document mean: (alist-get 'position item)
  ;; May not reflect the location after the context has been used to resolve the actual point.
  ;; For this reason, the actual jump call is needed.
  (save-excursion
    (bookmark-handle-bookmark (car item))
    (point)))

;; Extracted from: `bookmark-handle-bookmark',
;; Doesn't attempt to handle errors, just skip them.
(defun bookmark-in-project--item-get-position-or-nil (item)
  "Return the position of bookmark ITEM.
Note that this must only run on the for bookmarks in the current buffer,
otherwise it will switch the buffer."
  ;; Note that edits to the document mean: (alist-get 'position item)
  ;; May not reflect the location after the context has been used to resolve the actual point.
  ;; For this reason, the actual jump call is needed.
  (save-excursion
    (cond
      ((bookmark-in-project--item-handle-or-nil item)
        (point))
      (t
        nil))))

(defun bookmark-in-project--compare (a b)
  "Return t when A is less than B."
  (let
    (
      (a-fn (bookmark-in-project--item-get-filename a))
      (b-fn (bookmark-in-project--item-get-filename b)))
    (cond
      ((string-lessp a-fn b-fn)
        t)
      ((string-equal a-fn b-fn)
        (let
          (
            (a-pos (alist-get 'position a 1))
            (b-pos (alist-get 'position b 1)))
          (< a-pos b-pos)))
      (t
        nil))))


;; ---------------------------------------------------------------------------
;; Bookmark Relative Navigation Next/Previous

(defun bookmark-in-project--bookmarks-by-file-vector (bm-list &optional extra-files)
  "Return a sorted vector of `(file-path . bm-list)' pairs from BM-LIST.
Optionally include EXTRA-FILES (dummy files useful for ordering)."
  (let
    (
      (filepath-bm-list-pairs nil)
      (files-map (make-hash-table :test #'equal)))
    (while extra-files
      (puthash (pop extra-files) nil files-map))
    (while bm-list
      (let*
        (
          (item (pop bm-list))
          (filepath-iter (bookmark-in-project--item-get-filename item))
          (bm-list-local (gethash filepath-iter files-map)))

        ;; Maintain a list of items.
        (puthash filepath-iter (cons item bm-list-local) files-map)))

    (maphash (lambda (key value) (push (cons key value) filepath-bm-list-pairs)) files-map)
    (vconcat (sort filepath-bm-list-pairs (lambda (a b) (string-lessp (car a) (car b)))))))

(defun bookmark-in-project--bm-list-sorted-with-pos-and-valid (bm-list)
  "Return a list of (position . item) pairs from BM-LIST."
  (let
    (
      (bm-list-with-pos-and-valid
        (mapcar
          (lambda (item)
            ;; Real location, or stored location or a fallback.
            (let*
              (
                (pos-real (bookmark-in-project--item-get-position-or-nil item))
                (pos (or pos-real (alist-get 'position item 1))))
              (list item pos (not (null pos-real)))))
          bm-list)))
    ;; Sort by fallback position.
    (sort bm-list-with-pos-and-valid (lambda (a b) (< (cadr a) (cadr b))))))

(defun bookmark-in-project--step-in-buffer (bm-list direction filepath-current pos-current)
  "Return the next/previous based on DIRECTION (item . is-valid) in BM-LIST.
Arguments FILEPATH-CURRENT & POS-CURRENT are used as a reference.
When no bookmark is found in the buffer, return nil."
  ;; Take care, `filepath-current' and `pos-current' may not be the current buffer
  ;; so avoid (point-min) or anything that relies on the current buffers values.
  (setq filepath-current (bookmark-in-project--canonicalize-path filepath-current))
  (let
    (
      (bm-list-local (list))
      (item-with-valid nil)
      (i 0)
      (pos-best
        (cond
          ((< direction 0)
            0)
          (t
            most-positive-fixnum))))
    (while bm-list
      (let ((item (pop bm-list)))
        (when (string-equal filepath-current (bookmark-in-project--item-get-filename item))
          (push item bm-list-local))))

    (when bm-list-local
      (let
        (
          (bm-list-local-with-pos-and-valid
            (bookmark-in-project--bm-list-sorted-with-pos-and-valid bm-list-local)))
        (while bm-list-local-with-pos-and-valid
          (pcase-let ((`(,item ,pos ,is-valid) (pop bm-list-local-with-pos-and-valid)))
            (when
              (cond
                ((< direction 0)
                  (and (< pos-best pos) (> pos-current pos)))
                (t
                  (and (> pos-best pos) (< pos-current pos))))
              (setq pos-best pos)
              (setq item-with-valid (cons item is-valid))))
          (setq i (1+ i)))))

    item-with-valid))

(defun bookmark-in-project--step-the-buffer (bm-list direction)
  "Step into a buffer in BM-LIST along DIRECTION, returning (item . is-valid)."
  (let*
    (
      (item-with-valid nil)
      (filepath-current (bookmark-in-project--canonicalize-path (buffer-file-name)))
      (filepath-bm-list-pairs
        (bookmark-in-project--bookmarks-by-file-vector bm-list (list filepath-current)))
      (i-best nil))

    (let*
      (
        (files-len (length filepath-bm-list-pairs))
        (i files-len))
      (when (> i 1)
        (while (not (zerop i))
          (setq i (1- i))
          (when (string-equal filepath-current (car (aref filepath-bm-list-pairs i)))
            (setq i-best i)
            ;; Break.
            (setq i 0))))

      ;; It's possible there is only one buffer, in that case do nothing.
      (when i-best
        ;; We could check the file exists.
        (setq i (mod (+ i-best direction) files-len))
        (pcase-let ((`(,filepath-next . ,bm-list-local) (aref filepath-bm-list-pairs i)))
          (setq item-with-valid
            (bookmark-in-project--step-in-buffer
              bm-list-local direction filepath-next
              (cond
                ((< direction 0)
                  most-positive-fixnum)
                (t
                  0)))))))

    item-with-valid))

(defun bookmark-in-project--step-any (bm-list direction)
  "Step along DIRECTION in BM-LIST relative to the current buffer."
  (or
    (bookmark-in-project--step-in-buffer
      bm-list direction (buffer-file-name)
      (cond
        ((< direction 0)
          (line-beginning-position))
        (t
          (line-end-position))))
    (bookmark-in-project--step-the-buffer bm-list direction)
    ;; When there is only a single buffer, wrap back around to the start.
    (bookmark-in-project--step-in-buffer
      bm-list direction (buffer-file-name)
      (cond
        ((< direction 0)
          most-positive-fixnum)
        (t
          0)))))

(defun bookmark-in-project--calc-global-index (bm-list item)
  "Calculate the global index for ITEM in BM-LIST."
  (let*
    (
      (filepath-item (bookmark-in-project--item-get-filename item))
      (filepath-bm-list-pairs (bookmark-in-project--bookmarks-by-file-vector bm-list))
      (filepath-bm-list-pairs-len (length filepath-bm-list-pairs))
      (index 0)
      (i 0))

    (while (< i filepath-bm-list-pairs-len)
      (pcase-let ((`(,filepath-iter . ,bm-list-iter) (aref filepath-bm-list-pairs i)))
        (cond
          ((string-equal filepath-iter filepath-item)
            (let
              (
                (bm-list-local-with-pos-and-valid
                  (bookmark-in-project--bm-list-sorted-with-pos-and-valid bm-list-iter)))

              (while bm-list-local-with-pos-and-valid
                (pcase-let ((`(,item-iter ,_ ,_) (pop bm-list-local-with-pos-and-valid)))
                  (when (eq item-iter item)
                    ;; Break.
                    (setq bm-list-local-with-pos-and-valid nil)
                    (setq i filepath-bm-list-pairs-len)))
                (setq index (1+ index)))))
          (t
            (setq index (+ index (length bm-list-iter))))))
      (setq i (1+ i)))
    index))

(defun bookmark-in-project--default-name-at-point ()
  "Return the default name to use (based on surrounding context)."
  (let ((item (bookmark-in-project--find-at-point nil)))
    (cond
      (item
        (car item))
      (t
        bookmark-current-bookmark))))

(defun bookmark-in-project--jump-direction-impl (proj-dir bm-list direction)
  "Step bookmark in DIRECTION direction in PROJ-DIR & BM-LIST."

  (let
    ( ;; Track the number of failed attempts (report this when verbose).
      (skip 0)
      (item-with-valid nil)
      (bm-list-orig
        (cond
          (bookmark-in-project-verbose-cycle
            bm-list)
          (t
            nil))))

    (let ((keep-searching t))
      (while (and keep-searching bm-list (null item-with-valid))
        (setq item-with-valid (bookmark-in-project--step-any bm-list direction))
        (cond
          (item-with-valid
            (pcase-let ((`(,item . ,is-valid) item-with-valid))
              (unless is-valid
                ;; Lazy initialize a copy of `bm-list' before modifying it.
                (when (zerop skip)
                  (when bookmark-in-project-verbose-cycle
                    (setq bm-list-orig (copy-sequence bm-list))))
                (setq bm-list
                  (delete item
                    bm-list))
                (setq skip (1+ skip))
                (setq item-with-valid nil))))
          (t
            (setq keep-searching nil)))))

    (cond
      (item-with-valid
        (pcase-let ((`(,item . ,_is-valid) item-with-valid))
          ;; Call jump (non-interactively).
          (bookmark-jump item)

          (when bookmark-in-project-verbose-cycle
            (let ((name (car item)))
              (bookmark-in-project--message "(%s) %d of %d: %s%s"
                (cond
                  ((< direction 0)
                    "prev")
                  (t
                    "next"))
                (bookmark-in-project--calc-global-index bm-list-orig item)
                (length bm-list-orig)
                (bookmark-in-project--name-abbrev-and-fontify proj-dir name)
                (cond
                  ((zerop skip)
                    "")
                  (t
                    (format " (%d skipped)" skip))))))))
      (t
        ;; Note that his is  unlikely.
        (when bookmark-in-project-verbose-cycle
          (bookmark-in-project--message "unable to cycle %d bookmarks in %S!"
            (length bm-list)
            proj-dir))))))

(defun bookmark-in-project--jump-direction (direction)
  "Jump between bookmarks in DIRECTION (+1/-1)."
  (let ((proj-dir (bookmark-in-project--project-root-impl)))
    (let
      (
        (bm-list
          (bookmark-in-project--filter-by-narrowing
            (bookmark-in-project--filter-by-project proj-dir bookmark-alist))))
      (cond
        ((null bm-list)
          (bookmark-in-project--message "none found in %S!" proj-dir))
        (t
          (bookmark-in-project--jump-direction-impl proj-dir bm-list direction))))))

(defun bookmark-in-project--jump-impl (command)
  "Run a jump COMMAND with project limited context."
  (let ((proj-dir (bookmark-in-project--project-root-impl)))
    (let
      (
        (bm-list
          (sort
            (bookmark-in-project--filter-by-project proj-dir bookmark-alist)
            #'bookmark-in-project--compare))
        (bm-current-bookmark-new nil))
      (let
        ( ;; Already sorted.
          (bookmark-sort-flag nil)

          (bookmark-alist (bookmark-in-project--name-abbrev-and-fontify-list proj-dir bm-list))
          ;; Strip the prefix (so it's compatible).
          (bookmark-current-bookmark
            (bookmark-in-project--name-abbrev-or-nil
              proj-dir
              (bookmark-in-project--default-name-at-point))))

        ;; Call a jump command, e.g. `bookmark-jump', `bookmark-jump-other-window' .. etc.
        (cond
          ;; Ivy gives a minor advantage that it's possible to activate bookmarks
          ;; without closing the completing read.
          ((fboundp 'ivy-read)
            (ivy-read
              "Jump to bookmark: "
              ;; Content.
              bookmark-alist
              :preselect bookmark-current-bookmark
              :require-match t
              :action (lambda (item) (funcall command (car item)))
              :caller command))
          ;; No ivy integration (default `completing-read').
          (t
            (call-interactively command)))

        (when bookmark-current-bookmark
          (setq bm-current-bookmark-new
            (bookmark-in-project--remap-name bookmark-alist bm-list bookmark-current-bookmark))))

      ;; Set the expanded name back.
      (when bm-current-bookmark-new
        (setq bookmark-current-bookmark bm-current-bookmark-new)))))

(defun bookmark-in-project--find-at-point (current-line-only)
  "Return the closest bookmark to the current point.
Argument CURRENT-LINE-ONLY when non-nil,
only bookmarks on the current line will be considered."
  (let
    (
      (current-filename
        (bookmark-in-project--item-get-filename (bookmark-in-project--placeholder-item 1))))
    (cond
      ((string-empty-p current-filename)
        nil)
      (t
        (let
          (
            (bm-list bookmark-alist)
            (pos-delta-best most-positive-fixnum)
            (item-found nil)
            (bol (line-beginning-position))
            (eol (line-end-position)))
          (while bm-list
            (let ((item (car bm-list)))
              (setq bm-list (cdr bm-list))
              (when (string-equal current-filename (bookmark-in-project--item-get-filename item))
                (let ((pos (bookmark-in-project--item-get-position item)))
                  (when
                    (cond
                      (current-line-only
                        (and (<= bol pos) (<= pos eol)))
                      (t
                        (<= pos eol)))
                    (let ((pos-delta-test (abs (- pos (point)))))
                      (when (< pos-delta-test pos-delta-best)
                        (setq item-found item)
                        (setq pos-delta-best pos-delta-test))))))))
          item-found)))))

(defun bookmark-in-project--remap-name (bm-list-src bm-list-dst name)
  "Translate NAME from it's value in BM-LIST-SRC to it's value in BM-LIST-DST."
  (let ((result name))
    (while bm-list-src
      (let
        (
          (item-src (car bm-list-src))
          (item-dst (car bm-list-dst)))

        (setq bm-list-src (cdr bm-list-src))
        (setq bm-list-dst (cdr bm-list-dst))

        (when (string-equal name (car item-src))
          (setq result (car item-dst))
          ;; Break.
          (setq bm-list-src nil))))
    result))

;; ---------------------------------------------------------------------------
;; Public Functions/Macros

;;;###autoload
(defun bookmark-in-project-jump-next ()
  "Jump to the next bookmark."
  (interactive)
  (bookmark-maybe-load-default-file)
  (bookmark-in-project--jump-direction 1))

;;;###autoload
(defun bookmark-in-project-jump-previous ()
  "Jump to the previous bookmark."
  (interactive)
  (bookmark-maybe-load-default-file)
  (bookmark-in-project--jump-direction -1))

;;;###autoload
(defun bookmark-in-project-jump ()
  "Jump to a bookmark in the current project."
  (interactive)
  (bookmark-maybe-load-default-file)
  (bookmark-in-project--jump-impl #'bookmark-jump))

;;;###autoload
(defun bookmark-in-project-jump-other-window ()
  "Jump to a bookmark in another window, see `bookmark-in-project-jump'."
  (interactive)
  (bookmark-maybe-load-default-file)
  (bookmark-in-project--jump-impl #'bookmark-jump-other-window))

;;;###autoload
(defun bookmark-in-project-jump-other-frame ()
  "Jump to a bookmark in another frame, see `bookmark-in-project-jump'."
  (interactive)
  (bookmark-maybe-load-default-file)
  (bookmark-in-project--jump-impl #'bookmark-jump-other-frame))

;;;###autoload
(defun bookmark-in-project-toggle ()
  "Create or delete a bookmark on the current line."
  (interactive)

  ;; Don't go any further if this buffer doesn't have a file-name.
  ;; This is only needed for setting bookmarks, navigation can use the default-directory.
  (bookmark-in-project--has-file-name-or-error)

  (bookmark-maybe-load-default-file)
  ;; Only accept bookmarks on the current line.
  (let ((item-current (bookmark-in-project--find-at-point t)))
    (cond
      (item-current
        (let ((name (car item-current)))
          ;; Quiet messages when `bookmark-save-flag' is 0.
          (bookmark-in-project--without-messages (bookmark-delete name))
          ;; Message after to hide "Saved".
          (when bookmark-in-project-verbose-toggle
            (bookmark-in-project--message "deleted: %s"
              (let ((proj-dir (bookmark-in-project--project-root-impl)))
                (bookmark-in-project--name-abbrev-and-fontify proj-dir name))))))
      (t
        (let ((name (bookmark-in-project--name-impl bookmark-alist)))
          ;; Quiet messages when `bookmark-save-flag' is 0.
          (bookmark-in-project--without-messages (bookmark-set name))
          (when bookmark-in-project-verbose-toggle
            (bookmark-in-project--message "added: %s"
              (let ((proj-dir (bookmark-in-project--project-root-impl)))
                (bookmark-in-project--name-abbrev-and-fontify proj-dir name)))))))))

;;;###autoload
(defun bookmark-in-project-delete-all (&optional no-confirm)
  "Delete all bookmarks in the project.
If optional argument NO-CONFIRM is non-nil, don't ask for
confirmation."
  (interactive "P")
  (let ((proj-dir (bookmark-in-project--project-root-impl)))
    (when
      (or
        no-confirm
        (yes-or-no-p (format "Permanently delete bookmarks in this project [%S] ? " proj-dir)))
      (bookmark-maybe-load-default-file)
      (let ((bm-list (bookmark-in-project--filter-by-project proj-dir bookmark-alist)))
        (when bm-list
          (bookmark-in-project--with-save-deferred
            (while bm-list
              (let ((item (car bm-list)))
                (setq bm-list (cdr bm-list))
                (let ((name (car item)))
                  ;; Errors should not happen, even so - don't early exit if they do.
                  (with-demoted-errors (bookmark-delete name)))))))))))

(provide 'bookmark-in-project)
;;; bookmark-in-project.el ends here
