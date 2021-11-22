;;; consult-yasnippet.el --- A consulting-read interface for yasnippet -*- lexical-binding: t; -*-

;; Copyright (C) 2021  mohsin kaleem

;; Author: mohsin kaleem <mohkale@kisara.moe>
;; Package-Requires: ((emacs "27.1") (yasnippet "0.14") (consult "0.9"))
;; Package-Version: 20211122.810
;; Package-Commit: 9f38ad510328e708370a3a6b41cf40e8bd031b04
;; Version: 0.1
;; URL: https://github.com/mohkale/consult-yasnippet

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

;; Interactively select a yasnippet snippet through completing-read with in
;; buffer previews.

;;; Code:

(require 'map)
(require 'consult)
(require 'yasnippet)

(defun consult-yasnippet--expand-template (template region region-contents)
  "Expand TEMPLATE at point saving REGION and REGION-CONTENTS."
  (deactivate-mark)
  (goto-char (car region))

  ;; Restore marked region (when it existed) so that `yas-expand-snippet'
  ;; overwrites it.
  (when (not (string-equal "" region-contents))
    (push-mark (point))
    (push-mark (cdr region) nil t))

  (cl-letf (((symbol-function 'yas-completing-read)
             (lambda (&rest _args) ""))
            ;; yasnippet doesn't have a multiple variant.
            ((symbol-function 'completing-read-multiple)
             (lambda (&rest _args) "")))
    (yas-expand-snippet (yas--template-content template)
                        nil nil
                        (yas--template-expand-env template))))

(defun consult-yasnippet--preview ()
  "Previewer for `consult--read'.
This function expands TEMPLATE at point in the buffer
`consult-yasnippet--read-template' was started in. This includes
overwriting any region that was active and removing any previous
previews that're already active.

When TEMPLATE is not given, this function essentially just resets
the state of the current buffer to before any snippets were previewed."
  (let* ((buf (current-buffer))
         (region (if (region-active-p)
                     (cons (region-beginning) (region-end))
                   (cons (point) (point))))
         (region-contents (buffer-substring (car region) (cdr region))))
    (lambda (template restore)
      (with-current-buffer buf
        (let ((yas-verbosity 0)
              (inhibit-redisplay t)
              (inhibit-read-only t)
              (orig-offset (- (point-max) (cdr region)))
              (yas-prompt-functions '(yas-no-prompt)))

          ;; We always undo any snippet previews before maybe setting up
          ;; some new previews.
          (delete-region (car region) (cdr region))
          (goto-char (car region))
          (setcar region (point))
          (insert region-contents)
          (setcdr region (point))

          (when (and template (not restore))
            (unwind-protect
                (consult-yasnippet--expand-template template region region-contents)
              (unwind-protect
                  (mapc #'yas--commit-snippet
                        (yas-active-snippets (point-min) (point-max)))
                (setcdr region (- (point-max) orig-offset))))
            (redisplay)))))))

(defun consult-yasnippet--candidates (templates)
  "Convert TEMPLATES into candidates for completing-read."
  (mapcar
   (lambda (template)
     (cons (concat
            (propertize (concat (yas--table-name (yas--template-table template))
                                " ")
                        'invisible t)
            (yas--template-name template)
            " ["
            (propertize (or (yas--template-key template)
                            (and (functionp 'yas--template-regexp-key)
                                 (yas--template-regexp-key template)))
                        'face 'consult-key)
            "]")
           template))
   templates))

(defun consult-yasnippet--annotate (candidates)
  (lambda (cand)
    (when-let ((template (cdr (assoc cand candidates)))
               (table-name (yas--table-name (yas--template-table template))))
      (concat
       " "
       (propertize " " 'display `(space :align-to (- right ,(+ 1 (length table-name)))))
       table-name))))

(defun consult-yasnippet--read-template (&optional all-templates)
  "Backend implementation of `consult-yasnippet'.
This starts a `completing-read' session with all the snippets in the current
snippet table with support for previewing the snippet to be expanded and
replacing the active region with the snippet expansion. When ALL-TEMPLATES
is non-nil you get prompted with snippets from all snippet tables, not just
the current one.

This function doesn't actually expand the snippet, it only reads and then
returns a snippet template from the user."
  (unless (bound-and-true-p yas-minor-mode)
    (error "`consult-yasnippet' can only be called while `yas-minor-mode' is active"))

  (barf-if-buffer-read-only)

  (let* ((buffer-undo-list t)                                                  ; Prevent querying user (and showing previews) from updating the undo-history
         (candidates
          (consult-yasnippet--candidates
           (if all-templates
               (yas--all-templates (map-values yas--tables))
             (yas--all-templates (yas--get-snippet-tables))))))
    (consult--read
     candidates
     :prompt "Choose a snippet: "
     :annotate (consult-yasnippet--annotate candidates)
     :lookup 'consult--lookup-cdr
     :require-match t
     :state (consult-yasnippet--preview)
     :category 'yasnippet)))

;;;###autoload
(defun consult-yasnippet-visit-snippet-file (template)
  "Visit the snippet file associated with TEMPLATE.
When called interactively this command previews snippet completions in
the current buffer, and then opens the selected snippets template file
using `yas--visit-snippet-file-1'."
  (interactive (list (consult-yasnippet--read-template t)))
  (yas--visit-snippet-file-1 template))

;;;###autoload
(defun consult-yasnippet (arg)
  "Interactively select and expand a yasnippet template.
This command presents a completing read interface containing all currently
available snippet expansions, with live previews for each snippet. Once
selected a chosen snippet will be expanded at point using
`yas-expand-snippet'.

With ARG select snippets from all snippet tables, not just the current one."
  (interactive "P")
  (when-let ((template (consult-yasnippet--read-template arg)))
    (yas-expand-snippet (yas--template-content template)
                        nil nil
                        (yas--template-expand-env template))))

(provide 'consult-yasnippet)
;;; consult-yasnippet.el ends here
