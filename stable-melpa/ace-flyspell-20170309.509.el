;;; ace-flyspell.el --- Jump to and correct spelling errors using `ace-jump-mode' and flyspell

;; Copyright (C) 2015  Junpeng Qiu

;; Author: Junpeng Qiu <qjpchmail@gmail.com>
;; URL: https://github.com/cute-jumper/ace-flyspell
;; Package-Version: 20170309.509
;; Package-Commit: 538d4f8508d305262ba0228dfe7c819fb65b53c9
;; Version: 0.1.2
;; Package-Requires: ((avy "0.4.0"))
;; Keywords: extensions

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

;;                              ______________

;;                               ACE-FLYSPELL

;;                               Junpeng Qiu
;;                              ______________


;; Table of Contents
;; _________________

;; 1 Setup
;; 2 Usage
;; .. 2.1 `ace-flyspell-jump-word'
;; .. 2.2 `ace-flyspell-correct-word'
;; .. 2.3 `ace-flyspell-dwim'
;; 3 Acknowledgment


;; [[file:http://melpa.org/packages/ace-flyspell-badge.svg]]
;; [[file:http://stable.melpa.org/packages/ace-flyspell-badge.svg]]

;; *UPDATE 2017-01-24*: Now use `avy' instead of `ace-jump-mode'.

;; Jump to and correct spelling errors using `avy' and flyspell. Inspired
;; by [abo-abo(Oleh Krehel)]'s [ace-link].


;; [[file:http://melpa.org/packages/ace-flyspell-badge.svg]]
;; http://melpa.org/#/ace-flyspell

;; [[file:http://stable.melpa.org/packages/ace-flyspell-badge.svg]]
;; http://stable.melpa.org/#/ace-flyspell

;; [abo-abo(Oleh Krehel)] https://github.com/abo-abo/

;; [ace-link] https://github.com/abo-abo/ace-link


;; 1 Setup
;; =======

;;   ,----
;;   | (add-to-list 'load-path "/path/to/ace-flyspell")
;;   | (require 'ace-flyspell)
;;   `----

;;   Optional:
;;   ,----
;;   | M-x ace-flyspell-setup
;;   `----

;;   If you call `M-x ace-flyspell-setup' , then this setup binds the
;;   command `ace-flyspell-dwim' to C-., which is originally bound to
;;   `flyspell-auto-correct-word' if you enable the `flyspell-mode'. Of
;;   course, you can choose to change the key binding.

;;   Usually, you should enable `flyspell-mode' because this package aims
;;   to jump to and correct spelling errors detected by `flyspell', or at
;;   least you need to run `flyspell-buffer' to detect spelling errors.


;; 2 Usage
;; =======

;;   There are three available commands:


;; 2.1 `ace-flyspell-jump-word'
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

;;   This command jumps to an spelling error using `avy', and move the
;;   point to where the spelling error is.

;;   The following demo shows the usage of `ace-flyspell-jump-word':
;;   [./screencasts/ace-flyspell-jump-word.gif]

;;   If you prefer this command to the following `ace-flyspell-dwim' (which
;;   will be bound to C-. if you call `M-x ace-flyspell-setup'), you should
;;   probably give it a key binding.


;; 2.2 `ace-flyspell-correct-word'
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

;;   This command is different from `ace-flyspell-jump-word' in the sense
;;   that it aims to *correct* rather than *jump to* the spelling error. At
;;   first, it looks like `ace-flyspell-jump-word', but after you jump to
;;   the misspelt word, it will enter another /mode/, where you hit . to
;;   invoke `flyspell-auto-correct-word' to correct the current misspelt
;;   word and hit any other key to accept the correction and return to the
;;   original position. You can also hit , to save the current word into
;;   personal dictionary.

;;   This command is useful when you're writing an article and want to
;;   temporarily go back to some spelling error and return to where you
;;   left off after fixing the error.


;; 2.3 `ace-flyspell-dwim'
;; ~~~~~~~~~~~~~~~~~~~~~~~

;;   If the word under the cursor is misspelt, then this command is
;;   identical to `flyspell-auto-correct-word', otherwise it will call
;;   `ace-flyspell-correct-word' to jump to and correct some spelling
;;   error.

;;   This command is bound to C-. after you call `M-x ace-flyspell-setup'.

;;   The following demo shows the usage of `ace-flyspell-dwim' (Since there
;;   is no misspelt word at the cursor, `ace-flyspell-dwim' actually
;;   performs the same thing as `ace-flyspell-correct-word' does):
;;   [./screencasts/ace-flyspell-dwim.gif]


;; 3 Acknowledgment
;; ================

;;   - [avy]
;;   - [ace-link]


;; [avy] https://github.com/abo-abo/avy

;; [ace-link] https://github.com/abo-abo/ace-link

;;; Code:

(require 'avy)
(require 'flyspell)

(defgroup ace-flyspell nil
  "Jump to and correct spelling errors using `avy' and flyspell"
  :group 'flyspell)

(defface ace-flyspell--background
  '((t (:box t :bold t)))
  "face for ace-flyspell"
  :group 'ace-flyspell)

(defvar ace-flyspell-new-word-no-query nil
  "If t, don't ask for confirmation when adding new words.")

(defvar ace-flyspell-handler nil)
(defvar ace-flyspell--current-word nil)

(defconst ace-flyspell--ov (let ((ov (make-overlay 1 1 nil nil t)))
                             (overlay-put ov 'face 'ace-flyspell--background)
                             (delete-overlay ov)
                             ov))

(defun ace-flyspell--collect-candidates ()
  (save-excursion
    (save-restriction
      (narrow-to-region (window-start) (window-end (selected-window) t))
      (let ((pos (point-min))
            (pos-max (point-max))
            (pos-list nil)
            (word t))
        (goto-char pos)
        (while (and word (< pos pos-max))
          (setq word (flyspell-get-word t))
          (when word
            (setq pos (nth 1 word))
            (let* ((ovs (overlays-at pos))
                   (r (ace-flyspell--has-flyspell-overlay-p ovs)))
              (when r
                (push pos pos-list)))
            (setq pos (1+ (nth 2 word)))
            (goto-char pos)))
        (nreverse pos-list)))))

(defun ace-flyspell--has-flyspell-overlay-p (ovs)
  (let ((r nil))
    (while (and (not r) (consp ovs))
      (if (flyspell-overlay-p (car ovs))
          (setq r t)
        (setq ovs (cdr ovs))))
    r))

(defun ace-flyspell-help-default ()
  (message "[.]: correct word; [,]: save to personal dictionary"))

(defun ace-flyspell--auto-correct-word ()
  (flyspell-auto-correct-word)
  (ace-flyspell-help-default))

(defun ace-flyspell--insert-word ()
  (interactive)
  (let* ((word-tuple (save-excursion (flyspell-get-word)))
         (word (car word-tuple))
         (start (cadr word-tuple)))
    (ispell-send-string (concat "*" word "\n"))
    (setq ispell-pdict-modified-p '(t)) ; dictionary modified!
    (when (fboundp 'flyspell-unhighlight-at)
      (flyspell-unhighlight-at start))
    (ispell-pdict-save ace-flyspell-new-word-no-query)
    (ace-flyspell--reset)
    (goto-char (mark))))

(defun ace-flyspell--reset ()
  (interactive)
  (message "")
  (delete-overlay ace-flyspell--ov))

(defun ace-flyspell--avy-word ()
  (let (avy-action avy-all-windows)
    (avy--process (ace-flyspell--collect-candidates)
                  (avy--style-fn avy-style))))

(defun ace-flyspell-correct-word ()
  (interactive)
  (when (numberp (ace-flyspell--avy-word))
    (let ((word-tuple (save-excursion (flyspell-get-word))))
      (setq ace-flyspell--current-word (car word-tuple))
      (move-overlay ace-flyspell--ov (nth 1 word-tuple) (nth 2 word-tuple)))
    (unwind-protect
        (if (functionp ace-flyspell-handler)
            (funcall ace-flyspell-handler)
          (ace-flyspell-default-handler))
      (ace-flyspell--reset)
      (goto-char (mark)))))

(defun ace-flyspell-default-handler ()
  (let (char (flag t))
    (ace-flyspell-help-default)
    (while (and flag (setq char (read-key)))
      (ace-flyspell-help-default)
      (cond
       ((char-equal char ?.) (ace-flyspell--auto-correct-word))
       ((char-equal char ?,) (ace-flyspell--insert-word))
       ((char-equal char ?\C-g) (delete-region (overlay-start ace-flyspell--ov)
                                               (overlay-end ace-flyspell--ov))
        (insert ace-flyspell--current-word)
        (setq flag nil))
       (t (setq flag nil))))))

;;;###autoload
(defun ace-flyspell-jump-word ()
  (interactive)
  (ace-flyspell--avy-word))

;;;###autoload
(defun ace-flyspell-dwim ()
  (interactive)
  (if (or (and (eq flyspell-auto-correct-pos (point))
               (consp flyspell-auto-correct-region))
          (not (flyspell-word)))
      (flyspell-auto-correct-word)
    (ace-flyspell-correct-word)))

;;;###autoload
(defun ace-flyspell-setup ()
  "Set up default keybindings."
  (interactive)
  (global-set-key (kbd "C-.") 'ace-flyspell-dwim)
  (eval-after-load "flyspell"
    '(define-key flyspell-mode-map (kbd "C-.") 'ace-flyspell-dwim)))

(provide 'ace-flyspell)
;;; ace-flyspell.el ends here
