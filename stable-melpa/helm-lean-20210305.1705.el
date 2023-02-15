;;; helm-lean.el --- Helm interfaces for lean-mode -*- lexical-binding: t -*-

;; Copyright (c) 2014 Microsoft Corporation. All rights reserved.

;; Author: Leonardo de Moura <leonardo@microsoft.com>
;;         Soonho Kong       <soonhok@cs.cmu.edu>
;;         Gabriel Ebner     <gebner@gebner.org>
;;         Sebastian Ullrich <sebasti@nullri.ch>
;; Maintainer: Sebastian Ullrich <sebasti@nullri.ch>
;; Created: Jan 09, 2014
;; Keywords: languages
;; Package-Requires: ((emacs "24.3") (dash "2.18.0") (helm "2.8.0") (lean-mode "3.3.0"))
;; URL: https://github.com/leanprover/lean-mode

;; Released under Apache 2.0 license as described in the file LICENSE.

;;; Commentary:

;; Currently provides an interface for looking up Lean definitions by name

;;; Code:

(require 'dash)
(require 'helm)
(require 'lean-server)

(defcustom helm-lean-keybinding-helm-lean-definitions (kbd "C-c C-d")
  "Lean Keybinding for helm-lean-definitions"
  :group 'lean-keybinding :type 'key-sequence)

(defun helm-lean-definitions-format-candidate (c)
  `(,(format "%s : %s %s"
             (propertize (plist-get c :text) 'face font-lock-variable-name-face)
             (plist-get c :type)
             (propertize (plist-get (plist-get c :source) :file) 'face font-lock-comment-face))
    . ,c))

(defun helm-lean-definitions-candidates ()
  (with-helm-current-buffer
    (let* ((response (lean-server-send-synchronous-command 'search (list :query helm-pattern)))
           (results (plist-get response :results))
           (results (-filter (lambda (c) (plist-get c :source)) results))
           (candidates (-map 'helm-lean-definitions-format-candidate results)))
      candidates)))

;;;###autoload
(defun helm-lean-definitions ()
  "Open a 'helm' interface for searching Lean definitions."
  (interactive)
  (require 'helm)
  (helm :sources (helm-build-sync-source "helm-source-lean-definitions"
                   :requires-pattern 1
                   :candidates 'helm-lean-definitions-candidates
                   :volatile t
                   :match 'identity
                   :action '(("Go to" . (lambda (c) (with-helm-current-buffer
                                                      (apply 'lean-find-definition-cont (plist-get c :source)))))))
        :buffer "*helm Lean definitions*"))

;;;###autoload
(defun helm-lean-hook ()
  "Set up helm-lean for current buffer"
  (local-set-key helm-lean-keybinding-helm-lean-definitions #'helm-lean-definitions))

;;;###autoload
(add-hook 'lean-mode-hook #'helm-lean-hook)

(provide 'helm-lean)
;;; helm-lean.el ends here
