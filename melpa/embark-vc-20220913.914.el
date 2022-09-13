;;; embark-vc.el --- Embark actions for various version control integrations -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Ellis Kenyő
;;
;; Author: Ellis Kenyő <https://github.com/elken>
;; Maintainer: Ellis Kenyő <me@elken.dev>
;; Created: November 20, 2021
;; Modified: November 20, 2021
;; Version: 0.2
;; Package-Version: 20220913.914
;; Package-Commit: 316ed8d6c9e3ec7af069efbf2391a977852f067d
;; Keywords: convenience matching terminals tools unix vc
;; Homepage: https://github.com/elken/embark-vc
;; Package-Requires: ((emacs "26.1") (embark "0.13") (forge "0.3") (s "1.12.0"))
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; Some actions and conveniences for interacting with various version control
;; packages.
;;
;; See embark for detailed docs about setup & the README for a table of all the
;; keymaps and actions.
;;
;; In short, embark allows one to define a "target" (in this instance we have
;; topic, pull-request, issue, commit and conflict) upon which actions can be
;; performed onto.
;;
;; This package allows conveniences such as (for the purposes of these C-; will represent `embark-act'):
;; - Starting a review for a PR with C-; r
;; - Yank a PR URL with C-; y
;; - Keep the top/bottom/whole merge conflict with C-; /t/b/a
;;
;; And many more. It should also be quite simple to add any desired functions to
;; the keymaps.
;;; Code:

(require 'embark)
(require 'forge-commands)
(require 's)

(defun embark-vc-target-topic-at-point ()
  "Target a Topic in the context of Magit."
  (when (derived-mode-p 'magit-mode)
    (when-let ((topic (forge-topic-at-point)))
      (if (forge-issue-at-point)
          `(issue ,(oref topic number))
        `(pull-request ,(oref topic number))))))

(defun embark-vc-target-commit-at-point ()
  "Target a Commit in the context of Magit."
  (when (derived-mode-p 'magit-mode)
    (save-excursion
      (move-to-left-margin)
      (when (get-text-property (point) 'font-lock-face)
        (let* ((beg (progn (skip-chars-backward "\\b[0-9a-f]\\{5,40\\}\\b") (point)))
               (end (progn (skip-chars-forward "\\b[0-9a-f]\\{5,40\\}\\b") (point)))
               (str (buffer-substring-no-properties beg end)))
          (save-match-data
            (when (string-match "\\b[0-9a-f]\\{5,40\\}\\b" str)
              `(commit ,str))))))))

