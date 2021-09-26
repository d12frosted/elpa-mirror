;;; wakib-keys.el --- Minor Mode for Modern Keybindings -*- lexical-binding: t -*-

;; Author: Abdulla Bubshait
;; URL: https://github.com/darkstego/wakib-keys/
;; Package-Version: 20210903.1619
;; Package-Commit: 627e94389fe754da9802a8c93e4a3d1a1831967b
;; Created: 6 April 2018
;; Keywords: convenience, keybindings, keys
;; License: GPL v3
;; Package-Requires: ((emacs "24.4"))
;; Version: 0.3.10

;; This file is not part of GNU Emacs.

;; Emacs minor mode that provides a modern, efficient and easy to learn keybindings

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package aims to provide new keybindinfgs for basic Emacs
;; functions.  The goal of this package is to provide an accesible
;; emacs starter kit that could be used by anyone out of the box
;; without the need for tutorials, but also be feature complete.

;;; Code:


;; Functions & Macros


(defun wakib-dynamic-binding (key)
  "Act as KEY in the current context.
This uses an extended menu item's capability of dynamically computing a
definition.  This idea came from general.el"
  `(menu-item
	 ,""
	 nil
	 :filter
	 ,(lambda (&optional _)
		 (wakib-key-binding key))))


;; should probably use let instead of double call to (car x)
(defun wakib-minor-mode-key-binding (key)
  "Function return all keymaps defind to KEY within minor modes.
This function ignores the overriding maps that will be used to override
KEY"
  (let ((active-maps nil))
    (mapc (lambda (x)
	    (when (and (symbolp (car x)) (symbol-value (car x)))
	      (add-to-list 'active-maps  (lookup-key (cdr x) (kbd key)))))
	  minor-mode-map-alist )
    (make-composed-keymap active-maps)))


(defun wakib-current-minor-mode-maps ()
  "Return keymaps of all current active minor modes (without overriding modes)."
  (delete nil (mapcar (lambda (x)
	    (when (and (symbolp (car x)) (symbol-value (car x)))
	      (cdr x))) minor-mode-map-alist)))

;; might need to do keymap inheretence to perserve priority
(defun wakib-key-binding (key)
  "Return the full keymap bindings of KEY."
  (make-composed-keymap (list (wakib-minor-mode-key-binding key) (local-key-binding (kbd key)) (global-key-binding (kbd key)))))

(defun wakib-function-lookup(fun)
  "Lookup FUN in C-d C-e maps and return shortcut in string format"
  (let ((ce-key (car (where-is-internal fun (list (wakib-key-binding "C-x")))))
	(cd-key (car (where-is-internal fun (list (wakib-key-binding "C-c"))))))
    (cond (cd-key (concat "C-d " (key-description cd-key)))
	  (ce-key (concat "C-e " (key-description ce-key)))
	  (t nil))))

(defun wakib--get-command-keys (hash str start)
  "Add all C-d C-e matches in string to hash."
  (if (string-match "\\\\\\[\\([^\]]*\\)\\]" str start)
      (let* ((match (intern (match-string 1 str)))
	     (match-pos (match-beginning 0))
	     (shortcut (wakib-function-lookup match)))
	(puthash match shortcut hash)
	(wakib--get-command-keys hash str (+ match-pos 1)))
    hash))

(defun wakib-substitute-command-keys (orig-fun &rest args)
  "Advice for substitute command keys."
  ;; Put replacements in hash first because doing key lookup during
  ;; replace-regexp-in-string resets the match and causes the replace
  ;; step to work incorrectly

  ;; Parts of emacs (e.g. Customize) calls with nil args
  (if (stringp (car args))
  (let* ((hash (wakib--get-command-keys (make-hash-table) (car args) 0))
	(str (replace-regexp-in-string "\\\\\\[\\([^\]]*\\)\\]"
				       (lambda (match)
					 (let ((key (gethash (intern (substring match 2 -1)) hash)))
					   (if key key match)))
				       (car args) t t)))
    (apply orig-fun (list str)))
  (apply orig-fun args)))


(defun wakib-update-major-mode-map ()
  "Fix Shortcuts in menu-bar of major mode map."
  (let ((mode-map (current-local-map)))
    (when (and (keymapp mode-map)
	       (not (get major-mode 'wakib-updated)))
      (wakib-update-menu-map (lookup-key mode-map [menu-bar]) mode-map)
      (put major-mode 'wakib-updated t))))

(defun wakib-update-minor-mode-maps ()
  "Fix shortcts in menu-bar of minor mode maps."
  (let ((map-list (current-minor-mode-maps)))
    (mapc (lambda (keymap)
	    (wakib-update-menu-map (lookup-key keymap [menu-bar])
				   (wakib-current-minor-mode-maps))
      ) map-list)))



(defun wakib-update-menu-map (menu-map command-map &optional prefix)
  "Update MENU-MAP shortcuts from given COMMAND-MAP.
Optional argument PREFIX adds prefix to command."
  (mapc (lambda (i)
	  (wakib--update-keymap i command-map prefix)) menu-map))


(defun wakib--update-keymap (item keymaps &optional prefix)
  "Update Shortcuts in KEYMAP."
  (when (and (listp item)
	     (listp (cdr (last item))))
    (cond ((keymapp item)
	   (mapc (lambda (i) (wakib--update-keymap i keymaps prefix)) item))
	  ((and (stringp (cadr item))
		(keymapp (cddr item)))
	   (mapc (lambda (i) (wakib--update-keymap i keymaps prefix)) (cddr item)))
	  ((and (stringp (cadr item))
		(stringp (car (cddr item)))
		(keymapp (cdr (cddr item))))
	   (mapc (lambda (i) (wakib--update-keymap i keymaps prefix)) (cdr (cddr item))))
	  ((and (eq 'menu-item (cadr item))
		(keymapp (nth 3 item)))
	   (mapc (lambda (i) (wakib--update-keymap i keymaps prefix)) (nth 3 item)))
	  ((and (eq 'menu-item (cadr item))
		(nth 3 item))
	   (wakib--update-menu-item-keys item keymaps prefix)))))


(defun wakib--update-menu-item-keys (menu-item-list keymaps &optional prefix)
  "Change the given menu item to point to correct shortcut."
  (let* ((binding (nth 3 menu-item-list))
	 (menu-item-copy (copy-sequence (cdr menu-item-list)))
	(tail (nthcdr 2 menu-item-copy))
	(key (where-is-internal binding keymaps t))
	(keys (plist-get (cdr tail) :keys)))
    (when (and keys
	       (stringp keys)
	       (string-match-p "^\\(C-c\\|C-x\\)" keys))
      (setcdr tail (plist-put
			(cdr tail)
			:keys (replace-regexp-in-string
			       "^C-c" "C-d"
			       (replace-regexp-in-string "^C-x" "C-e" keys))))
      (setcdr menu-item-list menu-item-copy))
    (when key
      (let ((shortcut (key-description key)))
	(cond
	 (prefix
	  (setcdr tail (plist-put (cdr tail)
				  :keys (concat prefix " " shortcut)))
	  (setcdr menu-item-list menu-item-copy))
	 ((string-match-p "^\\(C-c\\|C-x\\)" shortcut)
	  (setcdr tail (plist-put
			(cdr tail)
			:keys (replace-regexp-in-string "^C-c" "C-d"
							(replace-regexp-in-string "^C-x" "C-e" shortcut))))
	  (setcdr menu-item-list menu-item-copy))
	 ;; since we already searched, memoize the key as a suggestion
	 (t (setcdr tail (plist-put (cdr tail)
				    :key-sequence key))
	    (setcdr menu-item-list menu-item-copy)))))))


(defun wakib-find-overlays-specifying (prop)
  "Find property among overlays at point"
            (let ((overlays (overlays-at (point)))
                  found)
              (while overlays
                (let ((overlay (car overlays)))
                  (if (overlay-get overlay prop)
                      (setq found (cons overlay found))))
                (setq overlays (cdr overlays)))
              found))


(defun wakib--replace-in-region (regex rep start-point end-point)
  "Go through the output of describe bindings and replace C-c and C-x with C-d and C-e"
  (save-excursion
    (goto-char start-point)
    (while (re-search-forward regex end-point t)
      (replace-match rep))))

(defun wakib--describe-bindings-advice (orig-fun buffer &optional prefix menus)
  "Advice for describe-buffer-bindings to correctly show C-d and C-e bindings.
Does not give the correct result if you explicitly search for C-c or C-x."
  (let ((start-point (point)))
    (cond ((not prefix)
	   ;; Without prefix must change C-c and C-x
	   (apply orig-fun buffer prefix menus)
	   (wakib--replace-in-region "^C-c " "C-d " start-point (point))
	   (wakib--replace-in-region "^C-x " "C-e " start-point (point)))
	  ;; Explicit search for C-d won't work if buffer passed isn't current buffer
	  ((and (not (eq buffer (current-buffer)))(string-match-p "^C-d" (key-description prefix)))
	   (apply orig-fun buffer
		  (kbd (replace-regexp-in-string "^C-d" "C-c" (key-description prefix))) menus)
	   (wakib--replace-in-region  "^C-c " "C-d " start-point (point)))
	  (t
	   (apply orig-fun buffer prefix menus)))))


    
;; Commands

(defun wakib-previous (&optional arg)
  "Perform context aware Previous function.
ARG used as repeat function for interactive"
  (interactive "p")
  ;; if region active
  (cond ((eq last-command 'yank)
	 (yank-pop (- arg)))
	((use-region-p)
	 (exchange-point-and-mark))
	(t (wakib-previous-more))))

(defun wakib-next (&optional arg)
  "Perform context aware Next function.
ARG used as repeat for interactive function."
  (interactive "p")
  (cond ((eq last-command 'yank)
	 (yank-pop arg))
	((use-region-p)
	 (exchange-point-and-mark))
	(t (wakib-next-more))))

(defun wakib-previous-more (&optional arg)
  "Used to add functionality to wakib-previous"
  (interactive "p"))

(defun wakib-next-more (&optional arg)
  "Used to add fucntionality to wakib-next"
  (interactive "p"))



;; might be a more functional way to do this
(defun wakib-select-line-block-all ()
  "Select line.  Expands to block and then entire buffer."
  (interactive)
  (let ((p1 (if (region-active-p)
		(region-beginning)
	      (point)))
	(p2 (if (region-active-p)
		(region-end)
	      (point)))
		  (x1)
		  (x2)
		  (end-p))
	 (unless (region-active-p)
		(setq p1 (point))
		(setq p2 (point)))
	 (setq end-p (eq p2 (point)))
	 (goto-char p1)
	 (beginning-of-line)
	 (setq x1 (point))
	 (push-mark x1 t t)
	 (goto-char p2)
	 (end-of-line)
	 (setq x2 (point))
	 (when (and (eq x1 p1)
		    (eq x2 p2))
	   (goto-char p1)
	   (when (re-search-backward "\n[ \t]*\n" nil "move")
	     (re-search-forward "\n[ \t]*\n"))
	   (setq x1 (point))
	   (push-mark x1 t t)
	   (goto-char p2)
	   (when (re-search-forward "\n[ \t]*\n" nil "move")
	     (re-search-backward "\n[ \t]*\n"))
	   (setq x2 (point)))
	 (when (and (eq x1 p1)
		    (eq x2 p2))
	   (goto-char (point-min))
	   (setq x1 (point))
	   (push-mark x1 t t)
	   (goto-char (point-max))
	   (setq x2 (point)))
	 (when (not end-p)
	   (push-mark x2 t t)
	   (goto-char x1))))

(defun wakib-back-to-indentation-or-beginning ()
  "Move to start of text or start of line."
  (interactive)
  (if (= (point) (progn (back-to-indentation) (point)))
      (beginning-of-line)))


(defun wakib-beginning-line-or-block ()
  "Move to the beginning of line, if there then move to beginning of block."
  (interactive)
  (let ((p (point)))
	 (beginning-of-line)
	 (when (eq p (point))
		(when (re-search-backward "\n[ \t]*\n" nil "move")
		  (re-search-forward "\n[ \t]*\n")))
	 (when (eq p (point))
		(re-search-backward "\n[ \t]*\n" nil "move")
		(when (re-search-backward "\n[ \t]*\n" nil "move")
		  (re-search-forward "\n[ \t]*\n")))))

(defun wakib-end-line-or-block ()
  "Move to the end of line, if there then move to end of block."
  (interactive)
  (let ((p (point)))
	 (end-of-line)
	 (when (eq p (point))
		(when (re-search-forward "\n[ \t]*\n" nil "move")
		  (re-search-backward "\n[ \t]*\n")))
	 (when (eq p (point))
		(re-search-forward "\n[ \t]*\n" nil "move")
		(when (re-search-forward "\n[ \t]*\n" nil "move")
		  (re-search-backward "\n[ \t]*\n")))))


(defun wakib-new-empty-buffer ()
  "Create a new empty buffer and switch to it.
New buffer will be named “untitled” or “untitled<2>”, etc.
It returns the buffer."
  (interactive)
  (let ((buffer (generate-new-buffer "untitled")))
    (set-buffer-major-mode buffer)
    (switch-to-buffer buffer)
    (setq buffer-offer-save t)
    buffer))

(defun wakib-insert-line-before ()
  "Insert a newline and indent before current line."
  (interactive)
  (move-beginning-of-line 1)
  (newline-and-indent)
  (forward-line -1)
  (indent-according-to-mode))

(defun wakib-insert-line-after ()
  "Insert a newline and indent before current line."
  (interactive)
  (move-end-of-line 1)
  (newline-and-indent))

(defun wakib-beginning-of-line-or-block ()
  "Move cursor to beginning of line or previous paragraph."
  (interactive)
  (let (($p (point)))
    (if (or (equal (point) (line-beginning-position))
            (equal last-command this-command ))
        (if (re-search-backward "\n[\t\n ]*\n+" nil "move")
            (progn
              (skip-chars-backward "\n\t ")
              ;; (forward-char )
              )
          (goto-char (point-min)))
      (progn
        (back-to-indentation)
        (when (eq $p (point))
          (beginning-of-line))))))

(defun wakib-end-of-line-or-block ()
  "Move cursor to end of line or next paragraph."
  (interactive)
  (if (or (equal (point) (line-end-position))
          (equal last-command this-command ))
      (progn
        (re-search-forward "\n[\t\n ]*\n+" nil "move" ))
    (end-of-line)))

(defun wakib-backward-kill-line ()
  "Kill from cursor to start of line."
  (interactive)
  (kill-line 0))

;; Setup for keymap

(defvar wakib-keys-overriding-map (make-sparse-keymap) "Key bindings for Wakib minor mode.")
(defvar wakib-keys-map (make-sparse-keymap) "Keymap used for menu-bar items.")

(defun wakib-define-keys (keymap keylist)
  "Add to KEYMAP all keys in KEYLIST.
Then add C-d and C-e to KEYMAP"
  (interactive)
  (mapc (lambda (pair)
          (define-key keymap (kbd (car pair)) (cdr pair)))
        keylist)
  (define-key keymap (kbd "C-e") (wakib-dynamic-binding "C-x"))
  (define-key keymap (kbd "C-d") (wakib-dynamic-binding "C-c")))

(defvar wakib-keylist
  `(("M-j" . left-char)
    ("M-l" . right-char)
    ("M-i" . previous-line)
    ("M-k" . next-line)
    ("M-u" . backward-word)
    ("M-o" . forward-word)
    ("M-;" . wakib-next)
    ("M-:" . wakib-previous)
    ("M-U" . move-beginning-of-line)
    ("M-O" . move-end-of-line)
    ("M-J" . backward-paragraph)
    ("M-L" . forward-paragraph)
    ("M-," . backward-sexp)
    ("M-." . forward-sexp)
    ("M-I" . scroll-down-command)
    ("M-K" . scroll-up-command)
    ("M-n" . beginning-of-buffer)
    ("M-N" . end-of-buffer)
    ("C-n" . wakib-new-empty-buffer)
    ("C-o" . find-file)
    ("C-S-o" . revert-buffer)
    ("C-w" . kill-current-buffer)
    ("C-q" . save-buffers-kill-terminal)
    ("C-<next>" . next-buffer)
    ("C-<prior>" . previous-buffer)
    ("C-c" . kill-ring-save)
    ("C-x" . kill-region)
    ("C-v" . yank)
    ("C-z" . undo)
    ("C-f" . isearch-forward)
    ("C-S-f" . isearch-backward)
    ("C-r" . query-replace)
    ("C-S-r" . query-replace-regexp)
    ("C-s" . save-buffer)
    ("C-S-s" . write-file)
    ("C-p" . print-buffer)
    ("C-a" . mark-whole-buffer)
    ("C-+" . text-scale-increase)
    ("C-=" . text-scale-increase)
    ("C--" . text-scale-decrease)
    ("C-;" . comment-line)
    ("M-h" . other-window)
    ("M-M" . goto-line)
    ("M-4" . split-window-right)
    ("M-$" . split-window-below)
    ("M-3" . delete-other-windows)
    ("M-#" . delete-window)
    ("M-e" . backward-kill-word)
    ("M-r" . kill-word)
    ("M-E" . wakib-backward-kill-line)
    ("M-R" . kill-line)
    ("M-w" . kill-whole-line)
    ("M-<f4>" . save-buffers-kill-emacs)
    ("M-d" . delete-backward-char)
    ("M-f" . delete-char)
    ("M-a" . wakib-select-line-block-all)
    ("M-s" . set-mark-command)
    ("M-S-s" . set-rectangular-region-anchor)
    ("<C-return>" . wakib-insert-line-after)
    ("<C-S-return>" . wakib-insert-line-before)
    ("C-b" . switch-to-buffer)
    ("M-X" . pp-eval-expression)
    (,(concat "<C-" (symbol-name mouse-wheel-down-event)  ">") . text-scale-increase)
    (,(concat "<C-" (symbol-name mouse-wheel-up-event)  ">") . text-scale-decrease)
    ("<escape>" . keyboard-quit)) ;; should quit minibuffer
  "List of all wakib mode keybindings.")


