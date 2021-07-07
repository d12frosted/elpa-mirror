;;; minibuffer-cua.el --- Make CUA mode's S-up/S-down work in minibuffer

;; Copyright (c) 2013 Akinori MUSHA
;;
;; All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;; 1. Redistributions of source code must retain the above copyright
;;    notice, this list of conditions and the following disclaimer.
;; 2. Redistributions in binary form must reproduce the above copyright
;;    notice, this list of conditions and the following disclaimer in the
;;    documentation and/or other materials provided with the distribution.
;;
;; THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
;; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;; ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
;; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
;; OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
;; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
;; LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
;; OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
;; SUCH DAMAGE.

;; Author: Akinori MUSHA <knu@iDaemons.org>
;; URL: https://github.com/knu/minibuffer-cua.el
;; Package-Version: 20130905.737
;; Package-Commit: e8dcddc24d4f2e8d7987336fb58259e3cc78bbcb
;; Created: 5 Sep 2013
;; Version: 1.0.0.20130905
;; Keywords: completion, editing

;;; Commentary:

;;; This module makes CUA mode's S-up/S-down selection movement work
;;; in minibuffer.

;;; Code:

(defun minibuffer-cua-forward-line (&optional n)
  "Call `forward-line' with argument N, preventing the cursor from moving into the prompt string."
  (forward-line n)
  (when (= (point-min) (point))
    (end-of-line)
    (beginning-of-line)))

(defun minibuffer-cua-shift-next-line (&optional n)
  "Emulate [S-down] selection of CUA mode, moving N lines forward."
  (interactive "p")
  (or mark-active
      (push-mark (point) t t))
  (minibuffer-cua-forward-line n))

(defun minibuffer-cua-shift-previous-line (&optional n)
  "Emulate [S-up] selection of CUA mode, moving N lines backward."
  (interactive "p")
  (or mark-active
      (push-mark (point) t t))
  (minibuffer-cua-forward-line (- n)))

;;;###autoload
(defun minibuffer-cua-define-keys ()
  "Define key bindings in `minibuffer-local-map'."
  (local-set-key (kbd "S-<down>") 'minibuffer-cua-shift-next-line)
  (local-set-key (kbd "S-<up>") 'minibuffer-cua-shift-previous-line))

;;;###autoload
(add-hook 'minibuffer-setup-hook 'minibuffer-cua-define-keys)

(provide 'minibuffer-cua)

;;; minibuffer-cua.el ends here