(defun embark-vc-target-conflict-at-point ()
  "Target a Merge Conflict at point."
  (when (or (derived-mode-p 'magit-mode)
            smerge-mode)
    (when-let* ((beg (save-excursion (when (search-backward "<<<<<<<" nil t)
                                       (move-to-left-margin)
                                       (point))))
                (end (save-excursion (when (search-forward ">>>>>>>" nil t)
                                       (move-end-of-line nil)
                                       (point))))
                (str (buffer-substring-no-properties beg end)))
      (save-match-data
        (when (string-match "<<<<<<<.*?=======.*?>>>>>>>" (s-replace "\n" "" str))
          `(conflict "test" ,beg . ,end))))))

(defun embark-vc-id-to-topic (id)
  "Convert a given ID to a topic."
  (when-let ((pr (forge-get-topic (if (stringp id) (string-to-number id) id))))
    pr))

(defun embark-vc-get-topic-title (topic)
  "Get the title for a TOPIC."
  (oref topic title))

(defun embark-vc-id-to-url (id)
  "Convert a given ID to a topic url scoped to the current forge."
  (when-let ((url (forge-get-url (embark-vc-id-to-topic id))))
    url))

(defun embark-vc-edit-topic-title (id)
  "Edit the title for a topic by ID."
  (when-let ((pr (embark-vc-id-to-topic id)))
    (forge-edit-topic-title pr)))

(defun embark-vc-edit-topic-state (id)
  "Edit the title for a topic by ID."
  (when-let ((topic (embark-vc-id-to-topic id)))
    (when (magit-y-or-n-p
           (format "%s %S?"
                   (cl-ecase (oref topic state)
                     (merged (error "Merged pull-requests cannot be reopened"))
                     (closed "Reopen")
                     (open   "Close"))
                   (embark-vc-get-topic-title topic)))
      (forge-edit-topic-state topic))))

(defun embark-vc-edit-topic-labels (id)
  "Edit the title for a topic by ID."
  (when-let ((pr (embark-vc-id-to-topic id)))
    (forge-edit-topic-labels pr)))

(defun embark-vc-start-review (id)
  "Start a review for a topic by ID."
  (when-let ((pr (embark-vc-id-to-url id)))
    (code-review-start pr)))

(defun embark-vc-checkout-branch (id)
  "Checkout a branch for a topic by ID."
  (when-let ((pr (embark-vc-id-to-topic id)))
    (forge-checkout-pullreq pr)))

(defun embark-vc-visit-pr (id)
  "Get a pr by ID and visit in a separate buffer."
  (when-let ((pr (embark-vc-id-to-topic id)))
    (forge-visit-pullreq pr)))

(defun embark-vc-merge (id)
  "Get a pr by ID and merge it."
  (when-let ((pr (embark-vc-id-to-topic id))
             (method (if (forge--childp (forge-get-repository t) 'forge-gitlab-repository)
                         (magit-read-char-case "Merge method " t
                           (?m "[m]erge"  'merge)
                           (?s "[s]quash" 'squash))
                       (magit-read-char-case "Merge method " t
                         (?m "[m]erge"  'merge)
                         (?s "[s]quash" 'squash)
                         (?r "[r]ebase" 'rebase)))))
    (forge-merge pr method)))

(embark-define-keymap embark-vc-topic-map
  "Keymap for actions related to Topics"
  ("y" forge-copy-url-at-point-as-kill)
  ("s" embark-vc-edit-topic-state)
  ("t" embark-vc-edit-topic-title)
  ("l" embark-vc-edit-topic-labels))

(embark-define-keymap embark-vc-pull-request-map
  "Keymap for actions related to Pull Requests"
  :parent embark-vc-topic-map
  ("c" embark-vc-checkout-branch)
  ("b" forge-browse-pullreq)
  ("m" embark-vc-merge)
  ("v" embark-vc-visit-pr))

(when (require 'code-review nil t)
  (define-key embark-vc-pull-request-map "r" #'embark-vc-start-review))

(embark-define-keymap embark-vc-issue-map
  "Keymap for actions related to Issues"
  :parent embark-vc-topic-map)

(embark-define-keymap embark-vc-commit-map
  "Keymap for actions related to Commits"
  ("b" forge-browse-commit))

(embark-define-keymap embark-vc-conflict-map
  "Keymap for actions related to Merge Conflicts"
  ("a" smerge-keep-all)
  ("b" smerge-keep-base)
  ("c" smerge-combine-with-next)
  ("d" smerge-ediff)
  ("l" smerge-keep-lower)
  ("n" smerge-next)
  ("p" smerge-prev)
  ("r" smerge-resolve)
  ("R" smerge-refine)
  ("u" smerge-keep-upper))

(add-to-list 'embark-keymap-alist '(pull-request . embark-vc-pull-request-map))
(add-to-list 'embark-keymap-alist '(issue . embark-vc-issue-map))
(add-to-list 'embark-keymap-alist '(commit . embark-vc-commit-map))
(add-to-list 'embark-keymap-alist '(conflict . embark-vc-conflict-map))

(add-to-list 'embark-target-finders 'embark-vc-target-topic-at-point)
(add-to-list 'embark-target-finders 'embark-vc-target-commit-at-point)
(add-to-list 'embark-target-finders 'embark-vc-target-conflict-at-point)

(provide 'embark-vc)
;;; embark-vc.el ends here
