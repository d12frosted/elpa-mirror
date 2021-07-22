;;; evil-rsi.el --- Use emacs motion keys in evil, inspired by vim-rsi

;; Copyright (C) 2014 Quang Linh LE

;; Author: Quang Linh LE <linktohack@gmail.com>
;; URL: http://github.com/linktohack/evil-rsi
;; Package-Version: 20160221.2104
;; Package-Commit: 65ae60866be494e4622fe383e23975e04d2a42a3
;; Version: 2.0.0
;; Keywords: evil rsi evil-rsi
;; Package-Requires: ((evil "1.0.0"))

;; This file is not part of GNU Emacs.

;;; License:

;; This file is part of evil-rsi
;;
;; evil-rsi is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.
;;
;; evil-rsi is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This program emulates `vim-rsi` initially developed by Tim Pope
;; (tpope). It brings some essential `emacs` motion bindings back.
;;
;; `<C-n>` and `<C-p>` are important keys, and will be enabled only
;; when `auto-complete` is enabled.


;;; Example:
;;
;; `<C-e>` to move to end of line in all states
;; `<C-d>` to delete to delete character to the right in `insert` state
;; `<C-k>` to delete current line in `insert` state


;;; Code:

(require 'evil)

;;;###autoload
(define-minor-mode evil-rsi-mode
  "Rsi mode."
  :lighter " rsi"
  :global t
  :keymap (let ((map (make-sparse-keymap)))
            (evil-define-key 'insert map "\C-o" #'evil-execute-in-normal-state)
            (evil-define-key 'insert map "\C-r" #'evil-paste-from-register)
            (evil-define-key 'insert map "\C-v" #'quoted-insert)
            (evil-define-key 'insert map (kbd "C-S-k") #'evil-insert-digraph)
            (evil-define-key 'motion map "\C-e" #'end-of-line)
            (when evil-want-C-w-delete
              (evil-define-key 'insert map "\C-w" #'evil-delete-backward-word))
            map)
  (if evil-rsi-mode
      (progn
        (evil-update-insert-state-bindings nil t)
        (when evil-want-C-w-delete
          (define-key minibuffer-local-map [remap kill-region] #'evil-delete-backward-word))
        (define-key evil-ex-completion-map [remap evil-insert-digraph] #'kill-line)
        (define-key evil-ex-completion-map "\C-S-k" #'evil-insert-digraph)
        (define-key evil-ex-completion-map "\C-a" #'beginning-of-line))
    (evil-update-insert-state-bindings)
    (define-key minibuffer-local-map [remap kill-region] nil)
    (define-key evil-ex-completion-map [remap evil-insert-digraph] nil)
    (define-key evil-ex-completion-map "\C-a" #'evil-ex-completion)))

(provide 'evil-rsi)

;;; evil-rsi.el ends here
