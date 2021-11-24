;;; outrespace.el --- Some c++ namespace utility functions
;; Copyright (C) 2016-2019  Dan Harms (dharms)
;; Author: Dan Harms <danielrharms@gmail.com>
;; Created: Wednesday, June  1, 2016
;; Version: 0.1
;; Package-Version: 20190724.1553
;; Package-Commit: d8c1619ec81fd3f4e728212a3526cd13bc2b0147
;; Modified Time-stamp: <2019-07-24 10:53:07 dan.harms>
;; Modified by: Dan Harms
;; Keywords: tools c++ namespace
;; URL: https://github.com/articuluxe/outrespace.git
;; Package-Requires: ((emacs "24.4"))

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
;; `Outrespace' is a collection of utilities to manage c++ namespaces.
;;

;;; Code:
(require 'subr-x)
(require 'seq)
(require 'ivy nil t)

(defgroup outrespace nil
  "C++ namespace wrangler."
  :group 'programming
  :prefix "outrespace")

(defvar-local outrespace-list nil
  "List of namespaces in the current buffer.")

(defcustom outrespace-prefix-key (kbd "C-c C-`")
  "Prefix key for `outrespace-mode'."
  :type 'vector)

(defface outrespace-highlight-face
  '((t :inherit highlight))
  "Font lock mode face used to highlight namespace names.")

(defvar outrespace-anon-name "<anon>"
  "A display name for anonymous namespaces.")

(defvar outrespace-debug nil
  "Whether to print debugging statistics to the `*Messages*' buffer.")