(wakib-define-keys wakib-keys-overriding-map wakib-keylist)
(add-to-list 'emulation-mode-map-alists
	     `((wakib-keys . ,wakib-keys-overriding-map)))

(defun wakib--tty-M-O (&optional arg)
  "Fix tty M-O to enable arrow keys"
  (interactive)
  (let ((key (read-char nil nil 0.01)))
    (if key
	;; temporary-goal-column needs to be reset otherwise
	;; up and down arrows end moving to old column
	(cond ((eq key 65) (previous-line arg))
	      ((eq key 66) (next-line arg))
	      ((eq key 67) (right-char arg)
	       (setq temporary-goal-column 0))
	      ((eq key 68) (left-char arg)
	       (setq temporary-goal-column 0)))
      (move-end-of-line arg))))

(unless (display-graphic-p)
  (define-key wakib-keys-overriding-map (kbd "M-O") 'wakib--tty-M-O))


(defun wakib--setup ()
  "Runs after minor mode change to setup minor mode"
  (if wakib-keys
      (progn
	(advice-add 'substitute-command-keys :around #'wakib-substitute-command-keys)
	(advice-add 'describe-buffer-bindings :around #'wakib--describe-bindings-advice))
    (advice-remove 'substitute-command-keys #'wakib-substitute-command-keys)
    (advice-remove 'describe-buffer-bindings #'wakib--describe-bindings-advice)))

;;;###autoload
(define-minor-mode wakib-keys
  "This mode brings modern style keybindings to Emacs.
Major changes is proper CUA key bindings by moving C-c and C-x to
C-d and C-e respectively. This allow access to all the keybindings of
Emacs while not tripping up users who do not want a steep learning curve
just to use their editor.

Note that only the first prefix is changed. So C-c C-c becomes C-d C-c."
  :lighter " Wakib"
  :init-value nil
  :keymap wakib-keys-map
  :require 'wakib-keys
  :global t
  (wakib--setup))

(provide 'wakib-keys)


;;; wakib-keys.el ends here
