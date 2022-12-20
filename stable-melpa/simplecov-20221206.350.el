;;; simplecov.el --- Colorize untested ruby code

;; Copyright (C) 2008-2022 by Ryan Davis

;; Author: Ryan Davis <ryand-ruby@zenspider.com>
;; URL: https://github.org/zenspider/elisp
;; Package-Version: 20221206.350
;; Package-Commit: 215f2bdc5d2ef9b4439779ba4d3129210c9f34ab
;; Keywords: tools, languages
;; Version: 2.0
;; Package-Requires: ((dash "2.19") (emacs "28"))

;;; The MIT License:

;; http://en.wikipedia.org/wiki/MIT_License
;;
;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:

;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
;; IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
;; CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
;; TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
;; SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;;; Commentary:

;; This package provides the ability to highlight untested code
;; according to simplecov by using its JSON serialized data.

;; See function `simplecov-show-coverage'.

;; Currently, you must manually run your tests with singlecov
;; activated.

;; If you're doing lots of coverage work, you might want to define
;; keybindings such as:
;;
;;   (define-key enh-ruby-mode-map (kbd "C-c r") 'simplecov-show-coverage)
;;   (define-key enh-ruby-mode-map (kbd "C-c R") 'simplecov-clear)

;;; History:

;; 2.0 2022-10-17 Overhaul into singlecov.el.
;; 1.3 2018-06-19 Added better overlay processing now that rcov is dead.
;; 1.2 2009-10-21 Added customizable overlay background color.
;; 1.1 2008-12-01 Added find-project-dir to fix path generation issues.
;; 1.0 2008-01-14 Birfday.

;;; Code:

(require 'json)
(require 'map)
(require 'dash)

(defcustom simplecov-bg-color
  "#ffcccc"
  "The default background color for simplecov uncovered lines."
  :group 'simplecov
  :type 'color)

;;;###autoload
(defun simplecov-show-coverage ()
  "Display lines reported as uncovered by simplecov using overlays."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (remove-overlays)
    (->> (current-buffer)
         (simplecov--buffer->coverage)
         (simplecov--coverage->lines)
         (simplecov--lines->regions)
         (simplecov--regions->overlays))))

;;;###autoload
(defun simplecov-clear ()
  "Clear simplecov overlays."
  (interactive)
  (remove-overlays))

;;; Utilities:

(defun simplecov--buffer->coverage (buffer-name)
  "Take BUFFER-NAME and return coverage data from simplecov's json file."
  (let* ((buffer (get-buffer buffer-name))
         (source-path (buffer-file-name buffer))
         (cov-path (simplecov--find-coverage-file-for-buffer buffer-name))
         (coverage (simplecov--read-json cov-path)))
    (map-nested-elt coverage (list "Minitest" "coverage" source-path "lines"))))

(defun simplecov--coverage->lines (coverage)
  "Take COVERAGE data and return the line numbers of the uncovered (0) lines."
  (->> coverage
       (-map-indexed #'cons)
       (--filter (eq 0 (cdr it)))
       (-map #'car)
       (-map #'1+)))

(defun simplecov--lines->regions (lines)
  "Take LINES data and return the regions \\='((beg . end)...) of those lines."
  (--map (cons (line-beginning-position it)
               (line-end-position it))
         lines))

(defun simplecov--regions->overlays (regions)
  "Take REGIONS and create overlays using `simplecov-bg-color'."
  (--each regions
    (overlay-put (make-overlay (car it) (cdr it))
                 'face (cons 'background-color simplecov-bg-color))))

(defun simplecov--find-coverage-file-for-buffer (buffer-name)
  "Search from BUFFER-NAME up parent directories until coverage file is found.
Return the full path to the JSON file."
  (with-current-buffer buffer-name
    (let* ((cov-file "coverage/.resultset.json")
           (base-dir (simplecov--find-project-dir cov-file))
           (cov-path (concat base-dir cov-file)))
      cov-path)))

(defun simplecov--read-json (cov-path)
  "Read and return the parsed json at COV-PATH."
  (let ((json-array-type 'list)
        (json-key-type   'string))
    (json-read-file cov-path)))

(defun simplecov--find-project-dir (file &optional dir)
  "Return parent DIR where FILE is found or nil if not found.

Traverses each parent directory until FILE is found. Starts at
DIR or `default-directory' if nil.

Return nil if not found before hitting root directory."
  (or dir (setq dir default-directory))
  (if (file-exists-p (concat dir file))
      dir
    (if (equal dir "/")
        nil
      (simplecov--find-project-dir file (expand-file-name (concat dir "../"))))))

(provide 'simplecov)

;;; simplecov.el ends here
