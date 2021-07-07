;;; helm-lsp.el --- LSP helm integration             -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Ivan Yonchovski

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

;; Author: Ivan Yonchovski <yyoncho@gmail.com>
;; Keywords: languages, debug
;; Package-Version: 20210419.2014
;; Package-Commit: c2c6974dadfac459b1a69a1217441283874cea92
;; URL: https://github.com/yyoncho/helm-lsp
;; Package-Requires: ((emacs "25.1") (dash "2.14.1") (lsp-mode "5.0") (helm "2.0"))
;; Version: 0.2

;;; Commentary:

;; `helm' for lsp function.

;;; Code:

(require 'helm)
(require 'helm-imenu)
(require 'dash)
(require 'lsp-mode)

(defvar helm-lsp-symbols-request-id nil)
(defvar helm-lsp-symbols-result-p nil)
(defvar helm-lsp-symbols-result nil)

(defgroup helm-lsp nil
  "`helm-lsp' group."
  :group 'lsp-mode
  :tag "Language Server")

(lsp-defun helm-lsp-workspace-symbol-action ((&SymbolInformation :location))
  "Action for helm workspace symbol.
CANDIDATE is the selected item in the helm menu."
  (lsp-goto-location location))

(defface helm-lsp-container-face
  '((t :height 0.8 :inherit shadow))
  "The face used for code lens overlays."
  :group 'helm-lsp)

(defcustom helm-lsp-treemacs-icons t
  "If non-nil, use `lsp-treemacs' icons."
  :group 'helm-lsp
  :type 'boolean)

(defun helm-lsp--extract-file-name (uri)
  "Extract file name from URI."
  (propertize
   (if (string= "jdt" (-> uri url-unhex-string url-generic-parse-url url-type))
       (cl-second (s-match ".*\(\\(.*\\)" uri))
     (f-filename uri))
   'face 'helm-lsp-container-face))

(defun helm-lsp--get-icon (kind)
  "Get the icon by KIND."
  (require 'lsp-treemacs)
  (ht-get (treemacs-theme->gui-icons (treemacs--find-theme lsp-treemacs-theme))
          (lsp-treemacs-symbol-kind->icon kind)))

(defun helm-lsp--workspace-symbol (workspaces name input)
  "Search against WORKSPACES NAME with default INPUT."
  (setq helm-lsp-symbols-result nil)
  (if workspaces
      (with-lsp-workspaces workspaces
        (helm
         :sources
         (helm-build-sync-source
             name
           :candidates (lambda ()
                         (if helm-lsp-symbols-result-p
                             helm-lsp-symbols-result
                           (with-lsp-workspaces workspaces
                             (-let (((request &as &plist :id request-id) ))
                               (setq helm-lsp-symbols-request-id request-id)
                               (lsp-request-async
                                "workspace/symbol"
                                (list :query helm-pattern)
                                (lambda (candidates)
                                  (setq helm-lsp-symbols-request-id nil)
                                  (and helm-alive-p
                                       (let ((helm-lsp-symbols-result-p t))
                                         (setq helm-lsp-symbols-result candidates)
                                         (helm-update))))
                                :mode 'detached
                                :cancel-token :workspace-symbols)
                               helm-lsp-symbols-result))))
           :action 'helm-lsp-workspace-symbol-action
           :volatile t
           :fuzzy-match t
           :match (-const t)
           :keymap helm-map
           :candidate-transformer
           (lambda (candidates)
             (-map
              (-lambda ((candidate &as
                                   &SymbolInformation :container-name? :name :kind :location (&Location :uri)))
                (let ((type (or (alist-get kind lsp-symbol-kinds) "Unknown")))
                  (cons
                   (if (and (featurep 'lsp-treemacs)
                            helm-lsp-treemacs-icons)
                       (concat
                        (or (helm-lsp--get-icon kind)
                            (helm-lsp--get-icon 'fallback))
                        (if (s-blank? container-name?)
                            name
                          (concat name " " (propertize container-name? 'face 'helm-lsp-container-face)))
                        (propertize " · " 'face 'success)
                        (helm-lsp--extract-file-name uri))
                     (concat (if (s-blank? container-name?)
                                 name
                               (concat name " " (propertize container-name? 'face 'helm-lsp-container-face) " -" ))
                             " "
                             (propertize (concat "(" type ")") 'face 'font-lock-type-face)
                             (propertize " · " 'face 'success)
                             (helm-lsp--extract-file-name uri)))
                   candidate)))
              (-take helm-candidate-number-limit candidates)))
           :candidate-number-limit nil
           :requires-pattern 0)
         :input input))
    (user-error "No LSP workspace active")))

;;;###autoload
(defun helm-lsp-workspace-symbol (arg)
  "`helm' for lsp workspace/symbol.
When called with prefix ARG the default selection will be symbol at point."
  (interactive "P")
  (helm-lsp--workspace-symbol (or (lsp-workspaces)
                                  (gethash (lsp-workspace-root default-directory)
                                           (lsp-session-folder->servers (lsp-session))))
                              "Workspace symbol"
                              (when arg (thing-at-point 'symbol))))

;;;###autoload
(defun helm-lsp-global-workspace-symbol (arg)
  "`helm' for lsp workspace/symbol for all of the current workspaces.
When called with prefix ARG the default selection will be symbol at point."
  (interactive "P")
  (helm-lsp--workspace-symbol (-uniq (-flatten (ht-values (lsp-session-folder->servers (lsp-session)))))
                              "Global workspace symbols"
                              (when arg (thing-at-point 'symbol))))

;;;###autoload
(defun helm-lsp-code-actions()
  "Show lsp code actions using helm."
  (interactive)
  (let ((actions (lsp-code-actions-at-point)))
    (cond
     ((seq-empty-p actions) (signal 'lsp-no-code-actions nil))
     ((and (eq (seq-length actions) 1) lsp-auto-execute-action)
      (lsp-execute-code-action (lsp-seq-first actions)))
     (t (helm :sources
              (helm-build-sync-source
                  "Code Actions"
                :candidates actions
                :candidate-transformer
                (lambda (candidates)
                  (-map
                   (-lambda ((candidate &as
                                        &CodeAction :title))
                     (list title :data candidate))
                   candidates))
                :action '(("Execute code action" . (lambda(candidate)
                                                     (lsp-execute-code-action (plist-get candidate :data)))))))))))



;; helm projects

(with-eval-after-load 'helm-projectile
  (defvar helm-lsp-source-projects
    (helm-build-sync-source
        "LSP projects"
      :candidates (lambda () (lsp-session-folders (lsp-session)))
      :fuzzy-match helm-projectile-fuzzy-match
      :keymap helm-projectile-projects-map
      :mode-line helm-read-file-name-mode-line-string
      :action 'helm-source-projectile-projects-actions)
    "Helm source for known LSP projects.")

  (defun helm-lsp-switch-project (&optional arg)
    "Use projectile with Helm for finding files in project
With a prefix ARG invalidates the cache first."
    (interactive "P")
    (let ((helm-ff-transformer-show-only-basename nil)
          (helm-boring-file-regexp-list nil))
      (helm :sources 'helm-lsp-source-projects
            :buffer (concat "*helm projectile: " (projectile-project-name) "*")
            :truncate-lines helm-projectile-truncate-lines
            :prompt (projectile-prepend-project-name "Switch to LSP project: ")))))

;; helm diagnostics

(defconst helm-lsp--diag-mapping
  `((,lsp/diagnostic-severity-error . error)
    (,lsp/diagnostic-severity-warning .  warning)
    (,lsp/diagnostic-severity-information . info)
    (,lsp/diagnostic-severity-hint . info)))

(lsp-defun helm-lsp--diag-matched
  (file (&Diagnostic :message
                     :source? :severity?
                     :range (&Range :start
                                    (&Position :line :character)))
        tokens)
  (-all? (lambda (token)

           (cl-case (aref token 0)
             (?# (s-matches? (substring token 1) file))
             (?* (s-contains? (substring token 1)
                              (symbol-name (alist-get severity? helm-lsp--diag-mapping))))
             (t (s-contains? token message))))
         tokens))

(lsp-defun helm-lsp-jump-to-error ((file start))
  "Go to selected symbol"
  (find-file file)
  (goto-char (lsp--position-to-point start)))

(lsp-defun helm-lsp-quick-fix ((file start))
  "Go to selected symbol and fix the action."
  (find-file file)
  (goto-char (lsp--position-to-point start))
  (call-interactively #'lsp-execute-code-action))

(defface helm-lsp-diag-error
  '((t :inherit error))
  "Face used for corresponding diag error level."
  :group 'lsp-faces)

(defface helm-lsp-diag-info
  '((t :inherit success))
  "Face used for corresponding diag error level."
  :group 'lsp-faces)

(defface helm-lsp-diag-warning
  '((t :inherit warning))
  "Face used for corresponding diag error level."
  :group 'lsp-faces)

(defcustom helm-lsp-diag-face-map
  `((,lsp/diagnostic-severity-error . helm-lsp-diag-error)
    (,lsp/diagnostic-severity-warning . helm-lsp-diag-warning)
    (,lsp/diagnostic-severity-information . helm-lsp-diag-info)
    (,lsp/diagnostic-severity-hint . helm-lsp-diag-info))
  "Alist diagnostics to face."
  :type 'alist)

(defun helm-lsp--diagnostics-transform (candidates)
  (let ((tokens (helm-mm-split-pattern helm-pattern)))
    (->>
     candidates
     (-keep (-lambda ((full-path file (diag &as &Diagnostic :message
                                            :source? :severity?
                                            :range (&Range :start (start &as &Position :line :character)) )))
              (when (helm-lsp--diag-matched full-path diag tokens)
                (list (format
                       "%s%s %s %s %s%s"
                       (if (fboundp 'lsp-treemacs-get-icon)
                           (lsp-treemacs-get-icon (alist-get severity?
                                                             helm-lsp--diag-mapping))
                         (propertize
                          (format "[%s] " (alist-get severity? helm-lsp--diag-mapping))
                          'face
                          (alist-get severity? helm-lsp-diag-face-map)))
                       (propertize (format "[%s]" source?) 'face 'lsp-details-face)
                       source? message
                       (propertize file 'face 'lsp-details-face)
                       (propertize (format ":%s:%s" line character) 'face 'lsp-details-face))
                      full-path start))))
     (-sort (-lambda ((full-path-1 _ (&Diagnostic :range
                                                  (&Range? :start (&Position? :line l1 :character c1))))
                      (full-path-2 _ (&Diagnostic :range
                                                  (&Range? :start (&Position? :line l2 :character c2)))))
              (if (string= full-path-1 full-path-2)
                  (cond
                   ((not l1) t)
                   ((not l2) nil)
                   (t (if (eq l1 l2) (< c1 c2) (< l1 l2))))
                (string< full-path-1 full-path-2)))))))


;;;###autoload
(defun helm-lsp-diagnostics (arg)
  "Diagnostics using `helm'"
  (interactive "P")
  (if (get-buffer "*helm-lsp-diagnostics*")
      (progn
        (run-with-timer 0 nil #'helm-update)
        (helm-resume "*helm-lsp-diagnostics*"))
    (helm
     :sources
     (helm-build-sync-source "Diagnostics"
       :mode-line (list "Diagnostics(s)")
       :candidates (lambda ()
                     (->> (lsp-diagnostics)
                          (ht-map (lambda (file v)
                                    (-map (-partial #'list
                                                    file
                                                    (if-let ((wks (lsp-workspace-root file)))
                                                        (f-relative file wks)
                                                      file))
                                          v)))
                          (apply #'append)))
       :action '(("Goto diagnostic" . helm-lsp-jump-to-error)
                 ("Quick fix" . helm-lsp-quick-fix))
       :persistent-action #'helm-lsp-jump-to-error
       :match (-const t)
       :volatile t
       :candidate-transformer #'helm-lsp--diagnostics-transform)
     :candidate-number-limit nil
     :buffer "*helm-lsp-diagnostics*")))


(provide 'helm-lsp)
;;; helm-lsp.el ends here
