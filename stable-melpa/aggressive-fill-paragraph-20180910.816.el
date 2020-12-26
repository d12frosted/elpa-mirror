;;; aggressive-fill-paragraph.el --- A mode to automatically keep paragraphs filled -*- lexical-binding: t; -*-

;; Author: David Shepherd <davidshepherd7@gmail.com>
;; Version: 0.0.1
;; Package-Version: 20180910.816
;; Package-Commit: 4a620e62b5e645a48b0a818bf4eb19daea4977df
;; Package-Requires: ((dash "2.10.0"))
;; URL: https://github.com/davidshepherd7/aggressive-fill-paragraph-mode
;; Keywords: fill-paragraph, automatic, comments

;;; Commentary:

;; An Emacs minor-mode for keeping paragraphs filled in both comments and prose.

;;; Code:

(require 'dash)


;; Helpers

(defun afp-inside-comment? ()
  "Are we in a comment?"
  (nth 4 (syntax-ppss)))

(defun afp-current-line ()
  "Get the current line."
  (buffer-substring-no-properties (point-at-bol) (point-at-eol)))


;; Functions for testing conditions to suppress fill-paragraph

(defun afp-markdown-inside-code-block? ()
  "Check if we are inside a markdown code block."
  (and (string-equal major-mode "markdown-mode")
       (string-match-p "^    " (afp-current-line))))

(defun afp-start-of-comment? ()
  "Check if we have just started writing a new comment line.

It's annoying if you are trying to write a list but it keeps
getting filled before you can type the * which afp recognises
as a list."
  (and (string-match-p (concat))))

(defun afp-repeated-whitespace? ()
  "Check if this is the second whitespace character in a row."
  (looking-back "\\s-\\s-" (- (point) 2)))

(defun afp-bullet-list-in-comments? ()
  "Try to check if we are inside a bullet pointed list.

Bulleted by *, + or -."
  (and (afp-inside-comment?)

       ;; TODO: extend to match any line in paragraph
       (string-match-p (concat "^\\s-*" comment-start "\\s-*[-\\*\\+]")
                       (afp-current-line))))

;; Org mode tables have their own filling behaviour which results in the
;; cursor being moved to the start of the table element, which is no good
;; for us! See issue #6.
(require 'org)
(declare-function org-element-type "org-element" element)
(defun afp-in-org-table? ()
  "Check if point is inside an ‘org-mode’ table."
  (interactive)
  (and (derived-mode-p 'org-mode)
       (or (eql (org-element-type (org-element-at-point)) 'table)
           (eql (org-element-type (org-element-at-point)) 'table-row))))

(defun afp-in-org-src-block-header? ()
  (let ((case-fold-search t))
    (and (derived-mode-p 'org-mode)
         (save-excursion
           (beginning-of-line)
           (looking-at-p "^[ \t]*#\\+\\(\\(begin\\|end\\)_src\\|header\\|name\\)")))))

(defcustom afp-suppress-fill-pfunction-list
  (list
   #'afp-repeated-whitespace?
   #'afp-markdown-inside-code-block?
   #'afp-bullet-list-in-comments?
   #'afp-in-org-table?
   #'afp-in-org-src-block-header?
   )
  "Functions to check if filling should be suppressed.

List of predicate functions of no arguments, if any of these
functions returns false then paragraphs will not be
  automatically filled."
  :type '(repeat function)
  :group 'aggressive-fill-paragraph)

(defcustom afp-fill-comments-only-mode-list
  (list 'emacs-lisp-mode 'sh-mode 'python-mode 'js-mode)
  "List of major modes in which only comments should be filled."
  :group 'aggressive-fill-paragraph
  :type '(repeat symbol))

(defcustom afp-fill-keys
  (list ?\ ?.)
  "List of keys after which to fill paragraph."
  :group 'agressive-fill-paragraph
  :type '(repeat character))



;; The main functions


(defun afp-only-fill-comments (&optional justify)
  "Replacement ‘fill-paragraph’ function which only affects comments.

Argument JUSTIFY is passed on to the fill function."
  (fill-comment-paragraph justify)

  ;; returning true says we are done with filling, don't fill anymore
  t)


(defun afp-suppress-fill? ()
  "Check all functions in ‘afp-suppress-fill-pfunction-list’."
  (-any? #'funcall afp-suppress-fill-pfunction-list))


(defun afp-choose-fill-function ()
  "Select which fill paragraph function to use."
  (cond

   ;; In certain modes it is better to use afp-only-fill-comments to avoid
   ;; strange behaviour in code.
   ((apply #'derived-mode-p afp-fill-comments-only-mode-list)
    #'afp-only-fill-comments)

   ;; For python we could also do something with let-binding
   ;; python-fill-paren-function so that code is left alone. This would
   ;; allow docstrings to be filled, but unfortunately filling of strings
   ;; and docstrings are both handled by the same chunk of code, so even
   ;; normal strings would be filled.

   ;; Use the buffer local fill function if it's set
   ((not (null fill-paragraph-function)) fill-paragraph-function)

   ;; Otherwise just use the default one
   (t #'fill-paragraph)))


(defun aggressive-fill-paragraph-post-self-insert-function ()
  "Main worker function for aggressive-fill-paragraph.

Fill paragraph when space is inserted and fill is not disabled
for any reason."
  (when (and (-contains? afp-fill-keys last-command-event)
             (not (afp-suppress-fill?)))

    ;; Delete the charcter before filling and reinsert after. This is
    ;; needed because we don't know if filling will remove whitespace.
    (backward-delete-char 1)
    (funcall (afp-choose-fill-function))
    (insert last-command-event)))



;; Minor mode set up
;;;###autoload
(define-minor-mode aggressive-fill-paragraph-mode
  "Toggle automatic paragraph fill when spaces are inserted in comments."
  :global nil
  :group 'electricity

  (if aggressive-fill-paragraph-mode
      (add-hook 'post-self-insert-hook
                #'aggressive-fill-paragraph-post-self-insert-function nil t)
    (remove-hook 'post-self-insert-hook
                 #'aggressive-fill-paragraph-post-self-insert-function t)))

;;;###autoload
(defun afp-setup-recommended-hooks ()
  "Install hooks to enable function ‘aggressive-fill-paragraph-mode’ in recommended major modes."
  (interactive)

  (add-hook 'text-mode-hook #'aggressive-fill-paragraph-mode)
  (add-hook 'prog-mode-hook #'aggressive-fill-paragraph-mode))


(provide 'aggressive-fill-paragraph)

;;; aggressive-fill-paragraph.el ends here