(defvar outrespace--select-ns-func
  (if (featurep 'ivy) 'outrespace--select-ns-ivy
    'outrespace--select-ns-standard)
  "The function by which to select a namespace by name.")

(defun outrespace-in-comment-or-string ()
  "Return non-nil if point is within a comment or string."
  (or (nth 3 (syntax-ppss))
      (nth 4 (syntax-ppss))))

(defun outrespace-not-in-comment-or-string ()
  "Return non-nil if point is not within a comment or string."
  (not (outrespace-in-comment-or-string)))

(defun outrespace--move-point-to-ns (ns)
  "Move point to namespace NS."
  (goto-char (car (outrespace--get-ns-delimiter-pos ns))))

(defun outrespace--on-namespace-selected (ns)
  "Highlight a namespace NS."
  (let ((name (outrespace--get-ns-name-pos ns))
        beg end str ov)
    (outrespace--move-point-to-ns ns)
    (setq beg (car name))
    (setq end (cadr name))
    (setq str (buffer-substring-no-properties beg end))
    (when str
      (setq ov (make-overlay beg end))
      (overlay-put ov 'face 'outrespace-highlight-face)
      (sit-for 1)
      (delete-overlay ov))
    ))

(defun outrespace--scan-all-ns ()
  "Scan current buffer for all namespaces."
  (save-excursion
    (widen)
    (let (lst beg curr cont parent)
      (goto-char (point-min))
      (while (setq beg (outrespace--find-ns-next))
        (setq cont
              (if (and
                   beg
                   (setq
                    parent
                    (catch 'found
                      (dolist (elt lst)
                        (if (outrespace--get-distance-from-begin beg elt)
                            (throw 'found elt) nil)))))
                  (cadr (outrespace--get-ns-names parent))
                nil))
        (catch 'invalid
          (setq curr (outrespace-parse-namespace beg cont))
          (if (outrespace--namespace-nested-p curr)
              (let* ((name-pos (outrespace--get-ns-name-pos curr))
                     (posb (car name-pos))
                     (pose (cadr name-pos)))
                (mapc
                 (lambda (elt)
                   (setq lst
                         (cons
                          (list
                           (list (car elt)
                                 (setq cont
                                       (if cont
                                           (concat cont "::" (car elt))
                                         (car elt))))
                           (outrespace--get-ns-tag-pos curr)
                           (list
                            (+ posb (cdr elt))
                            (+ posb (cdr elt) (length (car elt))))
                           (outrespace--get-ns-delimiter-pos curr))
                          lst)))
                 (outrespace--flatten-nested-names
                  (buffer-substring-no-properties posb pose))))
            (setq lst (cons curr lst)))))
      lst)))

(defun outrespace-scan-buffer ()
  "Scan current buffer for all namespaces.
Store in result `outrespace-list'."
  (interactive)
  (let ((start (current-time)))
    (setq outrespace-list (outrespace--scan-all-ns))
    (when outrespace-debug
      (message "It took %.3f sec. to scan buffer's namespaces"
               (float-time (time-subtract (current-time) start))))))

;;;###autoload
(defun outrespace-goto-namespace-next ()
  "Move point to the next start of a valid namespace."
  (interactive)
  (let (ns)
    (when (catch 'found
            (save-excursion
              (let ((beg (outrespace--find-ns-next)))
                (setq ns (catch 'invalid
                           (and beg (outrespace-parse-namespace beg))))
                (if ns
                    (throw 'found t)
                  (message "no namespace following point")
                  nil))))
      (outrespace--on-namespace-selected ns))))

;;;###autoload
(defun outrespace-goto-namespace-previous ()
  "Move point to the prior start of a valid namespace."
  (interactive)
  (let ((pt (point))
        ns)
    (when (catch 'found
            (save-excursion
              (let ((beg (outrespace--find-ns-previous))
                    delim)
                (setq ns (catch 'invalid
                           (and beg (outrespace-parse-namespace beg))))
                (setq delim (and ns (outrespace--get-ns-delimiter-pos ns)))
                ;; If between delimiters, choose current.
                ;; If outside (before) delimiters, search for previous.
                ;; This seems to work intuitively; but relies on point
                ;; being before the beginning delimiter when a namespace
                ;; is selected.
                (when delim
                  (unless (< (car delim) pt)
                    (setq beg (outrespace--find-ns-previous))
                    (setq ns (catch 'invalid
                               (and beg (outrespace-parse-namespace beg))))))
                (if ns
                    (throw 'found t)
                  (message "no namespace preceding point")
                  nil))))
      (outrespace--on-namespace-selected ns))))

(defun outrespace--find-ns-next ()
  "Return location of beginning of next valid namespace."
  (catch 'found
    (while (search-forward-regexp "\\_<namespace\\_>" nil t)
      (and (outrespace-not-in-comment-or-string)
           (throw 'found (match-beginning 0))))))

(defun outrespace--find-ns-previous ()
  "Return location of beginning of previous valid namespace."
  (catch 'found
    (while (search-backward-regexp "\\_<namespace\\_>" nil t)
      (and (outrespace-not-in-comment-or-string)
           (throw 'found (match-beginning 0))))))

(defun outrespace--at-ns-begin-p ()
  "Evaluate whether location LOC is at the beginning of a namespace."
  (save-excursion
    (and
     (looking-at "namespace")
     (save-excursion
       (backward-word)
       (not (looking-at "using\\s-+")))
     (save-excursion
       (forward-sexp 2)                 ;skip over "namespace x ="
       (not (looking-at "\\s-*=")))
     )))

(defun outrespace--namespace-nested-p (ns)
  "Return whether the namespace NS is a nested namespace (C++17)."
  (string-match-p "::" (car (outrespace--get-ns-names ns))))

(defun outrespace--flatten-nested-names (tags)
  "Flatten the input TAGS into a list of nested tags.
Useful for C++17's nested namespaces.  The result is a list of
cons cells, each of which is of the form: `(tag . pos)', where
tag is the individual tag, and pos is its position in the input.
The resultant list may have only one element."
  (let ((pos 0)
        res next)
    (while (setq next (string-match-p "::" tags pos))
      (setq res (cons
                 (cons (substring tags pos next) pos)
                 res))
      (setq pos (+ 2 next)))
    ;; add on the final tag
    (when (substring tags pos)
      (setq res (cons
                 (cons
                  (substring tags pos) pos) res)))
    (nreverse res)))

(defun outrespace--get-ns-names (ns)
  "Return the list '(name full-name) of NS."
  (nth 0 ns))

(defun outrespace--get-ns-tag-pos (ns)
  "Return the list '(beg end) of the `namespace' tag of NS."
  (nth 1 ns))

(defun outrespace--get-ns-name-pos (ns)
  "Return the list '(beg end) of the name, if any, of NS."
  (nth 2 ns))

(defun outrespace--get-ns-delimiter-pos (ns)
  "Return the list '(beg end) of the scope {} of NS."
  (nth 3 ns))

(defun outrespace--namespace-regexp ()
  "Define a regexp to parse a namespace declaration."
  (concat
   ;; an optional group comprised of mandatory whitespace
   ;; and a namespace name
   "\\(?:\\(?:\\s-\\|\n\\)+\\([A-Za-z0-9:_]+\\)\\)?"
   ;; opening brace (excluding surrounding whitespace)
   "\\(?:\\s-*\\|\n\\)*\\({\\)"))

(defun outrespace-parse-namespace (loc &optional parent)
  "Parse the namespace starting at LOC.
PARENT contains any enclosing namespaces."
  (save-excursion
    (let (tag-pos name-pos delimiter-pos title beg end title-trimmed)
      (goto-char loc)
      (unless (outrespace--at-ns-begin-p)
        ;; not looking at valid namespace
        (throw 'invalid nil))
      ;; get bounds of namespace tag
      (setq beg (point))
      (forward-sexp)
      (setq end (point))
      (setq tag-pos (list beg end))
      (unless
          (search-forward-regexp
           (outrespace--namespace-regexp)
           nil t)
        (error "Error parsing namespace"))
      ;; get bounds of opening delimiter `{'
      (goto-char (match-beginning 2))
      (setq beg (point))
      (forward-list)
      (setq end (point))
      (setq delimiter-pos (list beg end))
      ;; get bounds of name, if any exists
      (setq title (match-string-no-properties 1)) ;may have whitespace
      (setq beg (match-beginning 1))
      (setq end (match-end 1))
      ;; note string-trim alters match-data
      (if (and title (setq title-trimmed (string-trim title)))
          (setq name-pos (list beg (+ beg (length title-trimmed))))
        (setq name-pos (list (1+ (cadr tag-pos)) (1+ (cadr tag-pos))))
        (setq title-trimmed outrespace-anon-name))
      (list (list title-trimmed (if parent
                                    (concat parent "::" title-trimmed)
                                  title-trimmed))
            tag-pos name-pos delimiter-pos))))

(defun outrespace--get-full-extant (ns)
  "Return the bounds (beg . end) of the full namespace extent in NS."
  (cons (car (outrespace--get-ns-tag-pos ns))
        (cadr (outrespace--get-ns-delimiter-pos ns))))

(defun outrespace--get-distance-from-begin (pos ns)
  "Return the distance of a point POS from start of namespace in NS.
If POS is before or after the namespace bounds, return nil."
  (let ((extant (outrespace--get-full-extant ns)))
    (if (and (<= (car extant) pos) (>= (cdr extant) pos))
        (- pos (car extant))
      nil)))

(defun outrespace--collect-namespaces-around-pos (pos lst)
  "Return all namespaces that surround POS from LST."
  (seq-filter (lambda (ns)
                (outrespace--get-distance-from-begin pos ns))
              lst))

(defun outrespace--sort-namespaces-by-distance (pos lst)
  "Sort namespaces around POS from LST, according to distance."
  (sort lst
        (lambda (lhs rhs)
          (< (outrespace--get-distance-from-begin pos lhs)
             (outrespace--get-distance-from-begin pos rhs))
          )))

(defun outrespace--find-enclosing-ns-manual ()
  "Return the namespace around point, if any.
This scans the buffer ad-hoc, not using the results already
stored in `outrespace-list', if any."
  (save-excursion
    (catch 'found
      (let* ((pt (point))
             (beg (outrespace--find-ns-previous))
             (ns (and beg (catch 'invalid
                            (outrespace-parse-namespace beg)))))
        (while ns
          (when (outrespace--get-distance-from-begin pt ns)
            (throw 'found ns))
          (setq beg (outrespace--find-ns-previous))
          (setq ns (and beg (catch 'invalid
                              (outrespace-parse-namespace beg)))))))))

(defun outrespace--find-enclosing-ns ()
  "Return the namespace around point, if any.
This uses the results, if any, of a previous buffer scan,
stored in `outrespace-list'."
  (let ((pt (point))
        (lst outrespace-list)
        srt)
    (setq srt (outrespace--sort-namespaces-by-distance
               pt
               (outrespace--collect-namespaces-around-pos pt lst)))
    (car srt)))

;;;###autoload
(defun outrespace-change-enclosing-ns-name ()
  "Change the name of the enclosing namespace, if one exists."
  (interactive)
  (outrespace-scan-buffer)
  (let ((ns (outrespace--find-enclosing-ns)))
    (if ns
        (outrespace--change-ns-name ns)
      (message "No enclosing namespace"))))

(defun outrespace--change-ns-name (ns)
  "Change the name of namespace denoted by NS to NEW."
  (let ((start (car (outrespace--get-ns-name-pos ns)))
        (end (cadr (outrespace--get-ns-name-pos ns)))
        (old (car (outrespace--get-ns-names ns)))
        new)
    (setq new (read-string
               (concat "Change namespace " old
                       " to (leave blank for anonymous): ")))
    (when (string-equal old outrespace-anon-name)
      (setq old "anonymous"))
    (save-excursion
      ;; change any comment with old name at ns end
      ;; (only look on same line as last delimiter)
      (goto-char (cadr (outrespace--get-ns-delimiter-pos ns)))
      (when (and
             (search-forward old (line-end-position) t)
             (nth 4 (syntax-ppss)))
        (if (string-blank-p new)
            (replace-match "anonymous")
          (replace-match new))))
    ;; change the namespace tag
    (delete-region start end)
    (goto-char start)
    (insert new)
    (just-one-space)))

;;;###autoload
(defun outrespace-delete-enclosing-ns ()
  "Delete the enclosing namespace, if one exists.
This removes the tags and delimiters, not the content."
  (interactive)
  (outrespace-scan-buffer)
  (let ((ns (outrespace--find-enclosing-ns)))
    (if ns
        (outrespace--delete-ns ns)
      (message "No enclosing namespace"))))

(defun outrespace--delete-ns (ns)
  "Delete the namespace denoted by NS (though not its content)."
  (when ns
    (save-excursion
      (let ((start (car (outrespace--get-ns-tag-pos ns)))
            (end (car (outrespace--get-ns-delimiter-pos ns)))
            (coda (cadr (outrespace--get-ns-delimiter-pos ns))))
        (goto-char coda)
        (delete-char -1)
        (comment-kill 1)
        (outrespace--clean-up-ws-around-point)
        (delete-region start (1+ end))
        (goto-char start)
        (outrespace--clean-up-ws-around-point)))))

(defun outrespace--highlight-ns (ns)
  "Highlight the namespace denoted by NS."
  (when ns
    (let ((start (car (outrespace--get-ns-delimiter-pos ns)))
          (end (cadr (outrespace--get-ns-delimiter-pos ns))))
      (goto-char start)
      (set-mark-command nil)
      (goto-char end)
      (setq deactivate-mark nil))))

(defun outrespace--clean-up-ws-around-point ()
  "Clean up whitespace around point."
  (just-one-space)
  (delete-blank-lines))

(defun outrespace--jump-to-ns (ns)
  "Jump to the beginning of namespace NS."
  (when ns
    (outrespace--on-namespace-selected ns)))

(defun outrespace--get-ns-by-name (name)
  "Return the namespace matching NAME."
  (seq-find (lambda(elt)
              (string-equal name (cadr (outrespace--get-ns-names elt))))
            outrespace-list))

;;;###autoload
(defun outrespace-jump-to-ns ()
  "Jump to a namespace in current buffer, selected by name."
  (interactive)
  (let ((ns (outrespace--choose-ns-by-name "Namespace to jump to: ")))
    (if ns
        (outrespace--jump-to-ns ns)
      (message "No namespaces."))))

;;;###autoload
(defun outrespace-change-ns-name ()
  "Select a namespace, then change its name."
  (interactive)
  (outrespace-scan-buffer)
  (let ((ns (outrespace--choose-ns-by-name "Namespace to change: ")))
    (if ns
        (outrespace--change-ns-name ns)
      (message "No namespaces."))))

;;;###autoload
(defun outrespace-delete-ns-by-name ()
  "Select a namespace, then delete it (though not its content)."
  (interactive)
  (outrespace-scan-buffer)
  (let ((ns (outrespace--choose-ns-by-name "Namespace to delete: ")))
    (if ns
        (outrespace--delete-ns ns)
      (message "No namespaces."))))

;;;###autoload
(defun outrespace-highlight-ns-by-name ()
  "Select a namespace, then highlight it."
  (interactive)
  (outrespace-scan-buffer)
  (let ((ns (outrespace--choose-ns-by-name "Namespace to highlight: ")))
    (if ns
        (outrespace--highlight-ns ns)
      (message "No namespaces."))))

;;;###autoload
(defun outrespace-print-enclosing-ns-name ()
  "Print the closest namespace surrounding point, if any."
  (interactive)
  (outrespace-scan-buffer)
  (let ((ns (outrespace--find-enclosing-ns)))
    (if ns
        (message "Namespace: %s" (cadr (outrespace--get-ns-names ns)))
      (message "No enclosing namespace."))))

(defun outrespace--select-ns-ivy (lst prompt)
  "Select a namespace from LST (with prompt PROMPT), using ivy.
Duplicate namespace names can be selected based on their position
in the buffer."
  (interactive)
  (let (ns)
    (ivy-read prompt
              lst
              :caller 'outrespace--select-ns-ivy
              :action (lambda (x)
                        (setq ns (cdr x)))
              :sort nil
              :initial-input nil)
    ns))

(defun outrespace--select-ns-standard (lst prompt)
  "Select a namespace from LST (with prompt PROMPT).
Duplicate namespace names will be represented sequentially by
suffixes such as <1> or <2>."
  (interactive)
  (let ((tbl (make-hash-table :test 'equal))
        val res fully-qualified-name)
    (dolist (elt lst)
      (setq fully-qualified-name (cadr (outrespace--get-ns-names (cdr elt))))
      (setq val (gethash fully-qualified-name tbl))
      (if val
          (progn
            (setcar elt (format "%s<%d>" fully-qualified-name (1+ val)))
            (puthash fully-qualified-name (1+ val) tbl))
        (puthash fully-qualified-name 1 tbl)))
    (setq res (completing-read prompt lst nil t))
    (when res
      (cdr (assoc res lst)))))

(defun outrespace--choose-ns-by-name (&optional prompt)
  "Select a namespace (with prompt PROMPT) in the current buffer."
  (outrespace-scan-buffer)
  (let ((lst (mapcar
              (lambda(elt)
                (cons
                 (cadr (outrespace--get-ns-names elt))
                 elt))
              outrespace-list)))
    (funcall outrespace--select-ns-func (nreverse lst)
             (or prompt "Namespace: "))))

;; namespace
(defvar c-basic-offset)
;;;###autoload
(defun outrespace-wrap-namespace-region (start end name)
  "Surround the region (START, END) with a namespace NAME."
  (interactive "r\nsEnter the namespace name (leave blank for anonymous): ")
  (save-excursion
    (goto-char end) (insert "\n}")
    (insert-char ?\s c-basic-offset)
    (insert "// end namespace "
            (if (zerop (length name))
                "anonymous" name)
            "\n")
    (goto-char start)
    (insert "namespace ")
    (unless (zerop (length name))
      (insert name " "))
    (insert "{\n\n")))

(defun outrespace-define-keys (map)
  "Define in MAP key bindings for `outrespace-mode'."
  (define-key map "\M-p" 'outrespace-goto-namespace-previous)
  (define-key map "\M-n" 'outrespace-goto-namespace-next)
  (define-key map "p" 'outrespace-print-enclosing-ns-name)
  (define-key map "n" 'outrespace-wrap-namespace-region)
  (define-key map "j" 'outrespace-jump-to-ns)
  (define-key map "c" 'outrespace-change-ns-name)
  (define-key map "C" 'outrespace-change-enclosing-ns-name)
  (define-key map "d" 'outrespace-delete-ns-by-name)
  (define-key map "D" 'outrespace-delete-enclosing-ns)
  (define-key map "h" 'outrespace-highlight-ns-by-name)
  (define-key map [t] 'outrespace-turn-off)
  )

(defvar outrespace-mode-map
  (let ((map (make-sparse-keymap)))
    (outrespace-define-keys map)
    map)
  "Keymap for `outrespace-mode'.")

(defun outrespace-define-prefix (map)
  "Define a prefix keymap MAP for `outrespace-mode'."
  (define-key map outrespace-prefix-key outrespace-mode-map))

(defvar outrespace-prefix-map
  (let ((map (make-sparse-keymap)))
    (outrespace-define-prefix map)
    map)
  "Prefix keymap for `outrespace-mode'.")

(defun outrespace-turn-off ()
  "Turn off `outrespace-mode'."
  (interactive)
  (outrespace-mode -1))

(define-minor-mode outrespace-mode
  "Helper for c++ namespaces."
  :init-value nil
  :lighter " NS"
  :keymap outrespace-prefix-map
  (if outrespace-mode
      (outrespace-define-prefix global-map)
    t))

(provide 'outrespace)
;;; outrespace.el ends here
