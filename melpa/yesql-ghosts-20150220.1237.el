;;; yesql-ghosts.el --- Display ghostly yesql defqueries inline

;; Copyright (C) 2015 Magnar Sveen <magnars@gmail.com>

;; Author: Magnar Sveen <magnars@gmail.com>
;; Version: 0.1.0
;; Package-Version: 20150220.1237
;; Package-Commit: 8f1faf0137b85a5072d13e1240a463d9a35ce2bb
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
   Otherwise, use `yesql-ghosts-display-query-ghosts' and `yesql-ghosts-remove-overlays'
   to show and hide them."
  :group 'yesql-ghosts)

(defface yesql-ghosts-defn-face
  '((t :foreground "#686868" :background "#181818"))
  "Face for yesql ghost defns inserted when in cider-mode."
  :group 'yesql-ghosts)

(defun yesql-ghosts-extract-query-info (lines)
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

(defun yesql-ghosts-parse-queries (content)
  (->> (s-lines content)
       (--partition-by-header
        (s-starts-with? "-- name:" it))
       (-map 'yesql-ghosts-extract-query-info)))

(defun yesql-ghosts-load-queries (file)
  (when file
    (yesql-ghosts-parse-queries
     (with-current-buffer
         (find-file-noselect file)
       (buffer-substring-no-properties (point-min) (point-max))))))

(defun yesql-ghosts-format-query (q)
  (-let (((name desc args body) q))
    (if (and yesql-ghosts-show-descriptions desc)
        (format "(defn %s\n  \"%s\"\n  [%s])" name desc (s-join " " args))
      (format "(defn %s [%s])" name (s-join " " args)))))

(defun yesql-ghosts-remove-overlays ()
  (interactive)
  (--each (overlays-in (point-min) (point-max))
    (when (eq (overlay-get it 'type) 'yesql-ghosts)
      (delete-overlay it))))

(defun yesql-ghosts-fontify-ghost (s)
  (set-text-properties 0 (length s) `(face 'yesql-ghosts-defn-face) s)
  s)

(defun yesql-ghosts-insert-overlay (content)
  (let ((o (make-overlay (point) (point) nil nil t)))
    (overlay-put o 'type 'yesql-ghosts)
    (overlay-put o 'before-string (yesql-ghosts-fontify-ghost (concat content "\n")))))

(defun yesql-ghosts-display-next-queries ()
  (when (search-forward "(defqueries \"" nil t)
    (let* ((path (thing-at-point 'filename))
           (resource (cider-sync-request:resource path))
           (queries (yesql-ghosts-load-queries resource)))
      (when queries
        (end-of-line)
        (forward-char 1)
        (yesql-ghosts-insert-overlay
         (s-join "\n" (-map 'yesql-ghosts-format-query queries)))))))

(defun yesql-ghosts-display-query-ghosts ()
  (interactive)
  (yesql-ghosts-remove-overlays)
  (save-excursion
    (goto-char (point-min))
    (while (yesql-ghosts-display-next-queries))))

(defun yesql-ghosts-auto-show-ghosts ()
  (when (and cider-mode yesql-ghosts-show-ghosts-automatically)
    (yesql-ghosts-display-query-ghosts)))

(add-hook 'cider-mode-hook 'yesql-ghosts-auto-show-ghosts)
(add-hook 'after-save-hook 'yesql-ghosts-auto-show-ghosts)

(provide 'yesql-ghosts)
;;; yesql-ghosts.el ends here
