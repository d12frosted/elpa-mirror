;;; call-graph.el --- Library to generate call graph for cpp functions  -*- lexical-binding: t; -*-

;; Copyright (C) 2018 Huming Chen

;; Author: Huming Chen <chenhuming@gmail.com>
;; Maintainer: Huming Chen <chenhuming@gmail.com>
;; URL: https://github.com/beacoder/call-graph
;; Package-Version: 20180307.239
;; Package-Commit: 0bbe292b1b9c7ba1d8a65ed5e475f6a53f5f9f27
;; Version: 0.1.0
;; Keywords: programming, convenience
;; Created: 2018-01-07
;; Package-Requires: ((emacs "25.1") (cl-lib "0.6.1") (hierarchy "0.7.0") (tree-mode "1.0.0") (ivy "0.10.0"))

;; This file is not part of GNU Emacs.

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

;; Library to generate call graph for cpp functions.

;;; Install:

;; Put this file into load-path directory, and byte compile it if
;; desired. And put the following expression into your ~/.emacs.
;;
;;     (require 'call-graph)
;;     (global-set-key (kbd "C-c g") 'call-graph)
;;
;;; Usage:

;; "C-c g" => (call-graph) => buffer <*call-graph*> will be generated

;;; Code:

(require 'cl-lib)
(require 'hierarchy)
(require 'tree-mode)
(require 'ivy)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Customizable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defgroup call-graph nil
  "Customization support for the `call-graph'."
  :version "0.1.0"
  :group 'applications)

(defcustom call-graph-initial-max-depth 2
  "The maximum initial depth of call graph."
  :type 'integer
  :group 'call-graph)

(defcustom call-graph-search-filters '("grep -E \"\\.(cpp|cc):\"")
  "The filters used by `call-graph' when searching caller."
  :type 'list
  :group 'call-graph)

(defcustom call-graph-display-file t
  "Non-nil means display file in another window while moving from one field to another in `call-graph'."
  :type 'boolean
  :group 'call-graph)

(defcustom call-graph-path-to-global nil
  "If non-nil the directory to search global executables."
  :type '(choice (const :tag "Unset" nil) directory)
  :risky t
  :group 'call-graph)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Definition
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar call-graph-persist-caller-filters nil
  "The alist form of `call-graph--caller-filters'.")

(defvar call-graph--caller-filters nil
  "The filters describing caller relations, used when building caller-map.")

(defvar call-graph--current-depth 0
  "The current depth of call graph.")

(defvar call-graph--default-instance nil
  "Default CALL-GRAPH instance.")

(defvar call-graph--default-hierarchy nil
  "Hierarchy to display call-graph.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Data Structure
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(cl-defstruct (call-graph
               (:constructor nil)
               (:constructor call-graph--make)
               (:conc-name call-graph--))
  (callers (make-hash-table :test #'equal)) ; map func to its callers
  (locations (make-hash-table :test #'equal))) ; map func <- caller to its locations

(defun call-graph-new ()
  "Create a call-graph and return it."
  (call-graph--make))

(defun call-graph--add-callers (call-graph func callers)
  "In CALL-GRAPH, given FUNC, add CALLERS."
  (when (and call-graph func callers)
    (let* ((short-func (call-graph--extract-method-name func))) ; method only
      (unless (map-elt (call-graph--callers call-graph) short-func)
        (seq-doseq (caller callers)
          (let* ((full-caller (car caller)) ; class::method
                 (location (cdr caller)) ; location
                 (func-caller-key
                  (intern (concat (symbol-name short-func) " <- " (symbol-name full-caller))))) ; "callee <- class::caller" as key

            ;; populate caller data
            (cl-pushnew full-caller (map-elt (call-graph--callers call-graph) short-func (list)))

            ;; populate location data
            (cl-pushnew location (map-elt (call-graph--locations call-graph) func-caller-key (list))
                        :test #'equal)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Persitence
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun call-graph-prepare-persistent-data ()
  "Prepare data for persistence."
  (when call-graph--caller-filters
    (setq call-graph-persist-caller-filters
          (map-into call-graph--caller-filters 'list))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Helpers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun call-graph--extract-method-name (full-func)
  "Given FULL-FUNC, return a SHORT-FUNC.
e.g: class::method => method."
  (when-let ((full-func-str (symbol-name full-func))
             (temp-split (split-string full-func-str "::"))
             (short-func
              (intern (seq-elt temp-split (1- (seq-length temp-split))))))
    short-func))

(defun call-graph--get-func-caller-location (call-graph func caller)
  "In CALL-GRAPH, given FUNC and CALLER, return the caller postion."
  (when (and call-graph func caller)
    (let ((locations (call-graph--locations call-graph))
          (func-caller-key
           (if (eq 'root-function func) 'root-function ; special treatment for root-function
             (intern (concat (symbol-name (call-graph--extract-method-name func)) " <- " (symbol-name caller))))))
      (map-elt locations func-caller-key))))

(defun call-graph--get-buffer ()
  "Generate ‘*call-graph*’ buffer."
  (let ((buffer-name "*call-graph*"))
    (get-buffer-create buffer-name)))

(defun call-graph--get-path-to-global ()
  "Return path to program GNU GLOBAL."
  (if call-graph-path-to-global
      (expand-file-name "global" call-graph-path-to-global)
    "global"))

(defun call-graph--visit-function (func-location)
  "Visit function location FUNC-LOCATION."
  (when-let ((temp-split (split-string func-location ":"))
             (file-name (car temp-split))
             (line-nb-str (cadr temp-split))
             (line-nb (string-to-number line-nb-str))
             (is-valid-file (file-exists-p file-name))
             (is-valid-nb (integerp line-nb)))
    (find-file-read-only-other-window file-name)
    (with-no-warnings (goto-line line-nb))))

(defun call-graph--find-caller (reference)
  "Given a REFERENCE, return the caller as (caller . location)."
  (when-let ((tmp-split (split-string reference ":"))
             (file-name (car tmp-split))
             (line-nb-str (cadr tmp-split))
             (line-nb (string-to-number line-nb-str))
             (is-valid-file (file-exists-p file-name))
             (is-valid-nb (integerp line-nb)))
    (let ((location (concat file-name ":" line-nb-str))
          (caller nil))
      (with-temp-buffer
        (insert-file-contents-literally file-name)
        ;; TODO: leave only hooks on which 'which-function-mode depends
        ;; (set (make-local-variable 'c++-mode-hook) nil)
        (c++-mode)
        (goto-char (point-min))
        (while (re-search-forward "__attribute__[ \t\n]*(([[:alpha:]]+))" nil t)
          (replace-match "__attribute__" t nil)) ; imenu failed to parse function with __attribute__ ((...)) as args
        (which-function-mode t)
        (goto-char (point-min))
        (forward-line (1- line-nb))
        (setq caller (which-function)))
      (when caller
        (cons (intern caller) location)))))

(defun call-graph--find-references (func)
  "Given a FUNC, return all references as a list."
  (let ((command
         (format "%s -a --result=grep -r %s"
                 (call-graph--get-path-to-global)
                 (shell-quote-argument (symbol-name func))))
        (filter-separator " | ")
        command-filter command-out-put)
    (when (and (> (length call-graph-search-filters) 0)
               (setq command-filter
                     (mapconcat #'identity (delq nil call-graph-search-filters) filter-separator))
               (not (string= command-filter filter-separator)))
      (setq command (concat command filter-separator command-filter)))
    (when (setq command-out-put (shell-command-to-string command))
      (split-string command-out-put "\n" t))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Core Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun call-graph--search-callers (call-graph func depth &optional calculate-depth)
  "In CALL-GRAPH, given FUNC, search callers deep to level DEPTH.
CALCULATE-DEPTH is used to calculate actual depth."
  (when-let ((next-depth (and (> depth 0) (1- depth)))
             (calculate-depth (or calculate-depth 1))
             (next-calculate-depth (1+ calculate-depth))
             (short-func (call-graph--extract-method-name func)))
    (let ((caller-pairs (list))
          (callers (map-elt (call-graph--callers call-graph) short-func (list))))

      ;; callers not found.
      (unless callers
        (seq-doseq (reference (call-graph--find-references short-func))
          (when-let ((caller-pair (and reference (call-graph--find-caller reference))))
            (message (format "Search returns: %s" (symbol-name (car caller-pair))))
            (push caller-pair caller-pairs)))
        (call-graph--add-callers call-graph func caller-pairs)
        (setq callers (map-elt (call-graph--callers call-graph) short-func (list))))

      ;; calculate depth.
      (when (> calculate-depth call-graph--current-depth)
        (setq call-graph--current-depth calculate-depth))

      ;; recursively search callers.
      (seq-doseq (caller callers)
        (call-graph--search-callers call-graph caller next-depth next-calculate-depth)))))

(defun call-graph--build-hierarchy (call-graph func depth)
  "In CALL-GRAPH, given FUNC, build hierarchy deep to DEPTH level."
  (when-let ((next-depth (and (> depth 0) (1- depth)))
             (hierarchy call-graph--default-hierarchy)
             (short-func (call-graph--extract-method-name func))
             (callers
              (or (map-elt call-graph--caller-filters func (list))
                  (map-elt (call-graph--callers call-graph) short-func (list)))))

    ;; populate hierarchy data.
    (seq-doseq (caller callers)
      (hierarchy-add-tree hierarchy caller (lambda (item) (when (eq item caller) func)))
      (message "Insert child %s under parent %s" (symbol-name caller) (symbol-name func)))

    ;; recursively populate callers.
    (seq-doseq (caller callers)
      (call-graph--build-hierarchy call-graph caller next-depth))))

(defun call-graph--display-hierarchy ()
  "Display `call-graph' in hierarchy."
  (let ((switch-buffer (not (eq major-mode 'call-graph-mode)))
        hierarchy-buffer)
    (setq hierarchy-buffer
          (hierarchy-tree-display
           call-graph--default-hierarchy
           (lambda (tree-item _)
             (let ((caller (symbol-name tree-item))
                   (parent (or (hierarchy-parent call-graph--default-hierarchy tree-item) 'root-function)))

               ;; use propertize to avoid this error => Attempt to modify read-only object
               ;; @see https://stackoverflow.com/questions/24565068/emacs-text-is-read-only
               (insert (propertize caller 'caller-name tree-item 'callee-name parent))))
           (call-graph--get-buffer)))
    (when switch-buffer
      (switch-to-buffer-other-window hierarchy-buffer))
    (call-graph-mode)
    (call-graph-widget-expand-all)))

(defun call-graph--create (call-graph func depth)
  "Generate CALL-GRAPH for FUNC, DEPTH is the depth of caller-map."
  (when (and call-graph func depth)
    (setq call-graph--default-hierarchy (hierarchy-new)
          call-graph--current-depth 0)
    (call-graph--search-callers call-graph func depth)
    (call-graph--build-hierarchy call-graph func depth)
    (call-graph--display-hierarchy)))

(defun call-graph--init ()
  "Initialize data for `call-graph'."
  (when (or current-prefix-arg (null call-graph--default-instance))
    (setq call-graph--default-instance (call-graph-new))) ; clear cached reference

  (when (null call-graph--caller-filters)
    (if call-graph-persist-caller-filters ; load filtes from saved session
        (setq call-graph--caller-filters (map-into call-graph-persist-caller-filters 'hash-table)
              call-graph-persist-caller-filters nil)
      (setq call-graph--caller-filters (make-hash-table :test #'equal)))))

;;;###autoload
(defun call-graph (&optional func)
  "Generate `call-graph' for FUNC / func-at-point / func-in-active-rigion.
With prefix argument, discard cached data and re-generate reference data."
  (interactive)
  (when-let ((func
              (or func (if (use-region-p)
                           (prog1 (intern (buffer-substring-no-properties (region-beginning) (region-end)))
                             (deactivate-mark))
                         (symbol-at-point)))))
    (call-graph--init)
    (let ((call-graph call-graph--default-instance))

      (when-let ((file-name (buffer-file-name))
                 (line-nb (line-number-at-pos))
                 (location (concat file-name ":" (number-to-string line-nb))))
        (setf (map-elt (call-graph--locations call-graph) 'root-function) (list location))) ; save root function location

      (save-mark-and-excursion
       (call-graph--create call-graph func call-graph-initial-max-depth)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Call-Graph Operations
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun call-graph-select-caller-location ()
  "Select caller location as default location for function at point."
  (interactive)
  (save-mark-and-excursion
   (when (get-char-property (point) 'button)
     (forward-char 4))
   (when-let ((call-graph call-graph--default-instance)
              (callee (get-text-property (point) 'callee-name))
              (caller (get-text-property (point) 'caller-name))
              (func-caller-key
               (intern (concat (symbol-name (call-graph--extract-method-name callee)) " <- " (symbol-name caller))))
              (locations (call-graph--get-func-caller-location call-graph callee caller))
              (has-many (> (seq-length locations) 1)))
     (ivy-read "Caller Locations:" locations
               :action (lambda (func-location)
                         (while (not (equal func-location (car locations)))
                           (setq locations
                                 (nconc (cdr locations) (cons (car locations) ())))) ; put selected location upfront
                         (setf (map-elt (call-graph--locations call-graph) func-caller-key) locations)
                         (call-graph--visit-function func-location))))))

(defun call-graph-visit-file-at-point ()
  "Visit occurrence on the current line."
  (when-let ((call-graph call-graph--default-instance)
             (callee (get-text-property (point) 'callee-name))
             (caller (get-text-property (point) 'caller-name))
             (locations (call-graph--get-func-caller-location call-graph callee caller))
             (location (car locations)))
    (call-graph--visit-function location)
    (when (> (seq-length locations) 1)
      (message "Multiple locations for this function, select with `call-graph-select-caller-location'"))))

(defun call-graph-goto-file-at-point ()
  "Go to the occurrence on the current line."
  (interactive)
  (save-mark-and-excursion
   (when (get-char-property (point) 'button)
     (forward-char 4))
   (call-graph-visit-file-at-point)))

(defun call-graph-display-file-at-point ()
  "Display in another window the occurrence the current line describes."
  (interactive)
  (save-selected-window
    (call-graph-goto-file-at-point)))

(defun call-graph-at-point ()
  "Within buffer <*call-graph*>, generate new `call-graph' for symbol at point."
  (interactive)
  (save-mark-and-excursion
   (when (get-char-property (point) 'button)
     (forward-char 4))
   (when-let ((caller (get-text-property (point) 'caller-name)))
     (call-graph caller))))

(defun call-graph-remove-caller ()
  "Within buffer <*call-graph*>, remove caller at point."
  (interactive)
  (when (get-char-property (point) 'button)
    (forward-char 4))
  (when-let ((call-graph call-graph--default-instance)
             (callee (get-text-property (point) 'callee-name))
             (caller (get-text-property (point) 'caller-name))
             (short-func (call-graph--extract-method-name callee))
             (callers (map-elt (call-graph--callers call-graph) short-func (list)))
             (deep-copy-of-callers (seq-map #'identity callers))
             (filters
              (or (map-elt call-graph--caller-filters callee deep-copy-of-callers)
                  (setf (map-elt call-graph--caller-filters callee) deep-copy-of-callers))))
    (tree-mode-delete-match (symbol-name caller))
    (setf (map-elt call-graph--caller-filters callee)
          (remove caller filters))))

(defun call-graph-reset-caller-filter ()
  "Within buffer <*call-graph*>, reset caller filter."
  (interactive)
  (setf call-graph--caller-filters nil)
  (message "Reset caller filter done"))

(defun call-graph-quit ()
  "Quit `call-graph'."
  (interactive)
  (kill-this-buffer))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Widget Operations
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun call-graph-widget-expand-all ()
  "Iterate all widgets in buffer and expand em."
  (interactive)
  (tree-mode-expand-level 0))

(defun call-graph-widget-collapse-all ()
  "Iterate all widgets in buffer and close em."
  (interactive)
  (goto-char (point-min))
  (tree-mode-expand-level 1))

(defun call-graph-expand (&optional level)
  "Expand `call-graph' by LEVEL."
  (interactive "p")
  (when-let ((call-graph call-graph--default-instance)
             (hierarchy call-graph--default-hierarchy)
             (depth (+ call-graph--current-depth level))
             (func (car (hierarchy-roots hierarchy))))
    (call-graph--create call-graph func depth)))

(defun call-graph-collapse (&optional level)
  "Collapse `call-graph' by LEVEL."
  (interactive "p")
  (let ((level (- call-graph--current-depth level)))
    (goto-char (point-min))
    (cond
     ((> level 0)
      (tree-mode-expand-level level)
      (setq call-graph--current-depth level))
     ((<= level 0)
      (tree-mode-expand-level 1)
      (setq call-graph--current-depth 1)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar call-graph-mode-map
  (let ((map (make-keymap)))
    (define-key map (kbd "e") 'call-graph-widget-expand-all)
    (define-key map (kbd "c") 'call-graph-widget-collapse-all)
    (define-key map (kbd "p") 'widget-backward)
    (define-key map (kbd "n") 'widget-forward)
    (define-key map (kbd "q") 'call-graph-quit)
    (define-key map (kbd "+") 'call-graph-expand)
    (define-key map (kbd "_") 'call-graph-collapse)
    (define-key map (kbd "o") 'call-graph-goto-file-at-point)
    (define-key map (kbd "g") 'call-graph-at-point)
    (define-key map (kbd "d") 'call-graph-remove-caller)
    (define-key map (kbd "l") 'call-graph-select-caller-location)
    (define-key map (kbd "<RET>") 'call-graph-goto-file-at-point)
    map)
  "Keymap for `call-graph' major mode.")

;;;###autoload
(define-derived-mode call-graph-mode special-mode "call-graph"
  "Major mode for viewing function's `call graph'.
\\{call-graph-mode-map}"
  :group 'call-graph
  (buffer-disable-undo)
  (setq truncate-lines t
        buffer-read-only t
        show-trailing-whitespace nil)
  (setq-local line-move-visual t)
  (hack-dir-local-variables-non-file-buffer)
  (make-local-variable 'text-property-default-nonsticky)
  (push (cons 'keymap t) text-property-default-nonsticky)
  (when call-graph-display-file
    (add-hook 'widget-move-hook (lambda () (call-graph-display-file-at-point))))
  (run-mode-hooks))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Tests
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; (global-set-key (kbd "C-c g") 'call-graph)


(provide 'call-graph)
;;; call-graph.el ends here
