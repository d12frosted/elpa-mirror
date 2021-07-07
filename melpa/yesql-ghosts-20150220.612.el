;;; yesql-ghosts.el --- Display ghostly yesql defqueries inline

;; Copyright (C) 2015 Magnar Sveen <magnars@gmail.com>

;; Author: Magnar Sveen <magnars@gmail.com>
;; Version: 0.1.0
;; Package-Version: 20150220.612
;; Package-Commit: bd834e97f263f9f981758c1462bc6297a83ca852
;; Package-Requires: ((s "1.9.0") (dash "2.10.0") (cider "0.8.0"))

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Display ghostly yesql defqueries inline.

;; The ghostly displays are inserted when cider-mode is entered, and
;; updated every time you save.

;;; Code:

(require 's)
(require 'dash)
(require 'cider)
(require 'thingatpt)

(defgroup yesql-ghosts nil
  "Display ghostly yesql defqueries inline."
  :group 'tools)

(defcustom yesql-ghosts-show-descriptions nil
  "A non-nil value if you want to show query descriptions."
  :group 'yesql-ghosts)

(defcustom yesql-ghosts-show-ghosts-automatically t
  "A non-nil value if you want to show the ghosts when a buffer loads.
   Otherwise, use `yesqlg-display-query-ghosts' and `yesqlg-remove-overlays'
   to show and hide them."
  :group 'yesql-ghosts)

(defun yesqlg-extract-query-info (lines)
  (let* ((has-desc (s-starts-with? "--" (cadr lines)))
         (name (->> (car lines)
                    (s-chop-prefix "-- name:")
                    (s-trim)))
         (desc (when has-desc (->> (cadr lines)
                                   (s-chop-prefix "--")
                                   (s-trim))))
         (body (->> lines
                    (-drop (if has-desc 2 1))
                    (s-join "\n")))
         (args (->> body
                    (s-match-strings-all ":[^ \n\t,()]+")
                    (-flatten)
                    (-distinct)
                    (--map (s-chop-prefix ":" it)))))
    (list name desc (cons "db" args) body)))

(defun yesqlg-parse-queries (content)
  (->> (s-lines content)
       (--partition-by-header
        (s-starts-with? "-- name:" it))
       (-map 'yesqlg-extract-query-info)))

(defun yesqlg-load-queries (file)
  (when file
    (yesqlg-parse-queries
     (with-current-buffer
         (find-file-noselect file)
       (buffer-substring-no-properties (point-min) (point-max))))))

(defun yesqlg-format-query (q)
  (-let (((name desc args body) q))
    (if (and yesqlg-show-descriptions desc)
        (format "(defn %s\n  \"%s\"\n  [%s])" name desc (s-join " " args))
      (format "(defn %s [%s])" name (s-join " " args)))))

(defun yesqlg-remove-overlays ()
  (interactive)
  (--each (overlays-in (point-min) (point-max))
    (when (eq (overlay-get it 'type) 'yesqlg)
      (delete-overlay it))))

(defun yesqlg-fontify-ghost (s)
  (set-text-properties
   0 (length s)
   `(face (:foreground ,(format "#%02x%02x%02x" 104 104 104)
                       :background ,(format "#%02x%02x%02x" 24 24 24)))
   s)
  s)

(defun yesqlg-insert-overlay (content)
  (let ((o (make-overlay (point) (point) nil nil t)))
    (overlay-put o 'type 'yesqlg)
    (overlay-put o 'before-string (yesqlg-fontify-ghost (concat content "\n")))))

(defun yesqlg-display-next-queries ()
  (when (search-forward "(defqueries \"" nil t)
    (let* ((path (thing-at-point 'filename))
           (resource (cider-sync-request:resource path))
           (queries (yesqlg-load-queries resource)))
      (when queries
        (end-of-line)
        (forward-char 1)
        (yesqlg-insert-overlay
         (s-join "\n" (-map 'yesqlg-format-query queries)))))))

(defun yesqlg-display-query-ghosts ()
  (interactive)
  (yesqlg-remove-overlays)
  (save-excursion
    (goto-char (point-min))
    (while (yesqlg-display-next-queries))))

(defun yesqlg-auto-show-ghosts ()
  (when (and cider-mode yesqlg-show-ghosts-automatically)
    (yesqlg-display-query-ghosts)))

(add-hook 'cider-mode-hook 'yesqlg-auto-show-ghosts)
(add-hook 'after-save-hook 'yesqlg-auto-show-ghosts)

(provide 'yesql-ghosts)

;;; yesql-ghosts.el ends here
