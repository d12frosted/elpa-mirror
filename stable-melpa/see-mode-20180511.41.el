;;; see-mode.el --- Edit string  in a separate buffer

;; Author: Marcelo Muñoz <ma.munoz.araya@gmail.com>
;; URL: https://github.com/marcelino-m/see-mode
;; Package-Version: 20180511.41
;; Package-Commit: db9e4324f9dcc14d5125cb6a79d6c9fad5b14626
;; Keywords: convenience
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.4") (language-detection "0.1.0"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Edit snipet in separate buffers like `org-edit-src-code' but Snipet
;; here are embedded segment of code in literal string.

;;; Code:

(require 'language-detection)

;;; custom for all lang (when apply)

;;;###autoload
(defcustom see-use-align-quotes nil
  "Control if quotes are aligned vertically."
  :group 'see-mode
  :type '(boolean))

;;; custom for python lang

;;;###autoload
(defcustom see-py-use-single-quote nil
  "If this is nil `see-py-quote-lines' use triple quote to format multiline snipet."
  :group 'see-mode
  :type '(boolean))

;;;###autoload
(defcustom see-py-quote-char ?\"
  "The quote  character to use  for format snipet, in  python this may be simple or double."
  :group 'see-mode
  :type '(character))


(defcustom see-py-insert-newline-after-open-triple-quote t
  "Insert new line after opening triple quote characters."
  :group 'see-mode
  :type '(boolean))

(defcustom see-py-insert-newline-before-close-triple-quote nil
  "Insert new line before  closing  triple quote characters."
  :group 'see-mode
  :type '(boolean))


;;;###autoload
(defcustom see-window-setup 'other-window
  "How the source code edit buffer should be displayed.
Possible values for this option are:

`current-window'    Show edit buffer in the current window, keeping all other
                  windows.
`other-window'      Use `switch-to-buffer-other-window' to display edit buffer."
  :group 'see-mode
  :type '(choice
          (const current-window)
          (const other-window)))


;; keep context in editing buffer
(defvar-local see-ov              nil)
(defvar-local see-original-snipet nil)
(defvar-local see-saved-win-conf  nil)


(defvar see-language-detection-alist
  '((ada         . ada-mode)
    (awk         . awk-mode)
    (c           . c-mode)
    (cpp         . c++-mode)
    (clojure     . clojure-mode)
    (csharp      . csharp-mode)
    (css         . css-mode)
    (dart        . dart-mode)
    (delphi      . delphi-mode)
    (emacslisp   . emacs-lisp-mode)
    (erlang      . erlang-mode)
    (fortran     . fortran-mode)
    (fsharp      . fsharp-mode)
    (go          . go-mode)
    (groovy      . groovy-mode)
    (haskell     . haskell-mode)
    (html        . html-mode)
    (java        . java-mode)
    (javascript  . javascript-mode)
    (json        . json-mode)
    (latex       . latex-mode)
    (lisp        . lisp-mode)
    (lua         . lua-mode)
    (matlab      . octave-mode)
    (objc        . objc-mode)
    (perl        . perl-mode)
    (php         . php-mode)
    (prolog      . prolog-mode)
    (python      . python-mode)
    (r           . r-mode)
    (ruby        . ruby-mode)
    (rust        . rust-mode)
    (scala       . scala-mode)
    (shell       . shell-script-mode)
    (smalltalk   . smalltalk-mode)
    (sql         . sql-mode)
    (swift       . swift-mode)
    (visualbasic . visual-basic-mode)
    (xml         . sgml-mode)))



(defvar see-cc-regx-str-literal "\"\\(\\\\.\\|[^\"\\]\\)*\""
  "This regex match c and c++ string literal.")

(defvar see-py-regx-str-literal
  "\\(\\(\"\"\"\\(\\\\.\\|[^\\]\\)*?\"\"\"\\)\\|\\(\"\\(\\\\.\\|[^\"\\]\\)*\"\\)\\|\\('\\(\\\\.\\|[^'\\]\\)*'\\)\\)"
  "This regex match python string literal.")


(define-error 'see-read-only-region-error
  "Cannot modify an area being edited in a dedicated buffer by see-mode")

(define-minor-mode see-mode
  "Minor mode for  editing string in buffer with apropiate mode enabled."
  :lighter " see"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map "\C-c'"    #'see-exit)
            (define-key map "\C-c\C-k" #'see-abort)
            (define-key map "\C-x\C-s" #'see-save)
            map))


(defun see-set-ov (beg end)
  "Setup overlay between `BEG' and `END' and mark this as read only."
  (let ((ov (make-overlay beg end))
        (fn (lambda (&rest _)
              (unless inhibit-read-only
                (signal 'see-read-only-region-error nil)))))
    (overlay-put ov 'face 'secondary-selection)
    (overlay-put ov 'modification-hooks `(,fn))
    (overlay-put ov 'insert-in-front-hooks `(,fn))
    ov))


(defun see-cleanup-before-copy-back (code)
  "Remove empty  lines from upper  and bottom of `CODE'  and remove trailing whitespace."
  (with-temp-buffer
    (insert code)
    (goto-char (point-min))
    (let ((point (point)))
      (skip-syntax-forward "-")
      (beginning-of-line)
      (delete-region point (point))
      (goto-char (point-max))
      (setq point (point))
      (skip-syntax-backward "-")
      (end-of-line)
      (delete-region (point) point)
      (delete-trailing-whitespace (point-min) (point-max))
      (buffer-string))))


(defun see-construct-datum (beg end)
  "Construct a plist with general information of literal string enclosed between `BEG' and `END'."
  (list
   :beg    beg
   :end    end
   :buffer (current-buffer)
   :mode   nil))


(defun see-try-determine-lang-mode (string)
  "Try to determine mode based on content of STRING."
  (cdr
   (assoc
    (language-detection-string string) see-language-detection-alist)))

(defun see-generate-buffer-name (mode)
  "Return a string that is the name of no existing buffer based on `MODE'."
  (generate-new-buffer-name (format "[see: %s]" mode)))

(defun see-switch-to-edit-buffer (buffer)
  "Switch to `BUFFER' according to  option `see-window-setup'."
  (pcase see-window-setup
    (`current-window (pop-to-buffer-same-window buffer))
    (`other-window
     (switch-to-buffer-other-window buffer))))


(defun see-edit-snipet (beg end)
  "Setup and launch editing enviroment for literal string encloded by `BEG' and `END'."
  (let* ((datum        (see-construct-datum beg end))
         (beg          (plist-get datum :beg))
         (end          (plist-get datum :end))
         (mode         (plist-get datum :mode))
         (raw-str      (buffer-substring-no-properties beg end))
         (code         (see-unquote-lines raw-str))
         (ov           (see-set-ov beg end))
         (inhibit-quit t)
         (win-conf     (current-window-configuration)))

    (deactivate-mark)
    (unless mode
      (setq mode (see-try-determine-lang-mode code))
      (unless
          (with-local-quit
            (unless (y-or-n-p (format "%s was dectect, it's correct? " mode))
              (setq mode (see-select-major-mode)))
            t)
        (delete-overlay ov)
        (signal 'quit nil)))

    (unless (fboundp mode)
      (delete-overlay ov)
      (error "Your Emacs not have suport for %s mode" mode))

    (see-switch-to-edit-buffer (see-generate-buffer-name mode))
    (insert code)
    (funcall mode)
    (indent-region (point-min) (point-max))
    (see-mode)
    (setq see-ov ov)
    (setq see-original-snipet raw-str)
    (setq see-saved-win-conf  win-conf)))


(defun see-maybe-indent-region (beg end)
  "Some modes no need indenting when copy back to original buffer, as python.
This function indent region encloded by `BEG' and `END'"
  (cond ((derived-mode-p 'c++-mode 'c-mode)
         (indent-region-line-by-line beg end))
        ((derived-mode-p 'python-mode)
         (if see-py-use-single-quote
             (indent-region-line-by-line beg end)))))

(defun see-select-major-mode ()
  "Prompt to user to choose an apropiate major mode.
If major mode is not in list, thats is ok."
  (intern (completing-read
           "Select mode: "
           (mapcar 'cdr see-language-detection-alist) nil nil)))

(defun see-kill-edit-session ()
  "Finish editing."
  (let ((source-buffer (overlay-buffer see-ov))
        (edit-buffer (current-buffer))
        (beg (overlay-start see-ov))
        (end (overlay-end see-ov)))
    (delete-overlay see-ov)
    (pcase see-window-setup
      (`current-window
       (pop-to-buffer-same-window source-buffer)
       (kill-buffer edit-buffer))
      (`other-window
       (switch-to-buffer-other-window source-buffer)
       (kill-buffer edit-buffer)))))


(defun see-save ()
  "Update content in original buffer."
  (interactive)
  (let ((code (see-cleanup-before-copy-back
               (buffer-substring-no-properties (point-min) (point-max))))
        (beg  (overlay-start see-ov))
        (end  (overlay-end see-ov))
        (ov   see-ov))
    (with-current-buffer (overlay-buffer see-ov)
      (let ((inhibit-read-only t))
        (delete-region beg end)
        (goto-char beg)
        (insert (see-quote-lines code))
        (move-overlay ov beg (point))
        (let ((end (point)))
          (goto-char beg)
          (see-maybe-indent-region beg end))))))

(defun see-restore-original-snipet ()
  "Restore original content in original buffer buffer."
  (interactive)
  (let ((beg    (overlay-start see-ov))
        (end    (overlay-end   see-ov))
        (ov     see-ov)
        (snipet see-original-snipet))
    (with-current-buffer (overlay-buffer see-ov)
      (let ((inhibit-read-only t))
        (delete-region beg end)
        (goto-char beg)
        (insert snipet)
        (move-overlay ov beg (point))))))

(defun see-abort ()
  "Discard any modification on original buffer and kill edit session."
  (interactive)
  (see-restore-original-snipet)
  (see-kill-edit-session))

(defun see-exit ()
  "Update content in original buffer and terminate editing session."
  (interactive)
  (see-save)
  (see-kill-edit-session))

;;;###autoload
(defun see-edit-src-at-point ()
  "Edit literal string at point."
  (interactive)
  (let ((region (see-find-snipet-at-point)))
    (if region
        (see-edit-snipet (car region) (cdr region))
      (message "Nothing to edit here."))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  FUNCTION THAT DEPEND ON CUSTOM
;;          BACKEND FUNCTION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun see-quote-lines (code)
  "This function quotes lines acording mode inside `CODE'.
This function try to be smart handling quotation marks (\" and \') in `CODE'."
  (cond ((derived-mode-p 'c++-mode 'c-mode)
         (see-cc-quote-lines code))
        ((derived-mode-p 'python-mode)
         (see-py-quote-lines code))))


(defun see-unquote-lines (code)
  "Unquote lines inside `CODE'."
  (cond ((derived-mode-p 'c++-mode 'c-mode)
         (see-cc-unquote-lines code))
        ((derived-mode-p 'python-mode)
         (see-py-unquote-lines code))))


(defun see-find-snipet-at-point ()
  "Detect if you are inside literal string."
  (cond ((derived-mode-p 'c++-mode 'c-mode)
         (see-cc-find-snipet-at-point))
        ((derived-mode-p 'python-mode)
         (see-py-find-snipet-at-point))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;     CUSTOM BACKEND FUNCTION
;;         FOR EACH MODE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; c++-mode
(defun see-cc-unquote-lines (code)
  "Specialised version of  `see-unquote-lines'."
  (with-temp-buffer
    (insert code)
    (goto-char (point-min))
    (while (re-search-forward see-cc-regx-str-literal nil t)
      (goto-char (match-beginning 0))
      (delete-char 1)
      (goto-char (1- (match-end 0)))
      (delete-char -1))
    (goto-char (point-min))
    (while (re-search-forward "\\(\\\\\\)+\"" nil t)
      ;; handle escape quotes
      (let ((len (- (match-end 0) (match-beginning 0))))
        (if (= len 2)
            (replace-match "\"" nil t)
          (replace-match
           (concat (make-string (- len 3) ?\\) "\"") nil t))))
    (buffer-string)))


(defun see-cc-quote-lines (code)
  "Specialised version of  `see-quote-lines'."
  (with-temp-buffer
    (save-excursion
      ;; handle escape quoted
      (insert code)
      (goto-char (point-min))
      (while (re-search-forward "\\(\\\\\\)*\"" nil t)
        (let ((len (- (match-end 0) (match-beginning 0))))
          (if (= len 1)
              (replace-match "\\\"" nil t)
            (replace-match
             (concat (make-string (1+ len) ?\\) "\"") nil t)))))
    (let ((max-col 0))
      ;; calcule column of longest line
      (if see-use-align-quotes
          (save-excursion
            (while
                (progn
                  (end-of-line)
                  (when (> (current-column) max-col)
                    (setq max-col (current-column)))
                  (zerop (forward-line 1))))))
      (while
          (progn
            (insert "\"")
            (end-of-line)
            (if (>= max-col (current-column))
                (insert (make-string  (- (+ max-col 2) (current-column))  ?\s) "\"")
              (insert " \""))
            (zerop (forward-line 1)))))
    (buffer-substring-no-properties (point-min) (point-max))))


(defun see-cc-find-snipet-at-point ()
  "Specialised version of  `see-find-snipet-at-point'."
  (let ((point (point))
        (beg   nil)
        (end   nil)
        (regx  see-cc-regx-str-literal))
    (save-excursion
      (goto-char (point-min))
      (while
          (and
           (re-search-forward (format "%s\\(%s*%s\\)*" regx "[\n[:blank:]]" regx) nil t)
           (not (and (<= (match-beginning 0) point (match-end 0))
                     (setq beg (match-beginning 0)
                           end (match-end 0))))))
      (and beg end `(,beg . ,end)))))


;;; python-mode
(defun see-py-triple-or-single-quote (&optional point)
  "This function return 1 or 3 depending on quotation mark after `POINT'."
  (let ((p (or point (point))))
    (save-excursion
      (let ((str (buffer-substring-no-properties p (min (+ p 3) (point-max)))))
        (if (or (string= str "'''") (string= str "\"\"\""))
            3
          1)))))

(defun see-py-unquote-lines (code)
  "Specialised version of  `see-unquote-lines'."
  (with-temp-buffer
    (insert code)
    (goto-char (point-min))

    (while (re-search-forward "[^\\]\\(\\\\[[:space:]]*$\\)" nil t)
      (replace-match "" nil t nil 1))
    (goto-char (point-min))

    (while (re-search-forward see-py-regx-str-literal nil t)
      (let* ((mbeg (match-beginning 0))
             (mend (match-end 0))
             (nq (see-py-triple-or-single-quote mbeg))
             (quote-char (char-after mbeg)))
        (goto-char mbeg)
        (delete-char nq)
        (goto-char (- mend nq))
        (delete-char (- 0 nq))
        (setq mend (point))
        (save-excursion
          (goto-char mbeg)
          (while (re-search-forward (format "\\(\\\\\\)+%c" quote-char) mend t)
            ;; handle escape quotes
            (let ((len (- (match-end 0) (match-beginning 0))))
              (if (= len 2)
                  (replace-match (format "%c" quote-char) nil t)
                (replace-match
                 (concat (make-string (- len 3) ?\\) (format "%c" quote-char)) nil t)))))))
    (buffer-string)))


(defun see-py-quote-lines (code)
  "Specialised version of  `see-quote-lines'."
  (with-temp-buffer
    (save-excursion
      (insert code)
      (goto-char (point-min))
      ;; handle escape quoted
      (while (re-search-forward (format "\\(\\\\\\)*%c" see-py-quote-char) nil t)
        (let ((len (- (match-end 0) (match-beginning 0))))
          (if (= len 1)
              (replace-match (format "\\%c" see-py-quote-char) nil t)
            (replace-match
             (concat (make-string (1+ len) ?\\) (char-to-string see-py-quote-char)) nil t)))))

    (if see-py-use-single-quote
        (progn
          (let ((max-col 0))
            (if see-use-align-quotes
                (save-excursion
                  ;; calcule column of longest line
                  (while
                      (progn
                        (end-of-line)
                        (when (> (current-column) max-col)
                          (setq max-col (current-column)))
                        (zerop (forward-line 1))))))
            (while
                (progn
                  (insert see-py-quote-char)
                  (end-of-line)
                  (if (>= max-col (current-column))
                      (insert (make-string  (- (+ max-col 2) (current-column))  ?\s) see-py-quote-char)
                    (insert " " see-py-quote-char))
                  (unless (eobp) (insert ?\\))
                  (zerop (forward-line 1))))))
      (progn
        (insert (make-string 3 see-py-quote-char))
        (when see-py-insert-newline-after-open-triple-quote
          (insert ?\n))
        (goto-char (point-max))
        (when see-py-insert-newline-before-close-triple-quote
          (insert ?\n))
        (insert (make-string 3 see-py-quote-char))))
    (buffer-substring-no-properties (point-min) (point-max))))


(defun see-py-find-snipet-at-point ()
  "Specialised version of  `see-find-snipet-at-point'."
  (let ((point (point))
        (beg   nil)
        (end   nil)
        (regx  see-py-regx-str-literal))
    (save-excursion
      (goto-char (point-min))
      (while
          (and
           (re-search-forward (format "%s\\(%s*%s\\)*" regx "[\n[:blank:]\\]" regx) nil t)
           (not (and (<= (match-beginning 0) point (match-end 0))
                     (setq beg (match-beginning 0)
                           end (match-end 0))))))
      (and beg end `(,beg . ,end)))))

(provide 'see-mode)

;;; see-mode.el ends here
