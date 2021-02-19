;;; math-preview.el --- Preview TeX math equations inline -*- lexical-binding: t -*-

;; Author: Matsievskiy S.V.
;; Maintainer: Matsievskiy S.V.
;; Version: 0.1.1
;; Package-Version: 20210219.1431
;; Package-Commit: 08aa7c47ffc85c9cba1c9812e1c14250cc4192e4
;; Package-Requires: ((emacs "26.1") (dash "2.18.0") (s "1.12.0"))
;; Homepage: https://gitlab.com/matsievskiysv/math-preview
;; Keywords: convenience


;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.


;;; Commentary:

;; Preview TeX math equations inline using MathJax
;; This package requires external program math-preview.
;; Installation instructions are available in README.md file.

;;; Code:

(require 'dash)
(require 's)


;; {{{ Customization
(defgroup math-preview nil
  "Preview math inline"
  :group  'text
  :tag    "Math Preview"
  :prefix "math-preview-"
  :link   '(url-link :tag "GitLab" "https://gitlab.com/matsievskiysv/math-preview"))

(defface math-preview-face
  '((t :inherit default))
  "Face for equation")

(defface math-preview-processing-face
  '((t :inherit highlight))
  "Face for equation processing")

(defcustom math-preview-marks '(("\\begin{equation}" . "\\end{equation}")
                                ("\\begin{equation*}" . "\\end{equation*}")
                                ("\\[" . "\\]")
                                ("\\(" . "\\)")
                                ("$$" . "$$")
                                ("$" . "$"))
  "Strings marking beginning and end of equation."
  :tag "Equation marks"
  :type '(alist :key-type string :value-type string)
  :safe #'math-preview--check-marks)

(defcustom math-preview-command "math-preview"
  "TeX conversion program name."
  :tag "Command name"
  :type 'string)

(defcustom math-preview-inline-style nil
  "Use smaller math operators so equations would take less vertical space."
  :tag "Display in inline style."
  :type 'boolean)

(defcustom math-preview-raise 0.4
  "Adjust image vertical position."
  :tag "Image vertical position"
  :type 'number
  :safe (lambda (n) (and (numberp n)
                    (> n 0)
                    (< n 1))))

(defcustom math-preview-margin '(5 . 5)
  "Adjust image margin."
  :tag "Image margin"
  :type '(cons :tag "Configure margins" integer integer)
  :safe (lambda (l) (and (consp l)
                    (integerp (car l))
                    (> (car l) 0)
                    (integerp (cdr l))
                    (> (cdr l) 0))))

(defcustom math-preview-relief 0
  "Adjust image relief."
  :tag "Image relief"
  :type 'integer
  :safe (lambda (n) (and (integerp n)
                    (> n 0))))

(defcustom math-preview-scale 2
  "Adjust image scale."
  :tag "Image scale"
  :type 'number
  :safe (lambda (n) (and (numberp n)
                    (> n 0))))

(defcustom math-preview-scale-increment 0.1
  "Image scale interactive increment value."
  :tag "Image scale increment"
  :type 'number
  :safe (lambda (n) (and (numberp n)
                    (> n 0))))

(defcustom math-preview-preprocess-functions (list)
  "Functions to call on each string.
Functions are applied in chain from left to right.
Each function must take one string argument and return string."
  :tag "Preprocess functions"
  :type '(repeat function)
  :safe (lambda (n) (and (listp n)
                    (-all? 'identity (-map #'functionp n)))))
;; }}}

;; {{{ Variables
(defvar math-preview--queue nil "Job queue.")

(defvar math-preview-map (let ((keymap (make-keymap)))
                           (suppress-keymap keymap t)
                           (define-key keymap (kbd "<delete>")		#'math-preview-clear-at-point)
                           (define-key keymap (kbd "<backspace>")	#'math-preview-clear-at-point)
                           (define-key keymap (kbd "SPC")		#'math-preview-clear-at-point)
                           (define-key keymap (kbd "RET")		#'math-preview-clear-at-point)
                           (define-key keymap (kbd "<mouse-1>")		#'math-preview-clear-at-point)
                           (define-key keymap (kbd "<C-delete>")	#'math-preview-clear-all)
                           (define-key keymap (kbd "<C-backspace>")	#'math-preview-clear-all)
                           (define-key keymap (kbd "<C-mouse-1>")	#'math-preview-clear-all)
                           (define-key keymap (kbd "+")			#'math-preview-increment-scale)
                           (define-key keymap (kbd "p")			#'math-preview-increment-scale)
                           (define-key keymap (kbd "-")			#'math-preview-decrement-scale)
                           (define-key keymap (kbd "n")			#'math-preview-decrement-scale)
                           (define-key keymap (kbd "<C-return>")	#'math-preview-copy-svg)
                           (define-key keymap (kbd "C-SPC")		#'math-preview-copy-svg)
                           keymap)
  "Key map for math-preview image overlays.")

(defvar math-preview--input-buffer ""
  "Buffer holds input message.")

(defvar math-preview--debug-json nil
  "Switch for enabling JSON dump into `math-preview--output-buffer'.")

(put 'math-preview 'face 'math-preview-face)
(put 'math-preview 'keymap math-preview-map)
(put 'math-preview 'evaporate t)
(put 'math-preview 'help-echo "mouse-1 to remove")
(put 'math-preview 'mouse-face 'math-preview-processing-face)
(put 'math-preview-processing 'face 'math-preview-processing-face)
;; }}}

;; {{{ Process
;;;###autoload
(defun math-preview-start-process ()
  "Start math-preview process."
  (interactive)
  (let ((proc (get-process "math-preview"))
        (process-connection-type nil))
    (unless proc
      (math-preview--overlays-remove-processing)
      (setq math-preview--queue nil)
      (let ((p (executable-find math-preview-command)))
        (unless p
          (error "%s is not an executable" math-preview-command))
        (setq proc (start-process "math-preview" nil math-preview-command))
        (unless (process-live-p proc)
          (error "Cannot start process"))
        (set-process-query-on-exit-flag proc nil)
        (set-process-filter proc #'math-preview--process-filter)))
    proc))

;;;###autoload
(defun math-preview-stop-process ()
  "Stop math-preview process."
  (interactive)
  (when (get-process "math-preview")
    (setq math-preview--queue nil)
    (math-preview--overlays-remove-processing)
    (kill-process (get-process "math-preview"))))

(defun math-preview--process-filter (_process message)
  "Handle `MESSAGE` from math-preview `PROCESS`.
Call `math-preview--process-input' for strings with carriage return."
  (setq message (s-replace "" ""
                           (s-concat math-preview--input-buffer message)))
  (let ((lines (s-lines message)))
    (setq math-preview--input-buffer (-first-item (-take-last 1 lines)))
    (->> lines
         (-drop-last 1)
         (-map #'math-preview--process-input))))

(defun math-preview--process-input (message)
  "Process input MESSAGE line."
  (when math-preview--debug-json
      (with-current-buffer (get-buffer-create "*math-preview*")
        (insert "Incoming:")
        (insert message)))
    (let* ((msg (json-read-from-string message))
           (id (cdr (assoc 'id msg)))
           (data (cdr (assoc 'data msg)))
           (err (cdr (assoc 'error msg))))
      (let ((o (cdr (--first (= (car it) id) math-preview--queue))))
        (setq math-preview--queue
              (--remove (= (car it) id) math-preview--queue))
        (when o (if err (progn (message "%s" (elt err 0)) (delete-overlay o))
                  (overlay-put o 'category 'math-preview)
                  (overlay-put o 'display
                               (list (list 'raise math-preview-raise)
                                     (cons 'image
                                           (list :type 'svg
                                                 :data data
                                                 :scale math-preview-scale
                                                 :pointer 'hand
                                                 :margin math-preview-margin
                                                 :relief math-preview-relief)))))))))

(defun math-preview--submit (beg end string)
  "Submit TeX processing job.
`BEG` and `END` are the positions of the overlay region.
`STRING` is a TeX equation."
  (unless (math-preview--overlays beg end)
    (let ((proc (math-preview-start-process))
          (o (make-overlay beg end))
          (id (1+ (or (-> math-preview--queue
                          (-first-item)
                          (car))
                      0))))
      (overlay-put o 'category 'math-preview-processing)
      (setq math-preview--queue (-insert-at 0 (-cons* id o)
                                            math-preview--queue))
      (when (and (listp math-preview-preprocess-functions)
                 (> (length math-preview-preprocess-functions) 0))
        (setq string (funcall
                      (apply #'-compose
                             (reverse math-preview-preprocess-functions))
                      string)))
      (let ((msg (concat (json-encode (list :id id
                                            :data string
                                            :inline (if math-preview-inline-style t json-false)))
                         "\n")))
        (when math-preview--debug-json
          (with-current-buffer (get-buffer-create "*math-preview*")
            (insert "Outgoing:")
            (insert msg)))
        (process-send-string proc msg)))))
;; }}}

;; {{{ Search
(defun math-preview--overlays (beg end)
  "Get math-preview overlays in region between `BEG` and `END`."
  (->> (if (= beg end) (overlays-at beg) (overlays-in beg end))
       (--filter (let ((cat (overlay-get it 'category)))
                   (or (eq cat 'math-preview)
                       (eq cat 'math-preview-processing))))))

(defun math-preview--overlays-remove-processing ()
  "Get math-preview overlays in region."
  (->> (overlays-in (point-min) (point-max))
       (--filter (eq (overlay-get it 'category) 'math-preview-processing))
       (--map (delete-overlay it))))

(defun math-preview--check-marks (arg)
  "Check that ARG is a valid `math-preview-marks` value."
  (and (listp arg)
       (consp (car arg))
       (not (-filter 'null (--map (and
	                           (consp it)
	                           (stringp (car it))
	                           (stringp (cdr it))
	                           (not (s-matches? "^\s*$" (car it)))
	                           (not (s-matches? "^\s*$" (cdr it))))
			          arg)))))

(defun math-preview--find-gaps (beg end)
  "Find gaps in math-preview overlays in region between `BEG` and `END`."
  (let ((o (math-preview--overlays beg end)))
    (->> (-zip (-concat (list beg) (-sort #'< (-map #'overlay-end o)))
               (-concat (-sort #'< (-map #'overlay-start o)) (list end)))
         (--filter (> (cdr it) beg))
         (--filter (< (car it) end)))))

(defun math-preview--search (beg end)
  "Search for equations in region between `BEG` and `END`."
  (let ((text (buffer-substring beg end))
        (regex (concat "\\(?:"
                       (s-join "\\|"
                               (--map
                                (s-join ".+?"
                                        (list (regexp-quote (car it))
                                              (regexp-quote (cdr it))))
                                math-preview-marks))
                       "\\)")))
    (->> (s-matched-positions-all
          regex
          (s-replace-all '(("\n" . " ")) text))
         (-filter #'identity)
         (-flatten)
         (--map (cons (+ beg (car it))
                      (+ beg (cdr it)))))))

(defun math-preview--strip-marks (string)
  "Strip STRING of equation mark."
  (->> math-preview-marks
       (--sort (> (length (car it)) (length (car other))))
       (--filter (s-matches-p (s-concat (regexp-quote (car it))
                                           ".+?" (regexp-quote (cdr it)))
                              (s-replace-all '(("\n" . " ")) string)))
       (--map (s-chop-suffix (cdr it) (s-chop-prefix (car it) string)))
       (-first-item)))
;; }}}

;; {{{ User interface
(defun math-preview--region (beg end)
  "Preview equations in region between `BEG` and `END`."
  (->> (math-preview--find-gaps beg end)
       (--map (math-preview--search (car it) (cdr it)))
       (-flatten)
       (--map (math-preview--submit (car it) (cdr it)
                                    (math-preview--strip-marks
                                     (buffer-substring (car it) (cdr it)))))))

;;;###autoload
(defun math-preview-region (beg end)
  "Preview equations in region between `BEG` and `END`."
  (interactive "r")
  (deactivate-mark)
  (math-preview--region beg end))

;;;###autoload
(defun math-preview-all ()
  "Preview equations in buffer."
  (interactive)
  (math-preview--region (point-min) (point-max)))

;;;###autoload
(defun math-preview-at-point ()
  "Preview equations at point."
  (interactive)
  (->> (math-preview--find-gaps (point-min) (point-max))
     (--filter (and (>= (point) (car it))
                    (< (point) (cdr it))))
     (--map (math-preview--search (car it) (cdr it)))
     (-flatten)
     (--filter (and (>= (point) (car it))
                    (< (point) (cdr it))))
     (--map (math-preview--submit (car it) (cdr it)
                                    (math-preview--strip-marks
                                     (buffer-substring (car it) (cdr it)))))))

(defun math-preview--clear-region (beg end)
  "Remove all preview overlays in region between `BEG` and `END`."
  (--map (delete-overlay it) (math-preview--overlays beg end)))

;;;###autoload
(defun math-preview-clear-region (beg end)
  "Remove all preview overlays in region between `BEG` and `END`."
  (interactive "r")
  (deactivate-mark)
  (math-preview--clear-region beg end))

;;;###autoload
(defun math-preview-clear-at-point ()
  "Remove all preview overlays."
  (interactive)
  (math-preview--clear-region (point) (point)))

;;;###autoload
(defun math-preview-clear-all ()
  "Remove all preview overlays."
  (interactive)
  (math-preview--clear-region (point-min) (point-max)))

(defun math-preview--set-scale (n)
  "Adjust image size.
Scale is changed by `N` times `math-preview-scale-increment`"
  (let ((o (-first-item (math-preview--overlays (point) (point)))))
    (when o
      (let* ((display (overlay-get o 'display))
             (list (cdr (car (cdr display))))
             (scale (plist-get list ':scale))
             (increment (* math-preview-scale-increment n))
             (new-scale (+ scale increment))
             (new-scale-clipped (if (<= new-scale 0) increment new-scale)))
        (plist-put list ':scale new-scale-clipped)
        (move-overlay o (overlay-start o) (overlay-end o))))))

;;;###autoload
(defun math-preview-increment-scale (n)
  "Increment image size.
Scale is changed by `N` times `math-preview-scale-increment`"
  (interactive "p")
  (math-preview--set-scale (if (or (null n) (<= n 0)) 1 n)))

;;;###autoload
(defun math-preview-decrement-scale (n)
  "Decrement image size.
Scale is changed by `N` times `math-preview-scale-increment`"
  (interactive "p")
  (math-preview--set-scale (if (or (null n) (<= n 0)) -1 (* n -1))))

;;;###autoload
(defun math-preview-copy-svg ()
  "Copy SVG image to clipboard."
  (interactive)
  (let ((o (-first-item (math-preview--overlays (point) (point)))))
    (when o
      (let* ((display (overlay-get o 'display))
             (list (cdr (car (cdr display)))))
        (kill-new (plist-get list ':data))
        (message "Image copied to clipboard")))))
;; }}}


(provide 'math-preview)

;;; math-preview.el ends here
