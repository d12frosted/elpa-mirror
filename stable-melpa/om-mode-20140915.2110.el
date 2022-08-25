;;; om-mode.el --- Insert Om component template with life cycle.

;; Copyright (C) 2014 Daniel Szmulewicz
;; <http://about.me/daniel.szmulewicz>

;; Author: Daniel Szmulewicz <daniel.szmulewicz@gmail.com>
;; Keywords: clojurescript
;; Package-Version: 20140915.2110
;; Package-Commit: 5a6b380f8d1293a865d8a37aa4816d7412c512ce
;; Created: 14th September 2014
;; Version: 0.5.20140916

;;; Commentary:

;; Insert Om component template with life cycle and jump easily
;; between the relevant positions.  Also, using abbrev to expand the
;; template by typing a user-configurable abbrev, "om" being the
;; default.

;; Just call "om-insert-template" to start.

;;; Legal:
;;
;; This file is NOT part of GNU Emacs.
;;
;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation; either version 3 of the License,
;; or (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;; See <http://www.gnu.org/licenses/> for a copy of the GNU General
;; Public License.

;;; Code:

(require 'skeleton)

;;;###autoload
(define-skeleton om-insert-template
  "Om component skeleton"
  "Name of component: "
  "(defn " str \n
  > "\"Om component for new " str "\""
  \n > "[data owner]"
  \n > "(reify" \n
  '(setq v1 (skeleton-read "Render with state (y/n)? "))
  (when (string= v1 "y")
    (progn (init-state) nil))
  '(indent-according-to-mode)
  "om/IWillMount" \n
  > "(will-mount [_]" \n
  @ - ")" \n >
  "om/IDidMount" \n
  > "(did-mount [_]" \n
  @ - ")" \n >
  "om/IWillUnmount" \n
  > "(will-unmount [_]" \n
  @ - ")" \n >
  "om/IShouldUpdate" \n
  > "(should-update [_ next-props next-state]" \n
  @ - ")" \n >
  "om/IWillReceiveProps" \n
  > "(will-receive-props [_ next-props]" \n
  @ - ")" \n >
  "om/IWillUpdate" \n
  > "(will-update [_ next-props next-state]" \n
  @ - ")" \n >
  "om/IDidUpdate" \n
  > "(did-update [_ prev-props prev-state]" \n
  @ - ")" \n >
  "om/IDisplayName" \n
  > "(display-name [this]" \n
  "\"" str "\")" \n >
  (if (string= v1 "y")
      "om/IRenderState\n(render-state [_ state]"
    "om/IRender\n(render [_]")
  '(indent-according-to-mode)
  \n > @ - ")"
  '(indent-according-to-mode)
  resume: "))"
  '(om-insert-mode 1))

(define-skeleton init-state
  "init state"
  nil \n "om/IInitState" \n
  > "(init-state [_] {" @ " }"
  \n ")" \n >)

(defgroup om-mode nil
  "Customization group for `om-mode'."
  :group 'convenience)

(defconst om-insert-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [remap next-line] 'om-next-position)
    (define-key map [remap previous-line] (lambda () (interactive) (om-next-position 1)))
    (define-key map (kbd "C-c C-c") 'om-exit-edit)
    map)
  "Keymap used in om mode.")

(defcustom om-expand-abbrev "om"
  "This is the abbrev to expand an Om component."
  :group 'om-mode
  :type '(string))

(make-variable-buffer-local
 (defvar om-markers nil
   "Markers for locations saved in skeleton-positions."))

(defun om-make-markers ()
  "Make markers in skeleton."
  (while om-markers
    (set-marker (pop om-markers) nil))
  (setq om-markers
	(mapcar 'copy-marker (reverse skeleton-positions))))

(defun om-exit-edit ()
  "Reset the variable with Om markers, so that `next line' can be bound to default."
  (interactive)
  (om-insert-mode -1))

(defun om-next-position (&optional reverse)
  "Jump to next position in skeleton.
REVERSE - Jump to previous position in skeleton"
  (interactive "P")
  (let* ((positions (mapcar 'marker-position om-markers))
	 (positions (if reverse (reverse positions) positions))
	(comp (if reverse '> '<))
	pos)
    (when positions
      (if (catch 'break
	    (while (setq pos (pop positions))
	      (when (funcall comp (point) pos)
		(throw 'break t))))
	  (goto-char pos)
	(goto-char (marker-position
		    (car om-markers)))))))

;; abbrev table for this mode
;;
(defun om-install-abbrevs ()
  "Install default abbrev table for clojure if none is available."
  (if (and (boundp 'clojure-mode-abbrev-table)
 	   (not (equal clojure-mode-abbrev-table (make-abbrev-table))))
      (let ((save-abbrevs 'silently))
	(define-abbrev clojure-mode-abbrev-table om-expand-abbrev "" 'om-insert-template)
	(message "Clojure abbrevs already exists, om abbrev added to it"))
    (let ((save-abbrevs nil))
      (define-abbrev-table 'clojure-mode-abbrev-table om-expand-abbrev "" 'om-insert-template)
      (message "Clojure abbrevs loaded."))))

(unless noninteractive
  (om-install-abbrevs))

(define-minor-mode om-insert-mode
  "Toggle om mode."
  :init-value nil
  ;; The indicator for the mode line.
  :keymap om-insert-mode-map
  :lighter " OmInsert"
  ;; The minor mode bindings.
  :global nil
  :group 'om-mode
  (if om-insert-mode
      (progn
        (om-make-markers)
        (message "Use C-n and C-p to move between Om fields, C-c C-c to finish."))
    (message "Om insertion stopped.")))

(provide 'om-mode)
;;; om-mode.el ends here
