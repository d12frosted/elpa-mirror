;;; tab-bar-groups.el --- Tab groups for the tab bar -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2021 Fritz Grabo

;; Author: Fritz Grabo <me@fritzgrabo.com>
;; URL: https://github.com/fritzgrabo/tab-bar-groups
;; Package-Version: 20210213.2138
;; Package-Commit: d18e80804abb08cc2f033b986a84fdb0b1ece944
;; Version: 0.1
;; Package-Requires: ((emacs "27.1") (s "1.12.0"))
;; Keywords: convenience

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; If not, see http://www.gnu.org/licenses.

;;; Commentary:

;; Tab groups for the tab bar.

;; Tabs with the same base name ("foo", "foo<1>", "foo<2>" all share the
;; base name "foo") are considered a group.

;; This package provides convenient commands to create and work with
;; tabs in groups.

;;; Code:

(require 'seq)

(require 's)

(defun tab-bar-groups--tab-group-name (&optional tab)
  "Return the group name of TAB (or current tab's name if nil)."
  (s-replace-regexp "<[[:digit:]]+>$" "" (alist-get 'name (or tab (tab-bar--current-tab)))))

(defun tab-bar-groups--same-tab-group-p (tab1 tab2)
  "Check whether TAB1 and TAB2 are in the same group."
  (string-equal
   (tab-bar-groups--tab-group-name tab1)
   (tab-bar-groups--tab-group-name tab2)))

(defun tab-bar-groups--tabs-in-group (reference-tab)
  "Return all tabs in the group of REFERENCE-TAB (or current tab if nil)."
  (seq-filter (lambda (tab) (tab-bar-groups--same-tab-group-p reference-tab tab)) (funcall tab-bar-tabs-function)))

;; TODO: Simplify?
(defun tab-bar-groups-uniquify-tab-name (&optional reference-tab)
  "Make current tab name unique, with a base name derived from the group name of REFERENCE-TAB (or current tab if nil)."
  (interactive)
  (let* ((current-tab-name (alist-get 'name (tab-bar--current-tab)))
         (tab-group-name (tab-bar-groups--tab-group-name reference-tab))
         (tab-group-tab-names (seq-map (lambda (tab) (alist-get 'name tab)) (tab-bar-groups--tabs-in-group reference-tab)))
         (tab-name-function (lambda (base num) (format "%s<%i>" base num))))
    (if (or (and (string-equal current-tab-name tab-group-name) (= 1 (length tab-group-tab-names)))
            (not (member tab-group-name tab-group-tab-names)))
        (tab-bar-rename-tab tab-group-name)
      (let ((num 1))
        (while (let ((candidate (funcall tab-name-function tab-group-name num)))
                 (and (member candidate tab-group-tab-names)
                      (not (string-equal current-tab-name candidate))))
          (setq num (1+ num)))
        (tab-bar-rename-tab (funcall tab-name-function tab-group-name num))))))

(defun tab-bar-groups-duplicate-tab ()
  "Duplicate current tab with a unique name."
  (interactive)
  (let ((source-tab (tab-bar--current-tab))
        (tab-bar-new-tab-choice nil)) ;; nil means: duplicate tab contents.
    (tab-bar-new-tab)
    (tab-bar-groups-uniquify-tab-name source-tab)))

(defun tab-bar-groups-new-tab (&rest args)
  "Call `tab-bar-new-tab' with the given ARGS, ensure new tab has a unique name."
  (interactive)
  (tab-bar-new-tab args)
  (tab-bar-groups-uniquify-tab-name))

(defun tab-bar-groups-close-tab-or-tab-group (&rest args)
  "Dispatch to `tab-bar-close-tab', passing along ARGS.
If prefix argument is given, calls `tab-bar-groups-close-tab-group' with ARGS instead."
  (interactive)
  (apply (if current-prefix-arg
             #'tab-bar-groups-close-tab-group
           #'tab-bar-close-tab)
         args))

(defun tab-bar-groups-close-tab-group (&optional reference-tab)
  "Close all tabs of the group that REFERENCE-TAB (or the current tab if nil) belongs to."
  (interactive)
  (let* ((tab-group-tabs (seq-filter (lambda (tab) (tab-bar-groups--same-tab-group-p reference-tab tab)) (funcall tab-bar-tabs-function))))
    (dolist (tab tab-group-tabs)
      (tab-bar-close-tab-by-name (alist-get 'name tab)))))

(provide 'tab-bar-groups)
;;; tab-bar-groups.el ends here
